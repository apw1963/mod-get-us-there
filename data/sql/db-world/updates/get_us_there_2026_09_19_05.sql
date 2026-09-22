-- Get Us There
-- Settlement expansion batch 5 world database update
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
    (556, 'Lakeshire',           'Settlement', 1, 15, 0, 0, 1, 1, 930),
    (532, 'Kargath',             'Settlement', 2, 38, 0, 0, 1, 1, 940),
    (567, 'Light''s Hope Chapel','Settlement', 0, 58, 0, 0, 1, 1, 950);
