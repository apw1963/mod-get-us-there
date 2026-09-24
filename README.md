# Get Us There

Get Us There provides searchable, server-authoritative teleport support for
AzerothCore WotLK 3.3.5a.

**Companion WoW addon:** https://github.com/apw1963/GetUsThere

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

## Client options

The client addon includes an **Options** window with three categories.

### Appearance

- **UI Scale** adjusts the overall Get Us There interface scale.
- **Window Opacity** adjusts the main window transparency.
- **Text Size** adjusts Get Us There text independently of UI Scale.

### Window

- **Remember Window Position** restores the main window to its last dragged
  position after `/reload`.
- **Lock Window Position** prevents accidental dragging of the main window.
- **Hide in Combat** automatically hides the Get Us There interface when the
  player, party, or raid enters combat.
- **Restore After Combat** restores whichever Get Us There windows were open
  when the combat hide occurred.

### Display

- **Show Manual Map / X / Y / Z Controls** controls whether the raw-coordinate
  panel is shown when Test Override is enabled.
- **Show Minimap Button** controls the draggable Get Us There launcher around
  the minimap. Left-click opens or closes the main window, and dragging changes
  its saved position.

Client presentation preferences are saved in `GetUsThereDB` and survive
`/reload`. Test Override authorization/state remains session-only and is never
persisted by the addon.

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

### Race / starter-zone aliases

Race-name discovery is supported through the existing server-authoritative alias
catalog and the **Leveling Zones** search scope. Race aliases do not create new
teleport destinations and do not bypass normal destination policy.

Current starter-area discovery aliases are:

- Human -> Northshire Valley
- Dwarf -> Coldridge Valley
- Gnome -> Coldridge Valley
- Night Elf -> Shadowglen
- Draenei -> Crash Site
- Orc -> Valley of Trials
- Troll -> Valley of Trials
- Tauren -> Camp Narache
- Undead -> Shadow Grave
- Blood Elf -> The Sunspire

Shared starter locations remain represented by one authoritative destination with
multiple aliases. In particular, Dwarf/Gnome share Coldridge Valley and Orc/Troll
share Valley of Trials.

Opposing-faction destinations remain discoverable in search across current and
future destination categories. Visibility does not grant travel permission: the
server still evaluates normal faction, level, starter-zone, capital, and other
travel policy when a teleport is requested.

For a blocked opposing-faction destination, the client displays:

`Opposing Faction Territory.`

followed by:

`Enable Screw You! and defy restrictions at your own peril, explorer.`

The main Get Us There window is currently 560 x 640 to provide sufficient room
for the two-line warning and the lower coordinate/override controls.

## Development / Test Override

Get Us There includes a server-gated Test Override intended for development,
validation, and administrator-directed travel.

It is disabled by default:

- `GetUsThere.TestOverride.Enable = 0`
- `GetUsThere.TestOverride.AllowedAccountIds = ""`

When authorized, the client option **Screw you! I'll go where I want, whenever
I want.** is intentionally literal. It can bypass selected normal curated travel
restrictions and exposes a raw-coordinate path for exact Map/X/Y/Z requests.

Raw-coordinate travel bypasses the curated destination catalog. The server still
enforces override authorization, protocol validation, basic map/coordinate
validity, and general teleport-safety checks, but Get Us There does not attempt
to prevent a server owner from deliberately traveling to unusual, inaccessible,
unused, or normally non-playable locations.

That freedom is intentional. Server administrators decide whether Test Override
is enabled and who may use it. Once an authorized user deliberately chooses
override or raw-coordinate travel, responsibility for the destination and its
consequences belongs to that server owner/user.

Normal `SEARCH` and `TELEPORT` requests are separate from Test Override behavior.

## Client compatibility

The included client addon targets World of Warcraft 3.3.5a with interface number
`30300`.

Current client addon version: `0.2.0`.

## License

Get Us There is distributed under the MIT License. See `LICENSE`.
