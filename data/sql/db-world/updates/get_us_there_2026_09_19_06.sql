-- Get Us There
-- Settlement expansion batch 6 world database update
--
-- Stock AzerothCore game_tele rows remain authoritative for coordinates.
-- territory_faction: 0 = neutral, 1 = Alliance, 2 = Horde.
--
-- Feathermoon Stronghold and Revantusk Village have ExplorationLevel=0
-- in AreaTable. Their recommended levels use direct local quest evidence:
-- Feathermoon Stronghold -> dominant MinLevel 40.
-- Revantusk Village     -> dominant MinLevel 44.

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
    (913,  'Southshore',             'Settlement', 1, 22, 0, 0, 1, 1,  960),
    (190,  'Camp Taurajo',           'Settlement', 2, 10, 0, 0, 1, 1,  970),
    (200,  'Cenarion Hold',          'Settlement', 0, 55, 0, 0, 1, 1,  980),
    (763,  'Revantusk Village',      'Settlement', 2, 44, 0, 0, 1, 1,  990),
    (1145, 'The Sepulcher',          'Settlement', 2, 10, 0, 0, 1, 1, 1000),
    (58,   'Astranaar',              'Settlement', 1, 20, 0, 0, 1, 1, 1010),
    (60,   'Auberdine',              'Settlement', 1, 12, 0, 0, 1, 1, 1020),
    (372,  'Feathermoon Stronghold', 'Settlement', 1, 40, 0, 0, 1, 1, 1030),
    (401,  'Freewind Post',          'Settlement', 2, 26, 0, 0, 1, 1, 1040),
    (676,  'Nijel''s Point',         'Settlement', 1, 30, 0, 0, 1, 1, 1050);
