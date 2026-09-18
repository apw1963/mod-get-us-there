# Get Us There

Get Us There provides searchable, server-authoritative teleport support for
AzerothCore WotLK 3.3.5a.

The client addon asks for destinations and requests travel. The server decides
which destinations are visible, whether the player is allowed to use them, and
whether a teleport is safe to perform.

## Features

- `/gut` opens the Get Us There client interface.
- Search by curated destination name, category, or configured alias.
- Search results are supplied and filtered by the server.
- Selecting a result shows the server-provided map and coordinates.
- Pressing Enter performs a search only. Travel requires the explicit
  **Send Us** button.
- Curated destinations can include recommended-level metadata.
- PvE and PvP policy families can be selected explicitly or derived from the
  AzerothCore realm type.
- Faction-capital and protected starter-zone restrictions are server-controlled.
- Own-faction capitals can be allowed regardless of destination level.
- Successful teleports have a configurable per-player cooldown.
- Dungeon-origin and raid-origin teleports are disabled by default.
- Group and raid teleport requests can require the group or raid leader.

## Server-authoritative safety

Normal teleport requests are evaluated by the server. The accepted implementation
protects against travel while:

- already teleporting;
- in combat;
- dead or a ghost;
- in flight;
- on a transport;
- in a battleground or arena;
- in a dungeon or raid when the corresponding source-map setting is disabled.

Destination faction, protected-zone, capital, enabled-state, and recommended-level
policy are also evaluated server-side.

## Installation

1. Place the module at:

   `modules/mod-get-us-there`

2. Configure, build, and install AzerothCore normally. The module's world database
   installation SQL is located under:

   `data/sql/db-world/base/`

   and is discovered by the AzerothCore module database updater.

3. Review the installed module configuration:

   `etc/modules/mod_get_us_there.conf`

4. Copy the client addon folder:

   `client/GetUsThere`

   into the WoW 3.3.5a client as:

   `Interface/AddOns/GetUsThere`

5. Start the worldserver and confirm the module and destination catalog load
   successfully.

## Usage

In the WoW client:

1. Enter `/gut`.
2. Type a destination search.
3. Choose the desired result from **Search Results**.
4. Review the server-provided destination information.
5. Click **Send Us**.

Search and teleport are deliberately separate actions.

## Configuration

The distributed configuration file is:

`conf/mod_get_us_there.conf.dist`

Important settings include:

- `GetUsThere.Enable`
- `GetUsThere.PolicyProfile`
- `GetUsThere.BlockRivalCapitals`
- `GetUsThere.BlockRivalStarterZones`
- `GetUsThere.AllowOwnFactionCapitalsAtAnyLevel`
- `GetUsThere.LevelRestriction.Enable`
- `GetUsThere.LevelRestriction.MaxDeficit`
- `GetUsThere.PvP.AllowRivalFactionTerritory`
- `GetUsThere.PvP.AllowRivalCapitals`
- `GetUsThere.PvP.AllowRivalStarterZones`
- `GetUsThere.Teleport.CooldownSeconds`
- `GetUsThere.Teleport.AllowFromDungeon`
- `GetUsThere.Teleport.AllowFromRaid`
- `GetUsThere.GroupTeleport.RequireLeader`
- `GetUsThere.RaidTeleport.RequireLeader`

Runtime configuration reload support is provided by the module.

## Destination data

AzerothCore `game_tele` remains authoritative for teleport coordinates.

Get Us There stores its destination policy and search metadata in the world
database tables:

- `mod_get_us_there_destination`
- `mod_get_us_there_alias`

This keeps travel coordinates in AzerothCore's existing teleport system while
allowing Get Us There to maintain its own curated search and policy metadata.

## Development / Test Override

Get Us There includes a server-gated Test Override intended for development and
validation.

It is disabled by default:

- `GetUsThere.TestOverride.Enable = 0`
- `GetUsThere.TestOverride.AllowedAccountIds = ""`

Authorized testing can bypass selected normal travel restrictions and includes a
raw-coordinate test path. Raw coordinates bypass curated safe destinations and
should not be treated as normal player-facing travel.

Normal `SEARCH` and `TELEPORT` requests are separate from Test Override behavior.

## Client compatibility

The included client addon targets World of Warcraft 3.3.5a with interface number
`30300`.

## License

Get Us There is distributed under the MIT License. See `LICENSE`.
