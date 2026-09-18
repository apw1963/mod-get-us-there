# Get Us There — Engineering Log

This document records validated engineering milestones, runtime evidence, rollback anchors, and development lessons for Get Us There.

## Operating Principles

- The addon asks. The server decides.
- Prefer authoritative server state over client-supplied state.
- Validate changes through controlled gates with explicit evidence.
- Preserve rollback artifacts before replacing accepted binaries or build artifacts.
- Do not treat a build as accepted until live behavior and artifact identity are verified.

## Accepted Milestones

### 2026-09-16 — TELEPORT Request Admission Throttle

Status: LIVE / VALIDATED / ACCEPTED

- Added a fixed 250 ms per-player TELEPORT request-admission throttle.
- Throttle is applied after successful TELEPORT parsing and before teleport policy/safety dispatch.
- Error response: `TELEPORT_THROTTLED`.
- Malformed TELEPORT requests do not consume the throttle.
- Valid policy-rejected TELEPORT requests do consume the throttle interval.
- Existing successful-teleport cooldown remains independent at 5 seconds.
- Logout clears TELEPORT throttle state.
- No configuration, addon UI, destination policy, safety policy, or TeleportTo behavior was changed.

Live validation:
- Normal teleport succeeded: request 8319 to Dalaran.
- Rapid rejected pair: 8320 returned `RIVAL_CAPITAL_BLOCKED`; 8321 returned `TELEPORT_THROTTLED`.
- Throttle expiration verified by successful request 8322 to Stormwind.
- Cooldown independence verified: 8323 succeeded; request 8324 approximately one second later returned `TELEPORT_COOLDOWN`.
- Successful-request precedence verified: 8325 succeeded; immediate 8326 returned `TELEPORT_THROTTLED`.
- Parse placement verified: malformed TELEPORT returned `TELEPORT_FORMAT`; immediate valid 8327 reached `RIVAL_CAPITAL_BLOCKED` rather than throttle.
- All rejected/throttled validation cases produced no unintended movement.

Accepted artifact SHA256 values:
- Source: `096ec46d338f3218b95a7010b1c875e757e56719e831e4535b134d77a35b185c`
- Object: `3dec4e56185c56f134ab6b0a81d6e5f005db4a9681e6208fff63c1ee402adbe6`
- libmodules.a: `01eee988669949b3ebf79d81919a49c94f585db0509da5fec4af81b560b5efc8`
- worldserver: `d22c2406e0dbfcb5e10dd6dd2ff53d59b87592fa58c68db4d6d5cae5fe6c8f12`


### 2026-09-17 — Protected Racial Starter-Area Catalog

Status: LIVE / VALIDATED / ACCEPTED

Added eight curated racial starter-area destinations:

- Alliance:
  - `686` — Northshire Valley
  - `220` — Coldridge Valley
  - `837` — Shadowglen
  - `227` — Crash Site
- Horde:
  - `1278` — Valley of Trials
  - `188` — Camp Narache
  - `838` — Shadow Grave
  - `1168` — The Sunspire

Catalog metadata:

- Category: `Starter Area`
- `recommended_level = 1`
- `is_capital = 0`
- `is_protected_faction_zone = 1`
- `enabled = 1`
- `group_teleport_allowed = 1`
- Alliance rows use `territory_faction = 1`.
- Horde rows use `territory_faction = 2`.

Authoritative validation:

- Candidate `game_tele` entries were compared with non-Death-Knight `playercreateinfo` starting positions.
- All eight live destination rows reference valid `game_tele` records.
- Worldserver startup loaded 18 destinations with 0 rejected and 12 aliases with 0 rejected.

Live policy validation:

- Alliance request 8328 to Northshire Valley succeeded.
- Alliance request 8329 to Horde Valley of Trials returned `RIVAL_STARTER_ZONE_BLOCKED` with no movement.
- Alliance request 8330 to Crash Site succeeded.
- Horde level-1 request 8331 to The Sunspire succeeded.
- Horde request 8332 to Alliance Northshire Valley returned `RIVAL_STARTER_ZONE_BLOCKED` with no movement.
- Horde SEARCH request 8333 returned The Sunspire as `Starter Area`, recommended level 1, group allowed 1.
- Horde SEARCH request 8334 for Northshire returned `DONE` with 0 results, confirming rival protected starter areas are policy-filtered from SEARCH.

Accepted catalog state:

- Destination count: 18
- Recommended-level destination count: 8
- Capital count: 8
- Protected starter-area count: 8
- Enabled destination count: 18
- Alias count: 12
- Seed draft SHA256: `8cc5edadfd029a1bf33cf57ac7be0e4a45952b9c7c08f2c3b9318fea9146b3b5`
- Install candidate SHA256: `0307e2385f529dfc56d8ff2ae3e36a7a3810f53929d6b0f0d6440b24097a11b5`
- Accepted live database snapshot SHA256: `c1830bafb7ef6e05e9a438f946f0990a98395c5b17aae6576acc6e636bb48b35`


### 2026-09-17 — Leveling-Zone Catalog and Safe Arrival Points

Status: LIVE / VALIDATED / ACCEPTED

Added eight curated leveling-zone destinations using Get Us There-owned
`game_tele` safe-arrival records:

- `1997` — Westfall — recommended level 10 — Alliance territory
- `1998` — Redridge Mountains — recommended level 15 — neutral territory
- `1999` — Duskwood — recommended level 20 — neutral territory
- `2000` — Stranglethorn Vale — recommended level 30 — neutral territory
- `2001` — Tanaris — recommended level 40 — neutral territory
- `2002` — Hellfire Peninsula — recommended level 58 — neutral territory
- `2003` — Borean Tundra — recommended level 68 — neutral territory
- `2004` — Dragonblight — recommended level 71 — neutral territory

Safe-arrival validation:

- All eight custom `game_tele` points were directly runtime-tested with
  level-1 Horde character Peteorc.
- Each test arrived alive and remained stationary without NPC or creature
  attack during the controlled observation interval.
- Westfall uses the validated Sentinel Hill graveyard point.
- A later Westfall death was caused by an Alliance rogue; these arrival
  points reduce immediate NPC/environment danger but are not PvP sanctuaries.
- Fresh worldserver startup loaded 1997 GameTeleports.
- Get Us There loaded 26 destinations with 0 rejected and 12 aliases with
  0 rejected.
- No live destination references a missing `game_tele` row.

Recommended-level policy validation:

- Live `MaxDeficit` remains 9.
- Level-1 request 8338 to Redridge `1998` returned `LEVEL_TOO_LOW`.
- Level-1 request 8339 to Westfall `1997` returned `TELEPORTED` and arrived
  at the Westfall/Sentinel Hill graveyard.
- This confirms the level-1 boundary: recommended level 10 is permitted,
  while recommended level 15 is rejected.

Accepted catalog and persistence state:

