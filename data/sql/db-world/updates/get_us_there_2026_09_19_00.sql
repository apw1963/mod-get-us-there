-- Get Us There
-- Post-0.1.0 world database update
--
-- Add the validated Vault of Archavon arrival to the curated destination
-- catalog. The stock AzerothCore game_tele row remains authoritative for
-- coordinates.
--
-- Wintergrasp ownership is intentionally NOT stored as territory_faction.
-- Current ownership is dynamic battlefield state supplied by the server.

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
(
    1410,
    'Vault of Archavon',
    'Raid',
    0,
    80,
    0,
    0,
    1,
    1,
    710
);

INSERT INTO `mod_get_us_there_alias`
(
    `game_tele_id`,
    `alias`
)
VALUES
    (1410, 'Vault'),
    (1410, 'VoA'),
    (1410, 'Archavon');
