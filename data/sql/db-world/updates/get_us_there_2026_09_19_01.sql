-- Get Us There
-- Settlement pilot world database update
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
    (824,  'Sentinel Hill',  'Settlement', 1, 15, 0, 0, 1, 1, 810),
    (1029, 'The Crossroads', 'Settlement', 2, 15, 0, 0, 1, 1, 820),
    (732,  'Ratchet',        'Settlement', 0, 15, 0, 0, 1, 1, 830);