- Destination count: 26
- Alias count: 12
- Protected starter areas: 8
- Leveling zones: 8
- Destinations with nonzero recommended level: 16
- Safe custom `game_tele` rows: 8
- Seed draft SHA256:
  `f29bf90dc1bfd117db5b8db9308ef76ab6fe9e696b05144a466a1b6e48f8e136`
- Install candidate SHA256:
  `e25283aaeaa0310045cdcc307d712e3aecf07c650b37cce20cb36131a322f1ea`
- Accepted live catalog snapshot SHA256:
  `aaacab3be3c9dd7972ff331f17cdc987762725e18b46ae8a5fab2617c567c623`
- Accepted safe `game_tele` snapshot SHA256:
  `5e2dd152abac34a4148b5fe4ff73bced31781eed3df01a3911e0776494c46dfe`
- No Get Us There source, object, archive, or worldserver binary change was
  required for this milestone.

### 2026-09-17 — Server-Authorized Test Override

Accepted server-side test mode for future GUI exposure under the label:

`Screw you! I'll go wherever I want, whenever I want`

Protocol additions:

- `SEARCH_TEST <requestId> <query>`
- `TELEPORT_TEST <requestId> <gameTeleId>`
- Ordinary `SEARCH` and `TELEPORT` behavior remains unchanged.
- Unauthorized test requests return `TEST_OVERRIDE_DENIED`.

Authorization is server-owned and requires both:

1. `GetUsThere.TestOverride.Enable = 1`
2. The authenticated account ID must be present in
   `GetUsThere.TestOverride.AllowedAccountIds`.

The whitelist parser is fail-closed:

- An empty whitelist authorizes nobody.
- A malformed whitelist authorizes nobody, even if a valid account ID appears
  before the malformed token.
- Runtime validation with `AllowedAccountIds = "473,bad"` returned
  `TEST_OVERRIDE_DENIED` for account 473.

Authorized test override bypasses:

- rival-territory destination policy;
- rival-capital policy;
- rival protected starter-zone policy;
- recommended-level policy;
- combat teleport restriction;
- dungeon/raid source-map restriction;
- successful normal TELEPORT cooldown.

Authorized test override does not bypass:

- curated destination ownership;
- destination enabled state;
- existence of the referenced `game_tele`;
- valid player/session requirements;
- already-teleporting protection;
- dead/ghost, Spirit of Redemption, and Feign Death protection;
- flight protection;
- transport protection;
- battleground/arena protection;
- 250 ms SEARCH admission throttle;
- 250 ms TELEPORT admission throttle;
- server-owned `game_tele` coordinates.

Runtime validation completed with normal account 473 / Peteorc:

- With Test Override disabled, `SEARCH_TEST 8340 stormwind` returned
  `TEST_OVERRIDE_DENIED`.
- With the switch enabled but an empty whitelist,
  `SEARCH_TEST 8341 stormwind` returned `TEST_OVERRIDE_DENIED`.
- With account 473 authorized, `SEARCH_TEST 8342 stormwind` returned Stormwind
  City while ordinary `SEARCH 8343 stormwind` returned no result.
- Ordinary `TELEPORT 8344 954` returned `RIVAL_CAPITAL_BLOCKED`.
- Authorized `TELEPORT_TEST 8345 954` teleported Peteorc to Stormwind.
- While dead/ghost, `TELEPORT_TEST 8346 954` returned `DEAD_OR_GHOST`.
- Malformed whitelist `473,bad` denied `SEARCH_TEST 8347 stormwind`.
- `TELEPORT_TEST 8349` followed one second later by ordinary `TELEPORT 8350`
  proved test teleport does not create normal cooldown state.
- Ordinary `TELEPORT 8351` followed one second later by
  `TELEPORT_TEST 8352` proved test mode bypasses an existing normal cooldown.
- Ordinary `TELEPORT 8353` followed one second later by ordinary
  `TELEPORT 8354` returned `TELEPORT_COOLDOWN`, proving normal cooldown remains
  intact.
- From Ragefire Chasm, ordinary `TELEPORT 8355` returned `IN_DUNGEON`, while
  authorized `TELEPORT_TEST 8356` succeeded.
- In combat, ordinary `TELEPORT 8360` returned `IN_COMBAT`, while authorized
  `TELEPORT_TEST 8361` succeeded.
- Back-to-back `SEARCH_TEST` requests produced `SEARCH_THROTTLED` on the second
  request.
- Back-to-back `TELEPORT_TEST` requests produced `TELEPORT_THROTTLED` on the
  second request.
- `TELEPORT_TEST 8366 999999` returned `DESTINATION_NOT_FOUND`.
- Malformed `TELEPORT_TEST` returned `TELEPORT_TEST_FORMAT`.
- Malformed `SEARCH_TEST` returned `SEARCH_TEST_FORMAT`.
- Live catalog contains 26 destinations, all 26 enabled and 0 disabled.
  Enabled-only test-search behavior is therefore source-validated; no disabled
  live runtime fixture currently exists.
- After validation, Test Override was restored to disabled with an empty
  whitelist, config reloaded successfully, and `SEARCH_TEST 8369 stormwind`
  returned `TEST_OVERRIDE_DENIED`.

Temporary RFC validation fixture:

- Peteorc was temporarily raised from level 1 to level 8 because RFC has a
  local minimum-level requirement of 8.
- After dungeon-source validation, Peteorc was restored to level 1 and his
  original 165 XP.
- Gate 358 live validation confirmed Peteorc at level 1, XP 165, alive,
  at Camp Narache.
- Later Test Override tests moved Peteorc again; the Gate 373 acceptance snapshot
  confirmed the persisted character remained level 1 with XP 165 while online.
- PETE remained account security level 0 throughout the validation.

Accepted Test Override source/build hashes:

- `GetUsThere.cpp`:
  `4732cf2f93e4f04d2d34b0cd3f643801b59fee63558ffe62ee175ef15e091d56`
- `GetUsThere.cpp.o`:
  `d6d3abcb8db297f5bbdf2dfc119de1e8b6492b0a2a9b86e6aa65831e16e1a95b`
- `libmodules.a`:
  `44f028862f08387b028a2b312d823e9a8ec7d5c8b28736ada31315672b22bb61`
- Build-tree, installed, and running worldserver:
  `f965aa3499093e90116dd38c2a5b21e32b1ca022c427f4bcb315d1c4d50c9467`
- Module `conf.dist` and installed live config:
  `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`

## Engineering Lessons

### Static-library rebuild safety

- Do not run the generated `libmodules.a` link command directly against an existing archive.
- The generated archive command uses `ar qc`; running it against the existing archive can append duplicate object members.
- The proven safe rebuild sequence is to remove the target with `cmake_clean_target.cmake` and then run the generated `cmake_link_script`.
- After rebuilding, verify total member count, unique member count, exact `GetUsThere.cpp.o` member count, and the embedded object SHA256.

### Targeted object compilation

