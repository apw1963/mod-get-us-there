// GetUsThere
// Runtime configuration and destination catalog foundation.
//
// This stage implements:
//   * reloadable module configuration
//   * startup loading of curated destination metadata
//   * validation against AzerothCore game_tele
//   * alias loading
//   * private addon transport and protocol HELLO handshake
//
// Addon SEARCH exposure, policy filtering, teleport execution, and group/raid
// behavior are intentionally implemented separately.

#include "Chat.h"
#include "ConfigValueCache.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "Map.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "World.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <charconv>
#include <cmath>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

enum class GetUsThereConfig : uint32
{
    Enable,
    PolicyProfile,
    BlockRivalCapitals,
    BlockRivalStarterZones,
    AllowOwnFactionCapitalsAtAnyLevel,
    LevelRestrictionEnable,
    LevelRestrictionMaxDeficit,
    PvPAllowRivalFactionTerritory,
    PvPAllowRivalCapitals,
    PvPAllowRivalStarterZones,
    TeleportCooldownSeconds,
    TeleportAllowFromDungeon,
    TeleportAllowFromRaid,
    TestOverrideEnable,
    TestOverrideAllowedAccountIds,
    GroupTeleportRequireLeader,
    RaidTeleportRequireLeader,
    Count
};

class GetUsThereConfigData : public ConfigValueCache<GetUsThereConfig>
{
public:
    GetUsThereConfigData()
        : ConfigValueCache<GetUsThereConfig>(GetUsThereConfig::Count)
    {
    }

    bool IsEnabled() const
    {
        return GetConfigValue<bool>(GetUsThereConfig::Enable);
    }

protected:
    void BuildConfigCache() override
    {
        SetConfigValue<bool>(
            GetUsThereConfig::Enable,
            "GetUsThere.Enable",
            true);

        SetConfigValue<std::string>(
            GetUsThereConfig::PolicyProfile,
            "GetUsThere.PolicyProfile",
            std::string("Auto"),
            Reloadable::Yes,
            [](std::string const& value)
            {
                return value == "Auto" || value == "PvE" || value == "PvP";
            },
            "must be one of: Auto, PvE, PvP");

        SetConfigValue<bool>(
            GetUsThereConfig::BlockRivalCapitals,
            "GetUsThere.BlockRivalCapitals",
            true);

        SetConfigValue<bool>(
            GetUsThereConfig::BlockRivalStarterZones,
            "GetUsThere.BlockRivalStarterZones",
            true);

        SetConfigValue<bool>(
            GetUsThereConfig::AllowOwnFactionCapitalsAtAnyLevel,
            "GetUsThere.AllowOwnFactionCapitalsAtAnyLevel",
            true);

        SetConfigValue<bool>(
            GetUsThereConfig::LevelRestrictionEnable,
            "GetUsThere.LevelRestriction.Enable",
            true);

        SetConfigValue<uint32>(
            GetUsThereConfig::LevelRestrictionMaxDeficit,
            "GetUsThere.LevelRestriction.MaxDeficit",
            9u,
            Reloadable::Yes,
            [](uint32 value)
            {
                return value <= 79u;
            },
            "must be between 0 and 79");

        SetConfigValue<bool>(
            GetUsThereConfig::PvPAllowRivalFactionTerritory,
            "GetUsThere.PvP.AllowRivalFactionTerritory",
            true);

        SetConfigValue<bool>(
            GetUsThereConfig::PvPAllowRivalCapitals,
            "GetUsThere.PvP.AllowRivalCapitals",
            false);

        SetConfigValue<bool>(
            GetUsThereConfig::PvPAllowRivalStarterZones,
            "GetUsThere.PvP.AllowRivalStarterZones",
            false);
        SetConfigValue<uint32>(
            GetUsThereConfig::TeleportCooldownSeconds,
            "GetUsThere.Teleport.CooldownSeconds",
            5u,
            Reloadable::Yes,
            [](uint32 value)
            {
                return value <= 3600u;
            },
            "must be between 0 and 3600");

        SetConfigValue<bool>(
            GetUsThereConfig::TeleportAllowFromDungeon,
            "GetUsThere.Teleport.AllowFromDungeon",
            false);

        SetConfigValue<bool>(
            GetUsThereConfig::TeleportAllowFromRaid,
            "GetUsThere.Teleport.AllowFromRaid",
            false);

        SetConfigValue<bool>(
            GetUsThereConfig::TestOverrideEnable,
            "GetUsThere.TestOverride.Enable",
            false);

        SetConfigValue<std::string>(
            GetUsThereConfig::TestOverrideAllowedAccountIds,
            "GetUsThere.TestOverride.AllowedAccountIds",
            std::string(""));

        SetConfigValue<bool>(
            GetUsThereConfig::GroupTeleportRequireLeader,
            "GetUsThere.GroupTeleport.RequireLeader",
            true);

        SetConfigValue<bool>(
            GetUsThereConfig::RaidTeleportRequireLeader,
            "GetUsThere.RaidTeleport.RequireLeader",
            true);
    }
};

enum class GetUsThereFaction : uint8
{
    Neutral = 0,
    Alliance = 1,
    Horde = 2
};

struct GetUsThereDestination
{
    uint32 gameTeleId = 0;
    std::string displayName;
    std::string category;
    GetUsThereFaction territoryFaction = GetUsThereFaction::Neutral;
    uint8 recommendedLevel = 0;
    bool isCapital = false;
    bool isProtectedFactionZone = false;
    bool enabled = true;
    bool groupTeleportAllowed = true;
    uint16 sortOrder = 0;
    std::vector<std::string> aliases;
};

class GetUsThereCatalog
{
public:
    void Load()
    {
        _destinations.clear();

        QueryResult destinationResult = WorldDatabase.Query(
            "SELECT "
            "game_tele_id, "
            "display_name, "
            "category, "
            "territory_faction, "
            "recommended_level, "
            "is_capital, "
            "is_protected_faction_zone, "
            "enabled, "
            "group_teleport_allowed, "
            "sort_order "
            "FROM mod_get_us_there_destination");

        if (!destinationResult)
        {
            LOG_WARN(
                "server.loading",
                "GetUsThere: loaded 0 destinations from "
                "`mod_get_us_there_destination`.");

            return;
        }

        uint32 loadedDestinations = 0;
        uint32 rejectedDestinations = 0;

        do
        {
            Field* fields = destinationResult->Fetch();

            uint32 const gameTeleId = fields[0].Get<uint32>();
            std::string const displayName = fields[1].Get<std::string>();
            std::string const category = fields[2].Get<std::string>();
            uint32 const territoryFaction = fields[3].Get<uint32>();
            uint32 const recommendedLevel = fields[4].Get<uint32>();
            uint32 const isCapital = fields[5].Get<uint32>();
            uint32 const isProtectedFactionZone = fields[6].Get<uint32>();
            uint32 const enabled = fields[7].Get<uint32>();
            uint32 const groupTeleportAllowed = fields[8].Get<uint32>();
            uint32 const sortOrder = fields[9].Get<uint32>();

            if (!sObjectMgr->GetGameTele(gameTeleId))
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination references missing or invalid "
                    "game_tele id {}; row ignored.",
                    gameTeleId);

                ++rejectedDestinations;
                continue;
            }

