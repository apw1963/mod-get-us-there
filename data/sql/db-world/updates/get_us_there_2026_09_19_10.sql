-- Get Us There
-- Settlement expansion batch 10 world database update
--
-- Adds 29 individually researched Settlement destinations.
-- Stock AzerothCore game_tele rows remain authoritative for coordinates.
-- territory_faction: 0 = neutral, 1 = Alliance, 2 = Horde.
-- recommended_level values were resolved from local AreaTable, quest,
-- NPC, faction, and progression evidence.
-- Altar of Sha'tar and Sanctum of the Stars remain deferred because
-- Aldor/Scryer hostility is not represented by the current faction model.
-- Zul'Aman remains excluded as an instance complex.

INSERT INTO `mod_get_us_there_destination`
(
    `game_tele_id`,
    `display_name`,
    `category`,
    `territory_faction`,
    `recommended_level`,
    `is_capital`,
    `is_protected_faction_zone`,
    `enabled`,
    `group_teleport_allowed`,
    `sort_order`
)
VALUES
    (636, 'Moonglade', 'Settlement', 0, 10, 0, 0, 1, 1, 1670),
    (1373, 'Zoram''gar Outpost', 'Settlement', 2, 17, 0, 0, 1, 1, 1680),
    (389, 'Forest Song', 'Settlement', 1, 24, 0, 0, 1, 1, 1690),
    (1121, 'Theramore', 'Settlement', 1, 36, 0, 0, 1, 1, 1700),
    (1004, 'Thalanaar', 'Settlement', 1, 40, 0, 0, 1, 1, 1710),
    (980, 'Talrendis Point', 'Settlement', 1, 45, 0, 0, 1, 1, 1720),
    (1203, 'Thorium Point', 'Settlement', 0, 45, 0, 0, 1, 1, 1730),
    (607, 'Marshal''s Refuge', 'Settlement', 0, 47, 0, 0, 1, 1, 1740),
    (206, 'Chillwind Camp', 'Settlement', 1, 50, 0, 0, 1, 1, 1750),
    (387, 'Flame Crest', 'Settlement', 2, 50, 0, 0, 1, 1, 1760),
    (139, 'Bloodvenom Post', 'Settlement', 2, 52, 0, 0, 1, 1, 1770),
    (490, 'Honor Hold', 'Settlement', 1, 58, 0, 0, 1, 1, 1780),
    (1207, 'Thrallmar', 'Settlement', 2, 58, 0, 0, 1, 1, 1790),
    (356, 'Falcon Watch', 'Settlement', 2, 60, 0, 0, 1, 1, 1800),
    (974, 'Swamprat Post', 'Settlement', 2, 60, 0, 0, 1, 1, 1810),
    (988, 'Telredor', 'Settlement', 1, 60, 0, 0, 1, 1, 1820),
    (992, 'Temple of Telhamat', 'Settlement', 1, 60, 0, 0, 1, 1, 1830),
    (19, 'Allerian Stronghold', 'Settlement', 1, 62, 0, 0, 1, 1, 1840),
    (702, 'Orebor Harborage', 'Settlement', 1, 62, 0, 0, 1, 1, 1850),
    (940, 'Stonebreaker Hold', 'Settlement', 2, 62, 0, 0, 1, 1, 1860),
    (1361, 'Zabra''jin', 'Settlement', 2, 62, 0, 0, 1, 1, 1870),
    (413, 'Garadar', 'Settlement', 2, 64, 0, 0, 1, 1, 1880),
    (984, 'Telaar', 'Settlement', 1, 64, 0, 0, 1, 1, 1890),
    (976, 'Sylvanaar', 'Settlement', 1, 65, 0, 0, 1, 1, 1900),
    (1215, 'Thunderlord Stronghold', 'Settlement', 2, 65, 0, 0, 1, 1, 1910),
    (53, 'Area 52', 'Settlement', 0, 67, 0, 0, 1, 1, 1920),
    (841, 'Shadowmoon Village', 'Settlement', 2, 67, 0, 0, 1, 1, 1930),
    (1166, 'The Stormspire', 'Settlement', 0, 67, 0, 0, 1, 1, 1940),
    (1334, 'Wildhammer Stronghold', 'Settlement', 1, 67, 0, 0, 1, 1, 1950);