- Top-level `make -n` and `make -q` did not reliably expose whether the Get Us There object needed rebuilding.
- The generated module `build.make` is the authoritative targeted path for compiling only `GetUsThere.cpp.o`.
- Use a dry run against that generated rule before executing the targeted compile.

### Live teleport-state testing

- A far world transfer is not a reliable way to live-test addon handling of `AlreadyTeleporting`.
- During the far-transfer window the player is temporarily not in-world, and logged-in chat/addon packets can be discarded before reaching the module.
- Do not interpret the absence of an addon response during that window as proof that the module accepted or rejected the request.
- `AlreadyTeleporting` therefore remains source-verified but not deterministically live-validated.

### Client command length

- Long `/run` Lua commands can be truncated by the WoW client and produce misleading end-of-input syntax errors.
- Prefer short helper definitions followed by separate short execution commands for timing-sensitive client tests.



### Safe arrival is not PvP protection

- A curated safe arrival point is intended to avoid immediate NPC, creature,
  guard, or environmental danger when practical.
- It does not make the player immune to enemy players on a PvP realm.
- Runtime validation should therefore distinguish passive NPC/environment
  safety from later player-versus-player deaths.

## Coordinate Display and Raw-Coordinate Test Mode Acceptance — 2026-09-17

Server-side coordinate display and authorized raw-coordinate test teleport
support are accepted after build, install, restart, and live runtime validation.

Protocol additions and extensions:

- Ordinary and Test Override SEARCH `RESULT` payloads now append authoritative
  AzerothCore `game_tele` values:
  - `mapId`
  - `x`
  - `y`
  - `z`
- Existing RESULT field positions before those appended coordinate fields remain
  unchanged.
- New authorized raw-coordinate protocol:
  `TELEPORT_COORD_TEST <requestId> <mapId> <x> <y> <z>`.
- Successful raw-coordinate response:
  `COORD_TELEPORTED <requestId> <mapId> OK`.
- Raw-coordinate errors retain request/map context when parsing succeeded.
- Malformed raw-coordinate framing returns
  `TELEPORT_COORD_TEST_FORMAT`.

Raw-coordinate parser and execution behavior:

- Request ID and map ID require complete unsigned integer parsing.
- X/Y/Z require complete finite floating-point parsing.
- Trailing numeric junk is rejected rather than partially consumed.
- The existing 255-byte addon payload limit remains enforced.
- Raw-coordinate requests retain the existing 250 ms TELEPORT admission
  throttle.
- Test Override authorization remains mandatory before raw-coordinate execution.
- Map/coordinate validity is checked with AzerothCore map-coordinate validation.
- Current player orientation is preserved; the client does not supply
  orientation.
- Raw-coordinate execution uses `TELE_TO_GM_MODE`.
- Retained Test Override safety checks still apply.
- Successful raw-coordinate teleport does not create ordinary TELEPORT cooldown
  state.
- Ordinary `TELEPORT` and `TELEPORT_TEST` continue to use only server-owned
  curated `game_tele` coordinates.

Runtime validation completed:

- Ordinary Stormwind SEARCH returned one RESULT and appended authoritative
  coordinates:
  - gameTeleId `954`
  - map `0`
  - X `-8833.379883`
  - Y `628.627991`
  - Z `94.006599`
- With Test Override disabled, `TELEPORT_COORD_TEST` returned
  `TEST_OVERRIDE_DENIED`.
- Runtime Test Override validation used authenticated account `101`
  (`Rubberbean`, GUID `1001`) only.
- Test Override was enabled temporarily through the live module config and
  activated with `reload config`; no worldserver restart was required because
  these config-cache values are reloadable.
- Authorized `SEARCH_TEST` returned coordinate-bearing Stormwind results.
- Authorized raw teleport to the Stormwind coordinates succeeded.
- Invalid map `999999` was rejected with `INVALID_MAP_OR_COORDS`.
- A coordinate containing trailing text (`-8833.38junk`) was rejected with
  `TELEPORT_COORD_TEST_FORMAT`.
- A nearby coordinate not equal to the curated Stormwind `game_tele` point
  teleported successfully and visibly displaced the character, proving the raw
  path uses supplied coordinates rather than silently resolving gameTeleId
  `954`.
- A successful raw teleport followed approximately 0.6 seconds later by
  ordinary `TELEPORT 954` succeeded, proving raw success does not poison the
  ordinary 5-second teleport cooldown.
- Authorized raw-coordinate teleport from inside The Stockade succeeded despite
  the live ordinary dungeon-origin restriction.
- Ordinary `TELEPORT 954` from inside The Stockade remained blocked with
  `IN_DUNGEON`.
- Authorized `TELEPORT_TEST 954` from inside The Stockade succeeded and used the
  curated server-owned destination.
- Alliance ordinary SEARCH for Orgrimmar returned zero results, while authorized
  `SEARCH_TEST` returned the enabled curated Orgrimmar destination
  (gameTeleId `703`) with authoritative coordinates.
- Test Override was restored to safe defaults, reloaded into the running
  worldserver, and runtime revalidation again returned
  `TEST_OVERRIDE_DENIED`.

Accepted coordinate/raw build state:

- `GetUsThere.cpp` SHA256:
  `88bc71d0d77f635ab5450f8cf5740495a91e7d5d1d7bc1e13e6ab95f851090e9`
- `GetUsThere.cpp.o` SHA256:
  `939b25f66b97c4be06337a1920d083e5a949dcd93b772eac3c772084e9360b5c`
- `libmodules.a` SHA256:
  `088364b21f306bb87d79b4e25a41fc30728e1e42d69be57bbe952bb40e57cc39`
- Build-tree, installed, and running worldserver SHA256:
  `f5ecee1bf5b9a1802e38279916c67368959b789b9f36f4ea13cfb6fe2100b4a4`
- Safe accepted live config SHA256:
  `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`
- Accepted live safe state:
  - `GetUsThere.TestOverride.Enable = 0`
  - `GetUsThere.TestOverride.AllowedAccountIds = ""`
- Accepted running worldserver at final validation:
  - PID `25374`
  - tmux pane `%5`
  - executable `/root/azerothcore-wotlk/env/dist/bin/worldserver`

Coordinate/raw rollback anchors:

- Source:
  `/root/GetUsThere.cpp-pre-coordinate-raw-promotion-20260917`
  - SHA256:
    `4732cf2f93e4f04d2d34b0cd3f643801b59fee63558ffe62ee175ef15e091d56`
- Object:
  `/root/GetUsThere.cpp.o-pre-coordinate-raw-compile-20260917`
  - SHA256:
    `d6d3abcb8db297f5bbdf2dfc119de1e8b6492b0a2a9b86e6aa65831e16e1a95b`
- Module archive:
  `/root/libmodules.a-pre-coordinate-raw-archive-20260917`
  - SHA256:
    `44f028862f08387b028a2b312d823e9a8ec7d5c8b28736ada31315672b22bb61`