            if (displayName.empty())
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} has an empty "
                    "display_name; row ignored.",
                    gameTeleId);

                ++rejectedDestinations;
                continue;
            }

            if (category.empty())
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} has an empty "
                    "category; row ignored.",
                    gameTeleId);

                ++rejectedDestinations;
                continue;
            }

            if (territoryFaction > 2u)
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} has invalid "
                    "territory_faction {}; row ignored.",
                    gameTeleId,
                    territoryFaction);

                ++rejectedDestinations;
                continue;
            }

            if (recommendedLevel > 80u)
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} has invalid "
                    "recommended_level {}; row ignored.",
                    gameTeleId,
                    recommendedLevel);

                ++rejectedDestinations;
                continue;
            }

            if (isCapital > 1u ||
                isProtectedFactionZone > 1u ||
                enabled > 1u ||
                groupTeleportAllowed > 1u)
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} contains an "
                    "invalid boolean metadata value; row ignored.",
                    gameTeleId);

                ++rejectedDestinations;
                continue;
            }

            if (sortOrder > 65535u)
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: destination game_tele id {} has invalid "
                    "sort_order {}; row ignored.",
                    gameTeleId,
                    sortOrder);

                ++rejectedDestinations;
                continue;
            }

            GetUsThereDestination destination;
            destination.gameTeleId = gameTeleId;
            destination.displayName = displayName;
            destination.category = category;
            destination.territoryFaction =
                static_cast<GetUsThereFaction>(territoryFaction);
            destination.recommendedLevel =
                static_cast<uint8>(recommendedLevel);
            destination.isCapital = isCapital != 0u;
            destination.isProtectedFactionZone =
                isProtectedFactionZone != 0u;
            destination.enabled = enabled != 0u;
            destination.groupTeleportAllowed =
                groupTeleportAllowed != 0u;
            destination.sortOrder = static_cast<uint16>(sortOrder);

            auto const [itr, inserted] =
                _destinations.emplace(gameTeleId, std::move(destination));

            if (!inserted)
            {
                LOG_ERROR(
                    "server.loading",
                    "GetUsThere: duplicate destination for game_tele id {}; "
                    "later row ignored.",
                    gameTeleId);

                ++rejectedDestinations;
                continue;
            }

            ++loadedDestinations;
        }
        while (destinationResult->NextRow());

        uint32 loadedAliases = 0;
        uint32 rejectedAliases = 0;

        QueryResult aliasResult = WorldDatabase.Query(
            "SELECT game_tele_id, alias "
            "FROM mod_get_us_there_alias");

        if (aliasResult)
        {
            do
            {
                Field* fields = aliasResult->Fetch();

                uint32 const gameTeleId = fields[0].Get<uint32>();
                std::string const alias = fields[1].Get<std::string>();

                auto destinationItr = _destinations.find(gameTeleId);

                if (destinationItr == _destinations.end())
                {
                    LOG_WARN(
                        "server.loading",
                        "GetUsThere: alias references destination game_tele "
                        "id {} that was not loaded; alias ignored.",
                        gameTeleId);

                    ++rejectedAliases;
                    continue;
                }

                if (alias.empty())
                {
                    LOG_WARN(
                        "server.loading",
                        "GetUsThere: destination game_tele id {} has an "
                        "empty alias; alias ignored.",
                        gameTeleId);

                    ++rejectedAliases;
                    continue;
                }

                destinationItr->second.aliases.push_back(alias);
                ++loadedAliases;
            }
            while (aliasResult->NextRow());
        }

        LOG_INFO(
            "server.loading",
            "GetUsThere: loaded {} destination(s), rejected {} "
            "destination(s), loaded {} alias(es), rejected {} alias(es).",
            loadedDestinations,
            rejectedDestinations,
            loadedAliases,
            rejectedAliases);
    }

    std::vector<GetUsThereDestination> Search(
        std::string query,
        std::size_t limit) const
    {
        std::vector<GetUsThereDestination> results;

        if (limit == 0)
            return results;

        auto toLowerAscii = [](std::string& value)
        {
            std::transform(
                value.begin(),
                value.end(),
                value.begin(),
                [](unsigned char c)
                {
                    return static_cast<char>(std::tolower(c));
                });
        };

        toLowerAscii(query);

        auto containsQuery = [&query, &toLowerAscii](std::string value)
        {
            toLowerAscii(value);
            return value.find(query) != std::string::npos;
        };

        for (auto const& entry : _destinations)
        {
            GetUsThereDestination const& destination = entry.second;

            if (!destination.enabled)
                continue;

            bool matched =
                query.empty() ||
                containsQuery(destination.displayName) ||
                containsQuery(destination.category);

            if (!matched)
            {
                for (std::string const& alias : destination.aliases)
                {
                    if (containsQuery(alias))
                    {
                        matched = true;
                        break;
                    }
                }
            }

            if (matched)
                results.push_back(destination);
        }

        std::sort(
            results.begin(),
            results.end(),
            [](GetUsThereDestination const& left,
               GetUsThereDestination const& right)
            {
                if (left.sortOrder != right.sortOrder)
                    return left.sortOrder < right.sortOrder;

                if (left.displayName != right.displayName)
                    return left.displayName < right.displayName;

                return left.gameTeleId < right.gameTeleId;
            });

        if (results.size() > limit)
            results.resize(limit);

        return results;
    }

    std::size_t Size() const
    {
        return _destinations.size();
    }

    GetUsThereDestination const* FindByGameTeleId(uint32 gameTeleId) const
    {
        auto const destinationItr = _destinations.find(gameTeleId);

        if (destinationItr == _destinations.end())
            return nullptr;

        return &destinationItr->second;
    }

private:
    std::unordered_map<uint32, GetUsThereDestination> _destinations;
};

namespace
{
    GetUsThereConfigData sGetUsThereConfig;
    GetUsThereCatalog sGetUsThereCatalog;

    enum class GetUsTherePolicyDecision : uint8
    {
        Allowed,
        DestinationDisabled,
        InvalidPlayerFaction,
        RivalTerritoryBlocked,
        RivalCapitalBlocked,
        RivalStarterZoneBlocked,
        LevelTooLow
    };

