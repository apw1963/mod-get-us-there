-- Get Us There: initial Points of Interest catalog.
--
-- Synthetic game_tele 2048 uses the stock Dark Portal area-trigger landing
-- on the Azeroth side rather than stock game_tele 1036. Research found the
-- area-trigger landing has no creatures within 50 yards, while stock 1036
-- places faction-sensitive NPCs roughly 24-25 yards from arrival.

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
    (2048,-11877.700,-3204.490,-18.490,0.230000,0,'GetUsThereDarkPortalAzerothSafe');

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
    (2048,'Dark Portal - Azeroth', 'Point of Interest',0,55,0,0,1,1,5000),
    (458, 'Gurubashi Arena',       'Point of Interest',0,30,0,0,1,1,5010),
    (1037,'Dark Portal - Outland', 'Point of Interest',0,58,0,0,1,1,5020),
    (1210,'Throne of the Elements','Point of Interest',0,64,0,0,1,1,5030),
    (1572,'Sholazar Waygate',      'Point of Interest',0,77,0,0,1,1,5040),
    (1629,'Temple of Storms',      'Point of Interest',0,77,0,0,1,1,5050);

INSERT INTO `mod_get_us_there_alias`
(
    `game_tele_id`,
    `alias`
)
VALUES
    (2048,'Dark Portal'),
    (2048,'The Dark Portal'),
    (2048,'Dark Portal Azeroth'),
    (2048,'Blasted Lands Portal'),

    (1037,'Dark Portal'),
    (1037,'Dark Portal Outland'),
    (1037,'Stair of Destiny'),
    (1037,'The Stair of Destiny'),

    (458,'Gurubashi'),

    (1210,'Throne of Elements'),

    (1572,'Waygate'),
    (1572,'Sholazar Basin Waygate'),

    (1629,'Temple Storms'),
    (1629,'Storm Peaks Temple');