- Build-tree worldserver:
  `/root/worldserver-build-pre-coordinate-raw-link-20260917`
  - SHA256:
    `f965aa3499093e90116dd38c2a5b21e32b1ca022c427f4bcb315d1c4d50c9467`
- Installed worldserver:
  `/root/worldserver-installed-pre-coordinate-raw-20260917`
  - SHA256:
    `f965aa3499093e90116dd38c2a5b21e32b1ca022c427f4bcb315d1c4d50c9467`
- Safe config used before temporary account-101 validation:
  `/root/mod_get_us_there.conf-pre-testoverride-account101-20260917`
  - SHA256:
    `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`

## Rollback Anchors

### Pre-TELEPORT-throttle rollback set — verified 2026-09-16

- Source: `/root/GetUsThere.cpp-pre-teleport-throttle-20260916-175314`
  - SHA256: `e4284e87fe9ba99a0ad88531a54a609634a1972c2284e821a53741aa4444deff`
- Object: `/root/GetUsThere.cpp.o-pre-teleport-throttle-20260916-175802`
  - SHA256: `6ea568e6709af918a2fbaed00562154cb473b02667e93c5f4ef9c77f9c272d6c`
- Archive: `/root/libmodules.a-pre-teleport-throttle-20260916-175924`
  - SHA256: `808dd577617f71303210563a0ae8fcc345cc2826fadb02be00dda5262ca95be3`
- Build-tree worldserver: `/root/worldserver-build-pre-teleport-throttle-20260916-180245`
  - SHA256: `2ec158d7c65f3bef8bedf10d6df8e0dafdfc22ec29395a75c30cb6e95a6b15fc`
- Installed worldserver: `/root/worldserver-installed-pre-teleport-throttle-20260916-180653`
  - SHA256: `2ec158d7c65f3bef8bedf10d6df8e0dafdfc22ec29395a75c30cb6e95a6b15fc`


### Pre-safe-arrival data rollback set — verified 2026-09-17

- Pre-safe `game_tele` dump:
  `/root/game_tele-pre-get-us-there-safe-arrivals-20260917.sql`
  - SHA256: `33a27296f61f9c843ec89e9d9a32ec0f9a649e6e9bcbf3dda1058aa46bbd4585`
- Pre-safe live Get Us There catalog:
  `/root/GetUsThere-live-catalog-pre-safe-arrivals-20260917.sql`
  - SHA256: `0f9996db76e78f7c288dd5d81af93a68712a8ad8a8244283b334d8ba78c577a5`
- Pre-safe seed draft:
  `/root/GetUsThere-initial-catalog-seed-draft-pre-safe-arrivals-20260917.sql`
  - SHA256: `fe98736bb925df3cdaa841df910e1b8beb5854837daed479aa52574bcd5ece26`
- Pre-safe install candidate:
  `/root/GetUsThere-world-install-candidate-pre-safe-arrivals-20260917.sql`
  - SHA256: `2eb93cc9d0a2d2b4db98fb1d2e65b71f3671db77a5af571babc6747c532053b5`
- Pre-leveling/safe-arrival EngineeringLog:
  `/root/EngineeringLog-pre-leveling-safe-arrivals-20260917.md`
  - SHA256: `a716f8a06fabf52f9b2976b354a064cccc46479e0ff45afb290606e8cd80b925`

### Pre-Test-Override rollback set — verified 2026-09-17

- Source:
  `/root/GetUsThere.cpp-pre-test-override-r2-promotion-20260917`
  - SHA256:
    `096ec46d338f3218b95a7010b1c875e757e56719e831e4535b134d77a35b185c`
- Module config distribution:
  `/root/mod_get_us_there.conf.dist-pre-test-override-r2-promotion-20260917`
  - SHA256:
    `56d0a94c51afe968bf834b8d7b1ab69053b4c4af9d19c5649da10736160c0bc6`
- GetUsThere object:
  `/root/GetUsThere.cpp.o-pre-test-override-r2-compile-20260917`
  - SHA256:
    `3dec4e56185c56f134ab6b0a81d6e5f005db4a9681e6208fff63c1ee402adbe6`
- Module archive:
  `/root/libmodules.a-pre-test-override-r2-archive-20260917`
  - SHA256:
    `01eee988669949b3ebf79d81919a49c94f585db0509da5fec4af81b560b5efc8`
- Build-tree worldserver:
  `/root/worldserver-build-pre-test-override-r2-link-20260917`
  - SHA256:
    `d22c2406e0dbfcb5e10dd6dd2ff53d59b87592fa58c68db4d6d5cae5fe6c8f12`
- Installed worldserver:
  `/root/worldserver-installed-pre-test-override-r2-20260917`
  - SHA256:
    `d22c2406e0dbfcb5e10dd6dd2ff53d59b87592fa58c68db4d6d5cae5fe6c8f12`
- Pre-Test-Override live config:
  `/root/mod_get_us_there.conf-live-pre-test-override-r2-20260917`
  - SHA256:
    `56d0a94c51afe968bf834b8d7b1ab69053b4c4af9d19c5649da10736160c0bc6`
- Pre-Test-Override acceptance Engineering Log:
  `/root/EngineeringLog-pre-test-override-acceptance-20260917.md`
  - SHA256:
    `d0c589de2262602f716d0ec114f302d91c9e781bfe6b8e224d0d7e864aad6e3b`

Additional validation-state config anchors:

- Before enabling Test Override:
  `/root/mod_get_us_there.conf-pre-test-override-enable-only-20260917`
  - SHA256:
    `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`
- Before adding account 473 to the whitelist:
  `/root/mod_get_us_there.conf-pre-test-override-whitelist-473-20260917`
  - SHA256:
    `9f9864c4f77bc7cb5f5f39e7915c47f471dafdb0c57bf381a45fd6f036279790`
- Before malformed-whitelist validation:
  `/root/mod_get_us_there.conf-pre-malformed-whitelist-test-20260917`
  - SHA256:
    `722f87670c57689e3b0f09f39b8c8a16dece9a6d21360bcbaf3581239c5dfec1`
- Final active-validation config before safe disable:
  `/root/mod_get_us_there.conf-pre-test-override-disable-after-validation-20260917`
  - SHA256:
    `722f87670c57689e3b0f09f39b8c8a16dece9a6d21360bcbaf3581239c5dfec1`

## Non-Live Client Addon Candidate Milestone — 2026-09-17

A module-side WoW 3.3.5a addon distribution candidate now exists at:

`client/GetUsThere/`

Candidate files:

- `client/GetUsThere/GetUsThere.toc`
  - SHA256:
    `565b947821e73a32425ffdb0311dfe4e34fa4aade83d3e3912ce2f88fe7a5b29`
- `client/GetUsThere/GetUsThere.lua`
  - SHA256:
    `e45e8f0f28af574c0d67b5bd505ce0db49881261f3d1c877063be915e76defb8`

