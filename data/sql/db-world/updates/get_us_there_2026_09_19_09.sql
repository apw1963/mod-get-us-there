-- Get Us There
-- Skettis safe-arrival correction.
--
-- Live testing confirmed the stock AzerothCore Skettis teleport (game_tele 882)
-- lands at a good geographic location but can place the traveler directly into
-- hostile activity.
--
-- A player-validated outdoor ground location at Blackwind Landing is used as
-- the Get Us There safe arrival instead:
--
-- Map 530 (Outland)
-- Zone 3519 (Terokkar Forest)
-- Area 3973 (Blackwind Landing)
-- X -3361.9766
-- Y  3622.3125
-- Z   281.035
-- O     3.9436657
--
-- Stock game_tele ID 882 is intentionally left unchanged.
-- Get Us There owns ID 2005 following the existing project-safe teleport range.

INSERT INTO `game_tele`
(
    `id`,
    `position_x`,
    `position_y`,
    `position_z`,
    `orientation`,
    `map`,
    `name`
)
VALUES
(
    2005,
    -3361.9766,
    3622.3125,
    281.035,
    3.9436657,
    530,
    'GetUsThereSkettisSafe'
);

UPDATE `mod_get_us_there_destination`
SET `game_tele_id` = 2005
WHERE `game_tele_id` = 882
  AND `display_name` = 'Skettis'
  AND `category` = 'Settlement'
  AND `territory_faction` = 0
  AND `recommended_level` = 70
  AND `is_capital` = 0
  AND `is_protected_faction_zone` = 0
  AND `enabled` = 1
  AND `group_teleport_allowed` = 1
  AND `sort_order` = 1630;
