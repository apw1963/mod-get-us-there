-- Get Us There: initial World Boss catalog.
--
-- Arrival points were researched against the local AzerothCore world data
-- and field-tested in game before this migration was created.
--
-- Four stock game_tele rows are currently unowned by Get Us There and can be
-- used directly:
--   518 JademirLake     -> Emeriss
--   552 LakeMennar      -> Azuregos
--   851 ShaolWatha      -> Lethon
--   907 SouthfuryRiver  -> Ysondre
--
-- Taerar and Doom Lord Kazzak use dedicated copies of already accepted
-- Get Us There leveling-zone safe arrivals because game_tele_id is the
-- primary key of mod_get_us_there_destination and those existing rows are
-- already owned by Duskwood and Hellfire Peninsula.
--
-- Doomwalker uses a dedicated field-selected Netherwing Pass arrival.

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
    (2049,-10839.200195,-480.764008,42.460201,0.0000000,0,  'GetUsThereTaerarSafe'),
    (2050,   700.091003,2207.989990,288.518005,0.0000000,530,'GetUsThereKazzakSafe'),
    (2051, -4284.302200, 791.409200,24.135454,2.4528096,530,'GetUsThereDoomwalkerSafe');

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
    (552, 'Azuregos',          'World Boss',0,60,0,0,1,1,6000),
    (2050,'Doom Lord Kazzak',  'World Boss',0,70,0,0,1,1,6010),
    (2051,'Doomwalker',        'World Boss',0,70,0,0,1,1,6020),
    (518, 'Emeriss',           'World Boss',0,60,0,0,1,1,6030),
    (851, 'Lethon',            'World Boss',0,60,0,0,1,1,6040),
    (2049,'Taerar',            'World Boss',0,60,0,0,1,1,6050),
    (907, 'Ysondre',           'World Boss',0,60,0,0,1,1,6060);

INSERT INTO `mod_get_us_there_alias`
(
    `game_tele_id`,
    `alias`
)
VALUES
    (2050,'Kazzak'),
    (2050,'Lord Kazzak'),
    (2051,'Doom Walker');