Distribution-layout decision:

- Client files are deliberately stored under `client/GetUsThere/`.
- Client addon files are not stored under `apps/`; that directory remains CI
  infrastructure.
- The inner `GetUsThere` directory is intended to be self-contained for later
  client-side installation.
- No addon files have yet been installed into the WoW client.

Manifest state:

- WoW interface version: `30300`.
- Public addon title: `Get Us There`.
- Candidate version: `0.1.0-candidate`.
- `GetUsThere.lua` is the only Lua file loaded by the manifest.

Frozen GUI behavior implemented in the candidate:

- Destination search field.
- Explicit `Send Us` button.
- Search Results dropdown for explicit selection when multiple curated results
  are returned.
- One-result searches may select that sole result automatically.
- Selected destination displays authoritative server-returned World Coordinates:
  Map, X, Y, and Z.
- Coordinate display uses two decimal places.
- No orientation/facing field is exposed.
- Override checkbox label is exactly:
  `Screw you! I'll go wherever I want, whenever I want`
- Override mode reveals a separate Raw Coordinates section with Map, X, Y, and
  Z inputs.
- Raw warning text is exactly:
  `Raw coordinates bypass curated safe destinations.`
- Raw action button is exactly:
  `Send Us Exactly Here`
- Pressing Enter in the search box performs search only and never teleports.

Implemented addon/server protocol paths:

- Normal search:
  `SEARCH <requestId> <query>`
- Authorized override search:
  `SEARCH_TEST <requestId> <query>`
- Normal curated teleport:
  `TELEPORT <requestId> <gameTeleId>`
- Authorized override curated teleport:
  `TELEPORT_TEST <requestId> <gameTeleId>`
- Authorized raw-coordinate teleport:
  `TELEPORT_COORD_TEST <requestId> <mapId> <x> <y> <z>`

Transport behavior:

- Uses addon prefix `GetUsThere`.
- Uses private self-WHISPER addon transport.
- Outbound destination is `UnitName("player")`.
- Inbound addon responses require prefix `GetUsThere` and sender equal to the
  local player.
- Search RESULT/DONE responses are correlated to the pending search request ID.
- Curated TELEPORTED/ERROR responses are correlated by request ID and
  gameTeleId.
- Raw COORD_TELEPORTED/ERROR responses are correlated by request ID and map ID.
- The raw button is enabled only when override mode is checked and Map/X/Y/Z
  contain locally parseable finite numeric values.
- Server-side validation and authorization remain authoritative.

Non-live candidate audit:

- Required frozen GUI strings are present.
- Exactly three outbound `SendAddonMessage` call sites exist:
  search, curated teleport, and raw-coordinate teleport.
- Enter remains bound only to search.
- No orientation/facing request exists.
- No `.toc`, `.lua`, or `.xml` addon files exist under `apps/`.
- Safe live Test Override state remained:
  - `GetUsThere.TestOverride.Enable = 0`
  - `GetUsThere.TestOverride.AllowedAccountIds = ""`
- Server source and live config were not modified by addon implementation.
- Git staging, commit, and push remain unperformed.

Validation limitation:

- No Lua interpreter/compiler (`lua`, `lua5.1`, `luac`, or `luac5.1`) was
  available on the Debian VM for an independent syntax compile check.
- The candidate has therefore completed static source/protocol auditing only.
- WoW-client installation and actual 3.3.5a runtime validation remain pending.

Primary addon rollback anchors created during implementation include:

- `/root/GetUsThere.lua-pre-protocol-20260917`
- `/root/GetUsThere.lua-pre-receiver-20260917`
- `/root/GetUsThere.lua-pre-search-wiring-20260917`
- `/root/GetUsThere.lua-pre-result-selection-20260917`
- `/root/GetUsThere.lua-pre-curated-teleport-20260917`
- `/root/GetUsThere.lua-pre-raw-fields-20260917`
- `/root/GetUsThere.lua-pre-raw-validation-20260917`
- `/root/GetUsThere.lua-pre-raw-teleport-20260917`

## WoW Client Addon Runtime Acceptance — 2026-09-17

The `GetUsThere` WoW 3.3.5a addon candidate was installed and exercised
through the real client.

Installed client location:

`D:\wow\interface\addons\GetUsThere`

Installed client files remained byte-identical to the accepted module-side
candidate after runtime testing:

- `GetUsThere.toc`
  - SHA256:
    `565b947821e73a32425ffdb0311dfe4e34fa4aade83d3e3912ce2f88fe7a5b29`
- `GetUsThere.lua`
  - SHA256:
    `e45e8f0f28af574c0d67b5bd505ce0db49881261f3d1c877063be915e76defb8`
- Installed file count: 2.

Client discovery and load validation:

- WoW discovered `Get Us There` in the AddOns list.
- The addon was enabled without an out-of-date, dependency, or conflict
  indication.
- `/gut` opened the addon window successfully.
- BugGrabber reported no Lua errors during the validated test sequence.

Normal-mode GUI validation:

- Destination search box rendered.
- Search Results dropdown rendered.
- `Send Us` rendered disabled until a server-returned destination was selected.
- World Coordinates displayed Map/X/Y/Z.
- Override checkbox rendered with the frozen exact label.
- Raw Coordinates remained hidden while override mode was unchecked.

Override-mode GUI validation:

- Checking the override box revealed the Raw Coordinates section.
- Warning text, Map/X/Y/Z fields, and `Send Us Exactly Here` rendered correctly.
- Valid numeric Map/X/Y/Z values enabled the raw button.
- Invalid coordinate text (`abc`) disabled the raw button.

Multi-result dropdown runtime validation:

- Searching for `a` with override disabled returned 15 server-approved
  destinations.
- The Search Results dropdown expanded and displayed multiple destinations
  across several server-returned categories.
- Before selection, `Send Us` remained disabled.
- Selecting `Stormwind City` from the dropdown populated:
  - Map `0`
  - X `-8833.38`
  - Y `628.63`
  - Z `94.01`
- Selecting the result enabled `Send Us`.
- Selecting the result did not teleport Rubberbean.
- BugGrabber remained clear.

Normal SEARCH runtime validation:

- Searching `Stormwind` with override disabled returned the server-owned
  Stormwind destination.
- Displayed coordinates were:
  - Map `0`
  - X `-8833.38`
  - Y `628.63`
  - Z `94.01`
- Pressing Enter performed search only and did not teleport the player.
- `Send Us` became enabled only after destination selection.
- BugGrabber remained clear.

Normal TELEPORT runtime validation:

- Clicking `Send Us` for the selected Stormwind destination teleported
  Rubberbean successfully.
- `Send Us` recovered after the server response.
- BugGrabber remained clear.

Fail-closed override validation:

- With server Test Override disabled, override-mode Stormwind search returned:
  `TEST_OVERRIDE_DENIED`.
