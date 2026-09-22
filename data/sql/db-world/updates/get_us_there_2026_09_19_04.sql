-- Get Us There
-- Settlement expansion batch 4 world database update
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
    (615, 'Menethil Harbor', 'Settlement', 1, 20, 0, 0, 1, 1, 900),
    (939, 'Stonard',         'Settlement', 2, 37, 0, 0, 1, 1, 910),
    (345, 'Everlook',        'Settlement', 0, 55, 0, 0, 1, 1, 920);