    bool TryGetUsTherePlayerFaction(
        Player const* player,
        GetUsThereFaction& faction)
    {
        if (!player)
            return false;

        switch (player->GetTeamId())
        {
            case TEAM_ALLIANCE:
                faction = GetUsThereFaction::Alliance;
                return true;
            case TEAM_HORDE:
                faction = GetUsThereFaction::Horde;
                return true;
            default:
                return false;
        }
    }

    bool GetUsThereUsesPvPPolicy()
    {
        std::string_view const profile =
            sGetUsThereConfig.GetConfigValue(
                GetUsThereConfig::PolicyProfile);

        if (profile == "PvP")
            return true;

        if (profile == "PvE")
            return false;

        // PolicyProfile validation restricts the remaining value to "Auto".
        return sWorld && sWorld->IsPvPRealm();
    }

    GetUsTherePolicyDecision EvaluateGetUsThereDestinationPolicy(
        Player const* player,
        GetUsThereDestination const& destination)
    {
        if (!destination.enabled)
            return GetUsTherePolicyDecision::DestinationDisabled;

        GetUsThereFaction playerFaction = GetUsThereFaction::Neutral;

        if (!TryGetUsTherePlayerFaction(player, playerFaction))
            return GetUsTherePolicyDecision::InvalidPlayerFaction;

        bool const isRivalTerritory =
            destination.territoryFaction != GetUsThereFaction::Neutral &&
            destination.territoryFaction != playerFaction;

        bool const usesPvPPolicy = GetUsThereUsesPvPPolicy();

        if (isRivalTerritory)
        {
            if (usesPvPPolicy &&
                !sGetUsThereConfig.GetConfigValue<bool>(
                    GetUsThereConfig::PvPAllowRivalFactionTerritory))
            {
                return GetUsTherePolicyDecision::RivalTerritoryBlocked;
            }

            if (destination.isCapital)
            {
                bool const capitalBlocked =
                    usesPvPPolicy
                        ? !sGetUsThereConfig.GetConfigValue<bool>(
                              GetUsThereConfig::PvPAllowRivalCapitals)
                        : sGetUsThereConfig.GetConfigValue<bool>(
                              GetUsThereConfig::BlockRivalCapitals);

                if (capitalBlocked)
                    return GetUsTherePolicyDecision::RivalCapitalBlocked;
            }

            if (destination.isProtectedFactionZone)
            {
                bool const starterZoneBlocked =
                    usesPvPPolicy
                        ? !sGetUsThereConfig.GetConfigValue<bool>(
                              GetUsThereConfig::PvPAllowRivalStarterZones)
                        : sGetUsThereConfig.GetConfigValue<bool>(
                              GetUsThereConfig::BlockRivalStarterZones);

                if (starterZoneBlocked)
                {
                    return
                        GetUsTherePolicyDecision::RivalStarterZoneBlocked;
                }
            }
        }

        bool const ownFactionCapital =
            destination.isCapital &&
            destination.territoryFaction == playerFaction;

        bool const bypassLevelRestriction =
            ownFactionCapital &&
            sGetUsThereConfig.GetConfigValue<bool>(
                GetUsThereConfig::AllowOwnFactionCapitalsAtAnyLevel);

        if (!bypassLevelRestriction &&
            destination.recommendedLevel > 0 &&
            sGetUsThereConfig.GetConfigValue<bool>(
                GetUsThereConfig::LevelRestrictionEnable))
        {
            uint32 const playerLevel = player->GetLevel();
            uint32 const maxDeficit =
                sGetUsThereConfig.GetConfigValue<uint32>(
                    GetUsThereConfig::LevelRestrictionMaxDeficit);

            if (playerLevel + maxDeficit <
                static_cast<uint32>(destination.recommendedLevel))
            {
                return GetUsTherePolicyDecision::LevelTooLow;
            }
        }

        return GetUsTherePolicyDecision::Allowed;
    }

    enum class GetUsThereTeleportSafetyDecision : uint8
    {
        Allowed,
        InvalidPlayer,
        AlreadyTeleporting,
        InCombat,
        DeadOrGhost,
        InFlight,
        OnTransport,
        InBattlegroundOrArena,
        InDungeon,
        InRaid
    };

    GetUsThereTeleportSafetyDecision EvaluateGetUsThereTeleportSafety(
        Player const* player,
        bool testOverride = false)
    {
        if (!player)
            return GetUsThereTeleportSafetyDecision::InvalidPlayer;

        if (player->IsBeingTeleported())
            return GetUsThereTeleportSafetyDecision::AlreadyTeleporting;

        if (!testOverride && player->IsInCombat())
            return GetUsThereTeleportSafetyDecision::InCombat;

        if (!player->IsAlive() ||
            player->HasSpiritOfRedemptionAura() ||
            player->HasUnitFlag2(UNIT_FLAG2_FEIGN_DEATH))
        {
            return GetUsThereTeleportSafetyDecision::DeadOrGhost;
        }

        if (player->IsInFlight())
            return GetUsThereTeleportSafetyDecision::InFlight;

        if (player->GetTransport())
            return GetUsThereTeleportSafetyDecision::OnTransport;

        if (player->InBattleground() || player->InArena())
        {
            return
                GetUsThereTeleportSafetyDecision::InBattlegroundOrArena;
        }

        Map const* map = player->GetMap();

        if (!testOverride && map)
        {
            if (map->IsRaid())
            {
                if (!sGetUsThereConfig.GetConfigValue<bool>(
                        GetUsThereConfig::TeleportAllowFromRaid))
                {
                    return GetUsThereTeleportSafetyDecision::InRaid;
                }
            }
            else if (map->IsDungeon())
            {
                if (!sGetUsThereConfig.GetConfigValue<bool>(
                        GetUsThereConfig::TeleportAllowFromDungeon))
                {
                    return GetUsThereTeleportSafetyDecision::InDungeon;
                }
            }
        }

        return GetUsThereTeleportSafetyDecision::Allowed;
    }

    std::vector<GetUsThereDestination>
    SearchGetUsThereDestinationsForPlayer(
        Player const* player,
        std::string query,
        std::size_t limit,
        bool testOverride = false)
    {
        std::vector<GetUsThereDestination> results;

        if (!player || limit == 0)
            return results;

        // Ask the catalog for every textual match first. Policy filtering must
        // happen before the caller's final result cap so blocked destinations
        // cannot crowd eligible destinations out of the result window.
        std::vector<GetUsThereDestination> const matches =
            sGetUsThereCatalog.Search(
                query,
                sGetUsThereCatalog.Size());

        results.reserve(std::min(limit, matches.size()));

        for (GetUsThereDestination const& destination : matches)
        {
            if (testOverride)
            {
                if (!destination.enabled)
                    continue;
            }
            else if (EvaluateGetUsThereDestinationPolicy(
                         player,
                         destination) != GetUsTherePolicyDecision::Allowed)
            {
                continue;
            }

            results.push_back(destination);

            if (results.size() >= limit)
                break;
        }

        return results;
    }