- The GUI showed `Search failed` and
  `Server error: TEST_OVERRIDE_DENIED`.
- No destination remained selected and `Send Us` remained disabled.
- Rubberbean did not move.
- Raw-coordinate request with server Test Override disabled also did not move
  Rubberbean.
- BugGrabber remained clear.

Positive override validation:

- Test Override was temporarily enabled only for authenticated account `101`.
- Live config was reloaded into the running worldserver.
- Override-mode `SEARCH_TEST Orgrimmar` returned:
  - destination `Orgrimmar`
  - category `Capital`
  - Map `1`
  - X `1629.85`
  - Y `-4373.64`
  - Z `31.56`
- SEARCH_TEST remained search-only and did not move Rubberbean.
- Clicking `Send Us` while override mode was active exercised
  `TELEPORT_TEST` and teleported Rubberbean successfully to Orgrimmar.
- The curated Send Us button recovered after the response.
- BugGrabber remained clear.

Raw-coordinate positive validation:

- Raw fields:
  - Map `0`
  - X `-8833.38`
  - Y `628.63`
  - Z `94.01`
- Clicking `Send Us Exactly Here` exercised `TELEPORT_COORD_TEST` and moved
  Rubberbean from Orgrimmar back to the supplied Stormwind-area coordinates.
- BugGrabber remained clear.
- The transient disabled visual state of the raw button was not reliably
  observable because the loading screen / rapid server response obscured it.
- Subsequent raw requests were possible, demonstrating that the button did
  recover after the prior raw response.
- A syntactically valid raw request using map `999999` did not move Rubberbean
  and produced no Lua error; the server therefore remained authoritative over
  final map/coordinate validity.

Safe-state restoration:

- Temporary GUI validation config used:
  - `GetUsThere.TestOverride.Enable = 1`
  - `GetUsThere.TestOverride.AllowedAccountIds = "101"`
- Safe config was restored from:
  `/root/mod_get_us_there.conf-pre-gui-override-test-20260917`
- Restored config SHA256:
  `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`
- Safe restored values:
  - `GetUsThere.TestOverride.Enable = 0`
  - `GetUsThere.TestOverride.AllowedAccountIds = ""`
- `reload config` completed successfully after restoration.
- Final real-addon `SEARCH_TEST Orgrimmar` again returned
  `TEST_OVERRIDE_DENIED`.
- Rubberbean did not move and BugGrabber remained clear.

The client runtime validation therefore preserves the project design rule:

**THE ADDON ASKS. THE SERVER DECIDES.**

Git staging, commit, and push remain unperformed.

## Current Accepted Runtime

As of 2026-09-17:

- Running, installed, and build-tree worldserver SHA256:
  `f5ecee1bf5b9a1802e38279916c67368959b789b9f36f4ea13cfb6fe2100b4a4`
- `GetUsThere.cpp` SHA256:
  `88bc71d0d77f635ab5450f8cf5740495a91e7d5d1d7bc1e13e6ab95f851090e9`
- `GetUsThere.cpp.o` SHA256:
  `939b25f66b97c4be06337a1920d083e5a949dcd93b772eac3c772084e9360b5c`
- `libmodules.a` SHA256:
  `088364b21f306bb87d79b4e25a41fc30728e1e42d69be57bbe952bb40e57cc39`
- Module `conf.dist` and installed live config SHA256:
  `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`

Accepted client addon state:

- Module-side client distribution:
  `client/GetUsThere/`
- Installed WoW client location:
  `D:\wow\interface\addons\GetUsThere`
- `GetUsThere.toc` SHA256:
  `565b947821e73a32425ffdb0311dfe4e34fa4aade83d3e3912ce2f88fe7a5b29`
- `GetUsThere.lua` SHA256:
  `e45e8f0f28af574c0d67b5bd505ce0db49881261f3d1c877063be915e76defb8`
- Installed client files were re-hashed after runtime testing and remained
  byte-identical to the module-side accepted candidate.
- WoW 3.3.5a discovered and loaded the addon successfully.
- `/gut` opened the GUI without BugGrabber errors.
- Normal SEARCH and TELEPORT were runtime-validated through the real GUI.
- SEARCH_TEST, TELEPORT_TEST, and TELEPORT_COORD_TEST were runtime-validated
  through the real GUI while Test Override was temporarily authorized for
  account `101`.
- Test Override was restored to safe defaults and reloaded afterward.
- Final real-addon SEARCH_TEST revalidation returned `TEST_OVERRIDE_DENIED`.
- Pressing Enter performs search only and does not teleport.
- Multi-result search and dropdown selection were runtime-validated with a
  15-result server response; selecting `Stormwind City` populated the
  authoritative coordinates and enabled `Send Us` without moving the player.
- The raw button's transient disabled visual state during a successful teleport
  was not directly observable through the loading screen, but subsequent raw
  requests confirmed response recovery.

Test Override accepted state:

- `GetUsThere.TestOverride.Enable = 0`
- `GetUsThere.TestOverride.AllowedAccountIds = ""`
- Test Override therefore fails closed in the accepted live configuration.
- Runtime revalidation after restoring safe defaults returned
  `TEST_OVERRIDE_DENIED`.
- Test authorization requires both the server enable switch and an authenticated
  account ID present in the server-side whitelist.
- Malformed whitelist content fails closed.
- Ordinary `SEARCH` and `TELEPORT` protocol behavior remains separate from
  `SEARCH_TEST` and `TELEPORT_TEST`.

Validated Test Override behavior:

- Authorized `SEARCH_TEST` can bypass ordinary faction/capital policy.
- Authorized `TELEPORT_TEST` can bypass ordinary destination policy, combat,
  dungeon-source restriction, and successful normal-teleport cooldown.
- A successful test teleport does not create normal TELEPORT cooldown state.
- Existing normal TELEPORT cooldown does not block authorized test teleport.
- Normal-to-normal TELEPORT cooldown remains enforced.
- SEARCH_TEST retains the 250 ms SEARCH admission throttle.
- TELEPORT_TEST retains the 250 ms TELEPORT admission throttle.
- Invalid uncurated destination IDs remain rejected.
- Malformed SEARCH_TEST and TELEPORT_TEST payloads remain rejected.
- Dead/ghost protection was runtime-validated under Test Override.
- Raid-source bypass and retained Spirit of Redemption, Feign Death, flight,
  transport, battleground/arena, already-teleporting, valid-player/session,
  enabled-destination, and server-owned-coordinate protections remain
  source-validated where no additional live fixture was exercised.
- Live catalog has 26 destinations, all 26 enabled; enabled-only Test Override
  search behavior is source-validated because no disabled live fixture exists.

Existing ordinary runtime protections remain accepted:

- TELEPORT request throttle: 250 ms per player.
- Successful TELEPORT cooldown: 5 seconds.
- Dungeon-origin teleports: blocked by live configuration and runtime-validated.
- Raid-origin teleports: blocked by live configuration.
- Pseudo-death protections for Spirit of Redemption and Feign Death remain
  present from the previously accepted implementation.
