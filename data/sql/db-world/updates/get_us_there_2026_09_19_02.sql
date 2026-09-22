-- Get Us There
-- Settlement expansion batch 2 world database update
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
    (248, 'Darkshire',    'Settlement', 1, 25, 0, 0, 1, 1, 840),
    (983, 'Tarren Mill',  'Settlement', 2, 20, 0, 0, 1, 1, 850),
    (410, 'Gadgetzan',    'Settlement', 0, 40, 0, 0, 1, 1, 860);
