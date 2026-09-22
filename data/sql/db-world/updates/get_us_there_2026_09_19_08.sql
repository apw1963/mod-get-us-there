-- Get Us There
-- Settlement expansion batch 8 world database update
--
-- Distance-outlier Settlement candidates individually reviewed against
-- taxi evidence, AreaTable context, and all related stock game_tele rows.
--
-- Gundrak and Ulduar are intentionally excluded from Settlement because
-- local data identifies them as dungeon/raid complexes rather than
-- ordinary settlement/travel hubs.
--
-- Stock AzerothCore game_tele rows remain authoritative for coordinates.
-- territory_faction: 0 = neutral, 1 = Alliance, 2 = Horde.

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
    (694,  'Ogri''La',          'Settlement', 0, 66, 0, 0, 1, 1, 1620),
    (882,  'Skettis',           'Settlement', 0, 70, 0, 0, 1, 1, 1630),
    (1391, 'Warsong Hold',      'Settlement', 2, 70, 0, 0, 1, 1, 1640),
    (1838, 'Wyrmrest Temple',   'Settlement', 0, 73, 0, 0, 1, 1, 1650),
    (1695, 'The Argent Stand',  'Settlement', 0, 75, 0, 0, 1, 1, 1660);