- Live destination catalog: 26 enabled destinations.
- Live alias catalog: 12 aliases.
- Protected racial starter areas: 8.
- Curated leveling zones: 8.
- Leveling-zone safe `game_tele` IDs: `1997` through `2004`.
- Destinations with nonzero recommended level metadata: 16.
- Starter-area faction protection remains live-validated for both factions.
- Rival protected starter areas remain filtered from ordinary SEARCH results.
- Recommended-level boundary remains live-validated with `MaxDeficit = 9`.
- All eight leveling-zone safe arrivals were runtime-validated against
  immediate NPC/creature aggro.
- Live catalog has 0 missing `game_tele` references.

Accepted data artifacts remain:

- Seed draft SHA256:
  `f29bf90dc1bfd117db5b8db9308ef76ab6fe9e696b05144a466a1b6e48f8e136`
- Install candidate SHA256:
  `e25283aaeaa0310045cdcc307d712e3aecf07c650b37cce20cb36131a322f1ea`
- Accepted live catalog snapshot SHA256:
  `aaacab3be3c9dd7972ff331f17cdc987762725e18b46ae8a5fab2617c567c623`
- Accepted safe `game_tele` snapshot SHA256:
  `5e2dd152abac34a4148b5fe4ff73bced31781eed3df01a3911e0776494c46dfe`

Validation account restoration:

- Peteorc was restored after RFC testing to level 1 with his original 165 XP.
- Gate 358 confirmed the restored live character state.
- Gate 373 confirmed the persisted level and XP remained 1 and 165.

- Git staging, commit, and push remain unperformed.

## 2026-09-18 — Release SQL packaging and existing-database adoption

Release packaging investigation established the AzerothCore module database-updater
path and safely promoted the accepted Get Us There installation SQL into that path.

Validated database/catalog state before promotion:

- Live `game_tele` rows owned by Get Us There matched the accepted SQL candidate:
  8 of 8.
- Live `mod_get_us_there_destination` rows matched the accepted SQL candidate:
  26 of 26.
- Live `mod_get_us_there_alias` rows matched the accepted SQL candidate:
  12 of 12.
- An initial alias comparison reported false because Python and MySQL collation
  ordering differed; corrected sorted/multiset comparison confirmed exact content
  equality.
- Live destination and alias table schemas matched the accepted SQL definitions,
  including columns, defaults, primary/index definitions, engine, collation, and
  comments.

AzerothCore updater behavior was verified from local source:

- `worldserver` passes `AC_MODULES_LIST` to `DatabaseLoader`.
- `mod-get-us-there` is present in the compiled `AC_MODULES_LIST`.
- Module world SQL is discovered under:
  `modules/<module>/data/sql/db-world/...`
- Module SQL files are tracked in the world database `updates` table using state
  `MODULE`.
- Tracking identity is based on SQL filename with stored SHA-1.
- If an existing tracking row has the same filename and matching SHA-1, the
  updater treats the SQL as already applied and does not execute the file.
- If the stored SHA-1 differs, the updater reapplies the changed SQL.

Accepted release SQL:

- Permanent updater filename:
  `get_us_there_2026_09_18_00.sql`
- Permanent module path:
  `data/sql/db-world/base/get_us_there_2026_09_18_00.sql`
- SHA256:
  `9743c0c062366943d0a77311c724220d2ebaf6ae03366187d90e5df7bea056a5`
- SHA1:
  `3D934D45BD3D5AF11FCC1D07701018067BE7B294`
- The SQL body from the first `CREATE TABLE` onward is byte-identical to the
  previously accepted installation candidate; only the development-only header
  comments were replaced with release installation wording.
- The existing development database already contained the exact accepted schema
  and data before updater adoption.

Existing-development-database adoption:

- The world database `updates` table had no pre-existing row for
  `get_us_there_2026_09_18_00.sql`.
- One adoption row was inserted:
  `get_us_there_2026_09_18_00.sql | 3D934D45BD3D5AF11FCC1D07701018067BE7B294 | MODULE | 0`
- This adoption row prevents replay of the already-installed seed data on this
  development database when the release SQL becomes visible to the updater.
- Fresh installations without that tracking row will receive the release SQL
  normally through AzerothCore's module database updater.
- The release SQL was then copied into its permanent module updater path and
  verified byte-identical to the staged release file.

Runtime updater note:

- Matching-file skip behavior is source-verified.
- A real worldserver startup with the newly promoted SQL file present has not yet
  been performed as part of this milestone; runtime confirmation therefore
  remains pending.

Git staging, commit, and push remain unperformed.

### Release SQL updater runtime validation completed

A controlled worldserver shutdown/startup was performed after the release SQL had
been placed in the module updater path and its matching MODULE tracking row had
been adopted into the existing development database.

Runtime result:

- The prior worldserver exited cleanly.
- A single replacement worldserver started successfully as PID `35233`.
- AzerothCore reached the World database updater during startup.
- The updater reported:
  `World database is up-to-date! Containing 799 new and 2202 archived updates.`
- No `Applying update` or `Reapplying update` entry appeared for
  `get_us_there_2026_09_18_00.sql`.
- After startup, Get Us There database state remained:
  - destinations: `26`
  - aliases: `12`
  - owned `game_tele` rows `1997` through `2004`: `8`
- The updater tracking row remained exactly:
  `get_us_there_2026_09_18_00.sql | 3D934D45BD3D5AF11FCC1D07701018067BE7B294 | MODULE | 0`
- The tracking-row timestamp remained `2026-09-18 06:31:32`, confirming the
  startup updater did not replace or reapply that row.
- Release SQL SHA256 remained:
  `9743c0c062366943d0a77311c724220d2ebaf6ae03366187d90e5df7bea056a5`
- Release SQL SHA1 remained:
  `3D934D45BD3D5AF11FCC1D07701018067BE7B294`

Therefore the existing-development-database adoption path is now both
source-verified and runtime-validated: the existing accepted data is not replayed
when the release SQL becomes updater-visible, while fresh databases without the
tracking row remain eligible to apply the release SQL normally.

Character-database missing-update warnings observed during the same startup were
outside the Get Us There world-database workstream and did not prevent the World
database updater from completing successfully.

Git staging, commit, and push remain unperformed.

## 2026-09-18 — Release cleanup and addon version promotion

Final release-preparation cleanup completed the following controlled items:

- The existing `apps/ci/ci-codestyle.sh` was inspected before any modification.
- Its SHA256 is:
  `3ca5ad904bac99a01722c731440fd0650de7e516f454795e2b5bf63f60852270`
- It was proven byte-for-byte identical to AzerothCore `skeleton-module`
  `master` commit `877c24d9e759c7d1cd1ab3ef2402e1693299aac1`.