    class GetUsThereWorldScript : public WorldScript
    {
    public:
        GetUsThereWorldScript()
            : WorldScript(
                  "GetUsThereWorldScript",
                  {
                      WORLDHOOK_ON_BEFORE_CONFIG_LOAD,
                      WORLDHOOK_ON_BEFORE_WORLD_INITIALIZED
                  })
        {
        }

        void OnBeforeConfigLoad(bool reload) override
        {
            sGetUsThereConfig.Initialize(reload);
        }

        void OnBeforeWorldInitialized() override
        {
            if (!sGetUsThereConfig.IsEnabled())
            {
                LOG_INFO(
                    "server.loading",
                    "GetUsThere: module disabled; destination catalog "
                    "loading skipped.");

                return;
            }

            sGetUsThereCatalog.Load();
        }
    };

    constexpr char GetUsThereAddonPrefix[] = "GetUsThere\t";
    constexpr char GetUsThereHelloRequest[] = "GetUsThere\tHELLO\t1";
    constexpr char GetUsThereHelloResponse[] = "GetUsThere\tHELLO\t1\tOK";
    constexpr char GetUsThereSearchRequestPrefix[] =
        "GetUsThere\tSEARCH\t";
    constexpr char GetUsThereSearchTestRequestPrefix[] =
        "GetUsThere\tSEARCH_TEST\t";
    constexpr char GetUsThereTeleportRequestPrefix[] =
        "GetUsThere\tTELEPORT\t";
    constexpr char GetUsThereTeleportTestRequestPrefix[] =
        "GetUsThere\tTELEPORT_TEST\t";
    constexpr char GetUsThereTeleportCoordTestRequestPrefix[] =
        "GetUsThere\tTELEPORT_COORD_TEST\t";
    constexpr std::size_t GetUsThereMaxAddonPayloadLength = 255;
    constexpr std::size_t GetUsThereSearchResultLimit = 20;
    constexpr std::size_t GetUsThereMaxSearchQueryLength = 96;

    struct GetUsThereTeleportRequest
    {
        uint32 requestId = 0;
        uint32 gameTeleId = 0;
    };

    struct GetUsThereTeleportCoordRequest
    {
        uint32 requestId = 0;
        uint32 mapId = 0;
        float x = 0.0f;
        float y = 0.0f;
        float z = 0.0f;
    };

    struct GetUsThereSearchRequest
    {
        uint32 requestId = 0;
        std::string query;
    };

    using GetUsThereSearchThrottleClock = std::chrono::steady_clock;

    constexpr std::chrono::milliseconds
        GetUsThereSearchThrottleInterval{250};

    std::unordered_map<
        ObjectGuid,
        GetUsThereSearchThrottleClock::time_point>
        sGetUsThereSearchLastAccepted;

    bool TryConsumeGetUsThereSearchThrottle(Player const* player)
    {
        if (!player)
            return false;

        ObjectGuid const guid = player->GetGUID();
        GetUsThereSearchThrottleClock::time_point const now =
            GetUsThereSearchThrottleClock::now();

        auto const itr =
            sGetUsThereSearchLastAccepted.find(guid);

        if (itr != sGetUsThereSearchLastAccepted.end() &&
            now - itr->second < GetUsThereSearchThrottleInterval)
        {
            return false;
        }

        sGetUsThereSearchLastAccepted[guid] = now;
        return true;
    }

    void ClearGetUsThereSearchThrottle(Player const* player)
    {
        if (!player)
            return;

        sGetUsThereSearchLastAccepted.erase(player->GetGUID());
    }

    using GetUsThereTeleportThrottleClock = std::chrono::steady_clock;

    constexpr std::chrono::milliseconds
        GetUsThereTeleportThrottleInterval{250};

    std::unordered_map<
        ObjectGuid,
        GetUsThereTeleportThrottleClock::time_point>
        sGetUsThereTeleportLastAccepted;

    bool TryConsumeGetUsThereTeleportThrottle(Player const* player)
    {
        if (!player)
            return false;

        ObjectGuid const guid = player->GetGUID();
        GetUsThereTeleportThrottleClock::time_point const now =
            GetUsThereTeleportThrottleClock::now();

        auto const itr =
            sGetUsThereTeleportLastAccepted.find(guid);

        if (itr != sGetUsThereTeleportLastAccepted.end() &&
            now - itr->second < GetUsThereTeleportThrottleInterval)
        {
            return false;
        }

        sGetUsThereTeleportLastAccepted[guid] = now;
        return true;
    }

    void ClearGetUsThereTeleportThrottle(Player const* player)
    {
        if (!player)
            return;

        sGetUsThereTeleportLastAccepted.erase(player->GetGUID());
    }

    using GetUsThereTeleportCooldownClock = std::chrono::steady_clock;

    std::unordered_map<
        ObjectGuid,
        GetUsThereTeleportCooldownClock::time_point>
        sGetUsThereTeleportLastSuccessful;

    bool IsGetUsThereTeleportCooldownActive(Player const* player)
    {
        if (!player)
            return false;

        uint32 const cooldownSeconds =
            sGetUsThereConfig.GetConfigValue<uint32>(
                GetUsThereConfig::TeleportCooldownSeconds);

        if (cooldownSeconds == 0u)
            return false;

        ObjectGuid const guid = player->GetGUID();

        auto const itr =
            sGetUsThereTeleportLastSuccessful.find(guid);

        if (itr == sGetUsThereTeleportLastSuccessful.end())
            return false;

        GetUsThereTeleportCooldownClock::time_point const now =
            GetUsThereTeleportCooldownClock::now();

        if (now - itr->second >=
            std::chrono::seconds(cooldownSeconds))
        {
            sGetUsThereTeleportLastSuccessful.erase(itr);
            return false;
        }

        return true;
    }

    void MarkGetUsThereTeleportSuccessful(Player const* player)
    {
        if (!player)
            return;

        sGetUsThereTeleportLastSuccessful[player->GetGUID()] =
            GetUsThereTeleportCooldownClock::now();
    }

    void ClearGetUsThereTeleportCooldown(Player const* player)
    {
        if (!player)
            return;

        sGetUsThereTeleportLastSuccessful.erase(player->GetGUID());
    }

