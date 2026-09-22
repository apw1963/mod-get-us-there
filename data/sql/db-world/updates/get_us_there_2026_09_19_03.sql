-- Get Us There
-- Settlement expansion batch 3 world database update
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
    (7,   'Aerie Peak', 'Settlement', 1, 41, 0, 0, 1, 1, 870),
    (470, 'Hammerfall', 'Settlement', 2, 30, 0, 0, 1, 1, 880),
    (148, 'Booty Bay',  'Settlement', 0, 42, 0, 0, 1, 1, 890);