- No codestyle-script modification was required.

Obsolete development SQL cleanup:

- `docs/sql/GetUsThere-world-install-candidate.sql` was removed after confirming
  that its executable SQL matched the permanent release SQL and that no module
  file referenced the obsolete candidate.
- Rollback copy:
  `/root/GetUsThere-world-install-candidate-pre-release-cleanup-20260918.sql`
- Rollback SHA256:
  `e25283aaeaa0310045cdcc307d712e3aecf07c650b37cce20cb36131a322f1ea`
- The permanent updater SQL remained unchanged at SHA256:
  `9743c0c062366943d0a77311c724220d2ebaf6ae03366187d90e5df7bea056a5`

Addon release version promotion:

- `client/GetUsThere/GetUsThere.toc` was promoted from
  `0.1.0-candidate` to release version `0.1.0`.
- Release TOC SHA256:
  `1a39507bffebe5ad526948d41b87b1bd4d4d6e9ea233989e998e84628a7ffcfa`
- Accepted Lua SHA256 remained unchanged:
  `e45e8f0f28af574c0d67b5bd505ce0db49881261f3d1c877063be915e76defb8`
- The installed Windows/WoW addon was normalized to the exact module-side TOC
  bytes and verified to match both release hashes.
- After `/reload`, WoW runtime metadata reported:
  `Get Us There version: 0.1.0`

Git staging, commit, and push remain unperformed.

### Final obsolete SQL design-draft cleanup

A final release-residue review identified two historical SQL design drafts under
`docs/sql/`:

- `GetUsThere-destination-schema-draft.sql`
- `GetUsThere-initial-catalog-seed-draft.sql`

Both files explicitly identified themselves as design drafts, were not active
AzerothCore database updates, and were superseded by the permanent release SQL:

`data/sql/db-world/base/get_us_there_2026_09_18_00.sql`

Verified rollback copies were preserved outside the module before removal:

- `/root/GetUsThere-destination-schema-draft-pre-release-cleanup-20260918.sql`
  SHA256:
  `e6b890b0642513ebfaa078010ba7b1746751749692bcbb262bd0e80221e17f0e`

- `/root/GetUsThere-initial-catalog-seed-draft-pre-release-cleanup-20260918.sql`
  SHA256:
  `f29bf90dc1bfd117db5b8db9308ef76ab6fe9e696b05144a466a1b6e48f8e136`

Both rollback copies were verified byte-for-byte against their module sources
before removal.

The permanent release SQL remained unchanged at SHA256:

`9743c0c062366943d0a77311c724220d2ebaf6ae03366187d90e5df7bea056a5`

Git staging, commit, and push remain unperformed.

## 2026-09-18 — Final codestyle and build validation

The official AzerothCore module codestyle script was run against the release
source.

Initial result:

- Codestyle failed only the multiple-blank-line rule.
- Exactly one offending run was found in `src/GetUsThere.cpp`, consisting of two
  consecutive blank lines before `IsGetUsThereTestOverrideAuthorized`.
- The pre-fix accepted source was preserved at:
  `/root/GetUsThere.cpp-pre-codestyle-blankline-fix-20260918`
- Pre-fix SHA256:
  `88bc71d0d77f635ab5450f8cf5740495a91e7d5d1d7bc1e13e6ab95f851090e9`

Correction:

- One excess blank line only was removed.
- No executable logic changed.
- Post-fix source SHA256:
  `510f2d936c08832b76d9ea8cb0bc550174d91d70818edcf184889ed31584da32`
- Official `apps/ci/ci-codestyle.sh` then completed successfully with:
  `Everything looks good`

Build validation:

- Existing build configuration:
  - `Release`
  - `Unix Makefiles`
  - `MODULES=static`
  - `SCRIPTS=static`
  - `WITH_WARNINGS=ON`
- `cmake --build ... --target modules -- -j2` completed successfully.
- `cmake --build ... --target worldserver -- -j2` completed successfully.
- Module archive SHA256:
  `088364b21f306bb87d79b4e25a41fc30728e1e42d69be57bbe952bb40e57cc39`
- The archive hash remained unchanged because the source change was
  whitespace-only.

Binary identity validation:

- Newly built worldserver SHA256:
  `f5ecee1bf5b9a1802e38279916c67368959b789b9f36f4ea13cfb6fe2100b4a4`
- Installed worldserver SHA256:
  `f5ecee1bf5b9a1802e38279916c67368959b789b9f36f4ea13cfb6fe2100b4a4`
- Running `/proc/35233/exe` SHA256:
  `f5ecee1bf5b9a1802e38279916c67368959b789b9f36f4ea13cfb6fe2100b4a4`
- Newly built and installed worldserver binaries were byte-for-byte identical.
- Therefore no installation or worldserver restart was required for the
  codestyle-only source cleanup.
- Running worldserver remained PID `35233`.

Git staging, commit, and push remain unperformed.

## 2026-09-18 — Final release package preflight

A final release-residue and package-layout audit was completed before creating
the distributable archive.

Validated release state:

- No backup, temporary, editor, candidate, or draft files remain in the
  distributable module tree.
- No active candidate/draft release markers remain outside historical
  EngineeringLog entries.
- The `.gitattributes` `TODO text` entry is a file-pattern rule and not an
  unresolved development TODO.
- The obsolete empty `docs/sql/` directory was removed after its final draft
  files had already been preserved externally and removed.
- Official module codestyle validation still passes with:
  `Everything looks good`
- Client addon version remains:
  `0.1.0`
- README installation paths match the actual release tree:
  - server module: `modules/mod-get-us-there`
  - module-side addon: `client/GetUsThere`
  - WoW client destination: `Interface/AddOns/GetUsThere`

Release-critical hashes at package preflight:

- `src/GetUsThere.cpp`
  `510f2d936c08832b76d9ea8cb0bc550174d91d70818edcf184889ed31584da32`
- `conf/mod_get_us_there.conf.dist`
  `a57ae5346a68b08d82901674fc8fd1f4fefacc0eff64fca13a101dff82d3947b`
- `data/sql/db-world/base/get_us_there_2026_09_18_00.sql`
  `9743c0c062366943d0a77311c724220d2ebaf6ae03366187d90e5df7bea056a5`
- `client/GetUsThere/GetUsThere.toc`
  `1a39507bffebe5ad526948d41b87b1bd4d4d6e9ea233989e998e84628a7ffcfa`
- `client/GetUsThere/GetUsThere.lua`
  `e45e8f0f28af574c0d67b5bd505ce0db49881261f3d1c877063be915e76defb8`
- `README.md`
  `679f35f2f28e90fad4248a3f0247826979c09a39a64eace43819bdbf97e5dedd`
- `apps/ci/ci-codestyle.sh`
  `3ca5ad904bac99a01722c731440fd0650de7e516f454795e2b5bf63f60852270`

Git staging, commit, and push remain unperformed.