    bool IsGetUsThereTestOverrideAuthorized(Player const* player)
    {
        if (!player || !player->GetSession())
            return false;

        if (!sGetUsThereConfig.GetConfigValue<bool>(
                GetUsThereConfig::TestOverrideEnable))
        {
            return false;
        }

        std::string_view const configuredIds =
            sGetUsThereConfig.GetConfigValue(
                GetUsThereConfig::TestOverrideAllowedAccountIds);

        if (configuredIds.empty())
            return false;

        uint32 const accountId = player->GetSession()->GetAccountId();
        bool accountAllowed = false;

        std::size_t begin = 0;

        while (begin <= configuredIds.size())
        {
            std::size_t const comma = configuredIds.find(',', begin);
            std::size_t const end =
                comma == std::string_view::npos
                    ? configuredIds.size()
                    : comma;

            std::string_view token =
                configuredIds.substr(begin, end - begin);

            while (!token.empty() &&
                   std::isspace(
                       static_cast<unsigned char>(token.front())))
            {
                token.remove_prefix(1);
            }

            while (!token.empty() &&
                   std::isspace(
                       static_cast<unsigned char>(token.back())))
            {
                token.remove_suffix(1);
            }

            if (token.empty())
                return false;

            uint32 configuredAccountId = 0;

            auto const parseResult = std::from_chars(
                token.data(),
                token.data() + token.size(),
                configuredAccountId);

            if (parseResult.ec != std::errc{} ||
                parseResult.ptr != token.data() + token.size() ||
                configuredAccountId == 0u)
            {
                return false;
            }

            if (configuredAccountId == accountId)
                accountAllowed = true;

            if (comma == std::string_view::npos)
                break;

            begin = comma + 1;
        }

        return accountAllowed;
    }

    bool ParseGetUsThereTeleportRequestWithPrefix(
        std::string const& message,
        std::string_view prefix,
        GetUsThereTeleportRequest& request)
    {
        if (message.size() > GetUsThereMaxAddonPayloadLength)
            return false;

        if (message.size() <= prefix.size() ||
            message.compare(
                0,
                prefix.size(),
                prefix.data(),
                prefix.size()) != 0)
        {
            return false;
        }

        std::string_view const fields(
            message.data() + prefix.size(),
            message.size() - prefix.size());

        std::size_t const separator = fields.find('\t');

        if (separator == std::string_view::npos ||
            separator == 0 ||
            separator + 1 >= fields.size() ||
            fields.find('\t', separator + 1) != std::string_view::npos)
        {
            return false;
        }

        std::string_view const requestIdText =
            fields.substr(0, separator);
        std::string_view const gameTeleIdText =
            fields.substr(separator + 1);

        uint32 requestId = 0;
        uint32 gameTeleId = 0;

        auto const requestParse = std::from_chars(
            requestIdText.data(),
            requestIdText.data() + requestIdText.size(),
            requestId);

        if (requestParse.ec != std::errc{} ||
            requestParse.ptr != requestIdText.data() + requestIdText.size())
        {
            return false;
        }

        auto const destinationParse = std::from_chars(
            gameTeleIdText.data(),
            gameTeleIdText.data() + gameTeleIdText.size(),
            gameTeleId);

        if (destinationParse.ec != std::errc{} ||
            destinationParse.ptr !=
                gameTeleIdText.data() + gameTeleIdText.size())
        {
            return false;
        }

        request.requestId = requestId;
        request.gameTeleId = gameTeleId;
        return true;
    }

    bool ParseGetUsThereTeleportRequest(
        std::string const& message,
        GetUsThereTeleportRequest& request)
    {
        return ParseGetUsThereTeleportRequestWithPrefix(
            message,
            GetUsThereTeleportRequestPrefix,
            request);
    }

    bool ParseGetUsThereTeleportTestRequest(
        std::string const& message,
        GetUsThereTeleportRequest& request)
    {
        return ParseGetUsThereTeleportRequestWithPrefix(
            message,
            GetUsThereTeleportTestRequestPrefix,
            request);
    }

    bool ParseGetUsThereFiniteFloat(
        std::string_view text,
        float& value)
    {
        if (text.empty())
            return false;

        auto const result = std::from_chars(
            text.data(),
            text.data() + text.size(),
            value);

        return result.ec == std::errc{} &&
               result.ptr == text.data() + text.size() &&
               std::isfinite(value);
    }

    bool ParseGetUsThereTeleportCoordTestRequest(
        std::string const& message,
        GetUsThereTeleportCoordRequest& request)
    {
        if (message.size() > GetUsThereMaxAddonPayloadLength)
            return false;

        std::string_view const prefix =
            GetUsThereTeleportCoordTestRequestPrefix;

        if (message.size() <= prefix.size() ||
            message.compare(0, prefix.size(), prefix) != 0)
        {
            return false;
        }

        std::string_view const remainder(
            message.data() + prefix.size(),
            message.size() - prefix.size());

        std::vector<std::string_view> fields;
        std::size_t begin = 0;

        while (begin <= remainder.size())
        {
            std::size_t const tab = remainder.find('\t', begin);
            std::size_t const end =
                tab == std::string_view::npos ? remainder.size() : tab;

            fields.emplace_back(remainder.substr(begin, end - begin));

            if (tab == std::string_view::npos)
                break;

            begin = tab + 1;
        }

        if (fields.size() != 5)
            return false;

        for (std::string_view const field : fields)
            if (field.empty())
                return false;

        uint32 requestId = 0;
        uint32 mapId = 0;

        auto const requestParse =
            std::from_chars(fields[0].data(), fields[0].data() + fields[0].size(), requestId);

        auto const mapParse =
            std::from_chars(fields[1].data(), fields[1].data() + fields[1].size(), mapId);

        if (requestParse.ec != std::errc{} ||
            requestParse.ptr != fields[0].data() + fields[0].size() ||
            mapParse.ec != std::errc{} ||
            mapParse.ptr != fields[1].data() + fields[1].size())
        {
            return false;
        }

        float x = 0.0f;
        float y = 0.0f;
        float z = 0.0f;

        if (!ParseGetUsThereFiniteFloat(fields[2], x) ||
            !ParseGetUsThereFiniteFloat(fields[3], y) ||
            !ParseGetUsThereFiniteFloat(fields[4], z))
        {
            return false;
        }

        request.requestId = requestId;
        request.mapId = mapId;
        request.x = x;
        request.y = y;
        request.z = z;
        return true;
    }

    bool ParseGetUsThereSearchRequestWithPrefix(
        std::string const& message,
        std::string_view prefix,
        GetUsThereSearchRequest& request)
    {

        if (message.size() > GetUsThereMaxAddonPayloadLength)
            return false;

        if (message.compare(
                0,
                prefix.size(),
                prefix.data(),
                prefix.size()) != 0)
        {
            return false;
        }

        std::string_view const remainder(
            message.data() + prefix.size(),
            message.size() - prefix.size());

        std::size_t const separator = remainder.find('\t');

        if (separator == std::string_view::npos)
            return false;

        std::string_view const requestIdText =
            remainder.substr(0, separator);

        std::string_view const queryText =
            remainder.substr(separator + 1);

        if (requestIdText.empty() ||
            queryText.size() > GetUsThereMaxSearchQueryLength)
        {
            return false;
        }

        for (char const c : queryText)
        {
            unsigned char const byte = static_cast<unsigned char>(c);

            if (byte < 0x20u || byte == 0x7Fu)
                return false;
        }

        uint32 requestId = 0;

        auto const parseResult = std::from_chars(
            requestIdText.data(),
            requestIdText.data() + requestIdText.size(),
            requestId);

        if (parseResult.ec != std::errc{} ||
            parseResult.ptr != requestIdText.data() + requestIdText.size())
        {
            return false;
        }

        request.requestId = requestId;
        request.query.assign(queryText.begin(), queryText.end());

        return true;
    }

    bool ParseGetUsThereSearchRequest(
        std::string const& message,
        GetUsThereSearchRequest& request)
    {
        return ParseGetUsThereSearchRequestWithPrefix(
            message,
            GetUsThereSearchRequestPrefix,
            request);
    }

    bool ParseGetUsThereSearchTestRequest(
        std::string const& message,
        GetUsThereSearchRequest& request)
    {
        return ParseGetUsThereSearchRequestWithPrefix(
            message,
            GetUsThereSearchTestRequestPrefix,
            request);
    }

    std::string SanitizeGetUsThereWireField(std::string value)
    {
        for (char& c : value)
        {
            unsigned char const byte = static_cast<unsigned char>(c);

            // Tabs delimit protocol fields, and CR/LF or other control bytes
            // must never be allowed to alter addon-message framing.
            if (byte < 0x20u || byte == 0x7Fu)
                c = ' ';
        }

        return value;
    }

    std::string BuildGetUsThereSearchResultPayload(
        uint32 requestId,
        GetUsThereDestination const& destination)
    {
        GameTele const* const tele =
            sObjectMgr->GetGameTele(destination.gameTeleId);

        if (!tele)
            return {};

        std::string payload =
            "GetUsThere\tRESULT\t" +
            std::to_string(requestId) + "\t" +
            std::to_string(destination.gameTeleId) + "\t" +
            SanitizeGetUsThereWireField(destination.displayName) + "\t" +
            SanitizeGetUsThereWireField(destination.category) + "\t" +
            std::to_string(
                static_cast<uint32>(destination.recommendedLevel)) + "\t" +
            (destination.groupTeleportAllowed ? "1" : "0") + "\t" +
            std::to_string(tele->mapId) + "\t" +
            std::to_string(tele->position_x) + "\t" +
            std::to_string(tele->position_y) + "\t" +
            std::to_string(tele->position_z);

        if (payload.size() > GetUsThereMaxAddonPayloadLength)
            return {};

        return payload;
    }

    std::string BuildGetUsThereSearchDonePayload(
        uint32 requestId,
        std::size_t resultCount)
    {
        std::string payload =
            "GetUsThere\tDONE\t" +
            std::to_string(requestId) + "\t" +
            std::to_string(resultCount);

        if (payload.size() > GetUsThereMaxAddonPayloadLength)
            return {};

        return payload;
    }

    bool IsGetUsThereAddonPayload(
        uint32 type,
        uint32 language,
        std::string const& message)
    {
        if (type != CHAT_MSG_WHISPER || language != LANG_ADDON)
            return false;

        return message.compare(
                   0,
                   sizeof(GetUsThereAddonPrefix) - 1,
                   GetUsThereAddonPrefix) == 0;
    }

    void SendGetUsThereAddonPayload(
        Player* player,
        std::string const& payload)
    {
        if (!player)
            return;

        if (payload.empty() ||
            payload.size() > GetUsThereMaxAddonPayloadLength)
        {
            LOG_ERROR(
                "server.loading",
                "GetUsThere: refused outbound addon payload with invalid "
                "length {}.",
                payload.size());

            return;
        }

        WorldPacket data;
        ChatHandler::BuildChatPacket(
            data,
            CHAT_MSG_WHISPER,
            LANG_ADDON,
            player,
            player,
            payload);

        player->SendDirectMessage(&data);
    }

    std::string_view GetUsTherePolicyErrorCode(
        GetUsTherePolicyDecision decision)
    {
        switch (decision)
        {
            case GetUsTherePolicyDecision::Allowed:
                return "ALLOWED";
            case GetUsTherePolicyDecision::DestinationDisabled:
                return "DESTINATION_DISABLED";
            case GetUsTherePolicyDecision::InvalidPlayerFaction:
                return "INVALID_PLAYER_FACTION";
            case GetUsTherePolicyDecision::RivalTerritoryBlocked:
                return "RIVAL_TERRITORY_BLOCKED";
            case GetUsTherePolicyDecision::RivalCapitalBlocked:
                return "RIVAL_CAPITAL_BLOCKED";
            case GetUsTherePolicyDecision::RivalStarterZoneBlocked:
                return "RIVAL_STARTER_ZONE_BLOCKED";
            case GetUsTherePolicyDecision::LevelTooLow:
                return "LEVEL_TOO_LOW";
        }

        return "POLICY_BLOCKED";
    }

    std::string_view GetUsThereSafetyErrorCode(
        GetUsThereTeleportSafetyDecision decision)
    {
        switch (decision)
        {
            case GetUsThereTeleportSafetyDecision::Allowed:
                return "ALLOWED";
            case GetUsThereTeleportSafetyDecision::InvalidPlayer:
                return "INVALID_PLAYER";
            case GetUsThereTeleportSafetyDecision::AlreadyTeleporting:
                return "ALREADY_TELEPORTING";
            case GetUsThereTeleportSafetyDecision::InCombat:
                return "IN_COMBAT";
            case GetUsThereTeleportSafetyDecision::DeadOrGhost:
                return "DEAD_OR_GHOST";
            case GetUsThereTeleportSafetyDecision::InFlight:
                return "IN_FLIGHT";
            case GetUsThereTeleportSafetyDecision::OnTransport:
                return "ON_TRANSPORT";
            case GetUsThereTeleportSafetyDecision::InBattlegroundOrArena:
                return "IN_BATTLEGROUND_OR_ARENA";
            case GetUsThereTeleportSafetyDecision::InDungeon:
                return "IN_DUNGEON";
            case GetUsThereTeleportSafetyDecision::InRaid:
                return "IN_RAID";
        }

        return "SAFETY_BLOCKED";
    }

    std::string BuildGetUsThereTeleportErrorPayload(
        std::string_view errorCode,
        GetUsThereTeleportRequest const& request)
    {
        std::string payload =
            std::string("GetUsThere\tERROR\t") +
            std::string(errorCode) + "\t" +
            std::to_string(request.requestId) + "\t" +
            std::to_string(request.gameTeleId);

        if (payload.size() > GetUsThereMaxAddonPayloadLength)
            return {};

        return payload;
    }

    std::string BuildGetUsThereTeleportCoordErrorPayload(
        std::string_view errorCode,
        GetUsThereTeleportCoordRequest const& request)
    {
        std::string payload =
            std::string("GetUsThere\tERROR\t") +
            std::string(errorCode) + "\t" +
            std::to_string(request.requestId) + "\t" +
            std::to_string(request.mapId);

        if (payload.size() > GetUsThereMaxAddonPayloadLength)
            return {};

        return payload;
    }

    void DispatchGetUsThereTeleportCoordTest(
        Player* player,
        GetUsThereTeleportCoordRequest const& request)
    {
        if (!player)
            return;

        float const orientation = player->GetOrientation();

        if (!MapMgr::IsValidMapCoord(
                request.mapId,
                request.x,
                request.y,
                request.z,
                orientation))
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportCoordErrorPayload(
                    "INVALID_MAP_OR_COORDS",
                    request));
            return;
        }

        GetUsThereTeleportSafetyDecision const safetyDecision =
            EvaluateGetUsThereTeleportSafety(player, true);

        if (safetyDecision != GetUsThereTeleportSafetyDecision::Allowed)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportCoordErrorPayload(
                    GetUsThereSafetyErrorCode(safetyDecision),
                    request));
            return;
        }

        GetUsThereTeleportSafetyDecision const finalSafetyDecision =
            EvaluateGetUsThereTeleportSafety(player, true);

        if (finalSafetyDecision != GetUsThereTeleportSafetyDecision::Allowed)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportCoordErrorPayload(
                    GetUsThereSafetyErrorCode(finalSafetyDecision),
                    request));
            return;
        }

        bool const accepted =
            player->TeleportTo(
                request.mapId,
                request.x,
                request.y,
                request.z,
                orientation,
                TELE_TO_GM_MODE);

        if (!accepted)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportCoordErrorPayload(
                    "TELEPORT_FAILED",
                    request));
            return;
        }

        std::string const payload =
            std::string("GetUsThere\tCOORD_TELEPORTED\t") +
            std::to_string(request.requestId) + "\t" +
            std::to_string(request.mapId) + "\tOK";

        SendGetUsThereAddonPayload(player, payload);
    }

    void DispatchGetUsThereTeleport(
        Player* player,
        GetUsThereTeleportRequest const& request,
        bool testOverride = false)
    {
        if (!player)
            return;

        GetUsThereDestination const* destination =
            sGetUsThereCatalog.FindByGameTeleId(request.gameTeleId);

        if (!destination)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    "DESTINATION_NOT_FOUND",
                    request));
            return;
        }

        if (testOverride)
        {
            if (!destination->enabled)
            {
                SendGetUsThereAddonPayload(
                    player,
                    BuildGetUsThereTeleportErrorPayload(
                        "DESTINATION_DISABLED",
                        request));
                return;
            }
        }
        else
        {
            GetUsTherePolicyDecision const policyDecision =
                EvaluateGetUsThereDestinationPolicy(
                    player,
                    *destination);

            if (policyDecision != GetUsTherePolicyDecision::Allowed)
            {
                SendGetUsThereAddonPayload(
                    player,
                    BuildGetUsThereTeleportErrorPayload(
                        GetUsTherePolicyErrorCode(policyDecision),
                        request));
                return;
            }
        }

        // For curated destination requests, metadata authorizes exposure and
        // AzerothCore game_tele remains the sole authority for map and coordinates.
        GameTele const* const tele =
            sObjectMgr->GetGameTele(request.gameTeleId);

        if (!tele)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    "GAME_TELE_NOT_FOUND",
                    request));
            return;
        }

        GetUsThereTeleportSafetyDecision const safetyDecision =
            EvaluateGetUsThereTeleportSafety(player, testOverride);

        if (safetyDecision != GetUsThereTeleportSafetyDecision::Allowed)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    GetUsThereSafetyErrorCode(safetyDecision),
                    request));
            return;
        }

        if (!testOverride &&
            IsGetUsThereTeleportCooldownActive(player))
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    "TELEPORT_COOLDOWN",
                    request));
            return;
        }

        // Re-check immediately before curated teleport execution. TELEPORT and
        // TELEPORT_TEST use only server-owned game_tele coordinates. Client-supplied
        // coordinates are accepted only by authorized TELEPORT_COORD_TEST.
        GetUsThereTeleportSafetyDecision const finalSafetyDecision =
            EvaluateGetUsThereTeleportSafety(player, testOverride);

        if (finalSafetyDecision != GetUsThereTeleportSafetyDecision::Allowed)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    GetUsThereSafetyErrorCode(finalSafetyDecision),
                    request));
            return;
        }

        bool const accepted =
            player->TeleportTo(
                tele->mapId,
                tele->position_x,
                tele->position_y,
                tele->position_z,
                tele->orientation);

        if (!accepted)
        {
            SendGetUsThereAddonPayload(
                player,
                BuildGetUsThereTeleportErrorPayload(
                    "TELEPORT_FAILED",
                    request));
            return;
        }

        // Normal TELEPORT consumes cooldown only after AzerothCore accepts it.
        // Authorized TELEPORT_TEST must not alter normal-protocol cooldown state.
        if (!testOverride)
            MarkGetUsThereTeleportSuccessful(player);

        std::string const payload =
            std::string("GetUsThere\tTELEPORTED\t") +
            std::to_string(request.requestId) + "\t" +
            std::to_string(request.gameTeleId) + "\tOK";

        SendGetUsThereAddonPayload(player, payload);
    }

    void DispatchGetUsThereSearchResults(
        Player* player,
        GetUsThereSearchRequest const& request,
        bool testOverride = false)
    {
        if (!player)
            return;

        // Retrieve all policy-eligible textual matches first. The wire result
        // limit is applied only after each result has been successfully framed,
        // so an oversized catalog field cannot consume one of the 20 slots.
        std::vector<GetUsThereDestination> const matches =
            SearchGetUsThereDestinationsForPlayer(
                player,
                request.query,
                sGetUsThereCatalog.Size(),
                testOverride);

        std::size_t sentCount = 0;

        for (GetUsThereDestination const& destination : matches)
        {
            std::string const payload =
                BuildGetUsThereSearchResultPayload(
                    request.requestId,
                    destination);

            if (payload.empty())
            {
                LOG_WARN(
                    "server.loading",
                    "GetUsThere: search result for game_tele id {} could not "
                    "fit within the addon payload limit; result skipped.",
                    destination.gameTeleId);

                continue;
            }

            SendGetUsThereAddonPayload(player, payload);
            ++sentCount;

            if (sentCount >= GetUsThereSearchResultLimit)
                break;
        }

        std::string const donePayload =
            BuildGetUsThereSearchDonePayload(
                request.requestId,
                sentCount);

        if (donePayload.empty())
        {
            LOG_ERROR(
                "server.loading",
                "GetUsThere: failed to build SEARCH DONE payload for "
                "request id {}.",
                request.requestId);

            return;
        }

        SendGetUsThereAddonPayload(player, donePayload);
    }

    class GetUsThereAddonScript : public PlayerScript
    {
    public:
        GetUsThereAddonScript()
            : PlayerScript(
                  "GetUsThereAddonScript",
                  {
                      PLAYERHOOK_ON_BEFORE_LOGOUT,
                      PLAYERHOOK_CAN_PLAYER_USE_PRIVATE_CHAT
                  })
        {
        }

        void OnPlayerBeforeLogout(Player* player) override
        {
            ClearGetUsThereSearchThrottle(player);
            ClearGetUsThereTeleportThrottle(player);
            ClearGetUsThereTeleportCooldown(player);
        }

        bool OnPlayerCanUseChat(
            Player* player,
            uint32 type,
            uint32 language,
            std::string& message,
            Player* receiver) override
        {
            if (!IsGetUsThereAddonPayload(type, language, message))
                return true;

            // Get Us There protocol traffic is private client/server traffic.
            // Never relay one of our protocol messages to another player.
            if (!player || !receiver || receiver != player)
            {
                if (player)
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tSELF_ONLY");

                return false;
            }

            if (!sGetUsThereConfig.IsEnabled())
            {
                SendGetUsThereAddonPayload(
                    player,
                    "GetUsThere\tERROR\tDISABLED");

                return false;
            }

            if (message == GetUsThereHelloRequest)
            {
                SendGetUsThereAddonPayload(
                    player,
                    GetUsThereHelloResponse);

                return false;
            }

            if (message.compare(
                    0,
                    sizeof(GetUsThereTeleportCoordTestRequestPrefix) - 1,
                    GetUsThereTeleportCoordTestRequestPrefix) == 0)
            {
                GetUsThereTeleportCoordRequest coordRequest;

                if (!ParseGetUsThereTeleportCoordTestRequest(
                        message,
                        coordRequest))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tTELEPORT_COORD_TEST_FORMAT");
                    return false;
                }

                if (!TryConsumeGetUsThereTeleportThrottle(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        BuildGetUsThereTeleportCoordErrorPayload(
                            "TELEPORT_THROTTLED",
                            coordRequest));
                    return false;
                }

                if (!IsGetUsThereTestOverrideAuthorized(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        BuildGetUsThereTeleportCoordErrorPayload(
                            "TEST_OVERRIDE_DENIED",
                            coordRequest));
                    return false;
                }

                DispatchGetUsThereTeleportCoordTest(
                    player,
                    coordRequest);

                return false;
            }

            if (message.compare(
                    0,
                    sizeof(GetUsThereTeleportTestRequestPrefix) - 1,
                    GetUsThereTeleportTestRequestPrefix) == 0)
            {
                GetUsThereTeleportRequest teleportRequest;

                if (!ParseGetUsThereTeleportTestRequest(
                        message,
                        teleportRequest))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tTELEPORT_TEST_FORMAT");

                    return false;
                }

                if (!TryConsumeGetUsThereTeleportThrottle(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        BuildGetUsThereTeleportErrorPayload(
                            "TELEPORT_THROTTLED",
                            teleportRequest));

                    return false;
                }

                if (!IsGetUsThereTestOverrideAuthorized(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        BuildGetUsThereTeleportErrorPayload(
                            "TEST_OVERRIDE_DENIED",
                            teleportRequest));

                    return false;
                }

                DispatchGetUsThereTeleport(
                    player,
                    teleportRequest,
                    true);

                return false;
            }

            if (message.compare(
                    0,
                    sizeof(GetUsThereTeleportRequestPrefix) - 1,
                    GetUsThereTeleportRequestPrefix) == 0)
            {
                GetUsThereTeleportRequest teleportRequest;

                if (!ParseGetUsThereTeleportRequest(
                        message,
                        teleportRequest))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tTELEPORT_FORMAT");

                    return false;
                }

                if (!TryConsumeGetUsThereTeleportThrottle(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        BuildGetUsThereTeleportErrorPayload(
                            "TELEPORT_THROTTLED",
                            teleportRequest));

                    return false;
                }

                DispatchGetUsThereTeleport(
                    player,
                    teleportRequest);

                return false;
            }

            if (message.compare(
                    0,
                    sizeof(GetUsThereSearchTestRequestPrefix) - 1,
                    GetUsThereSearchTestRequestPrefix) == 0)
            {
                GetUsThereSearchRequest searchRequest;

                if (!ParseGetUsThereSearchTestRequest(
                        message,
                        searchRequest))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tSEARCH_TEST_FORMAT");

                    return false;
                }

                if (!TryConsumeGetUsThereSearchThrottle(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        std::string(
                            "GetUsThere\tERROR\tSEARCH_THROTTLED\t") +
                            std::to_string(searchRequest.requestId));

                    return false;
                }

                if (!IsGetUsThereTestOverrideAuthorized(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        std::string(
                            "GetUsThere\tERROR\tTEST_OVERRIDE_DENIED\t") +
                            std::to_string(searchRequest.requestId));

                    return false;
                }

                DispatchGetUsThereSearchResults(
                    player,
                    searchRequest,
                    true);

                return false;
            }

            if (message.compare(
                    0,
                    sizeof(GetUsThereSearchRequestPrefix) - 1,
                    GetUsThereSearchRequestPrefix) == 0)
            {
                GetUsThereSearchRequest searchRequest;

                if (!ParseGetUsThereSearchRequest(
                        message,
                        searchRequest))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        "GetUsThere\tERROR\tSEARCH_FORMAT");

                    return false;
                }

                if (!TryConsumeGetUsThereSearchThrottle(player))
                {
                    SendGetUsThereAddonPayload(
                        player,
                        std::string(
                            "GetUsThere\tERROR\tSEARCH_THROTTLED\t") +
                            std::to_string(searchRequest.requestId));

                    return false;
                }

                DispatchGetUsThereSearchResults(
                    player,
                    searchRequest);

                return false;
            }

            SendGetUsThereAddonPayload(
                player,
                "GetUsThere\tERROR\tUNSUPPORTED");

            return false;
        }
    };
}

void AddGetUsThereScripts()
{
    new GetUsThereWorldScript();
    new GetUsThereAddonScript();
}
