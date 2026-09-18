-- Get Us There
-- AzerothCore world database base installation
--
-- Installed through the AzerothCore module database updater.
--
-- game_tele remains authoritative for destination coordinates.
-- Get Us There stores only curated player-facing and policy metadata.
--
-- No FOREIGN KEY is intentionally created against game_tele.  The module
-- validates game_tele_id references at runtime and ignores/logs invalid ones.

CREATE TABLE IF NOT EXISTS `mod_get_us_there_destination` (
    `game_tele_id` int unsigned NOT NULL,
    `display_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    `category` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Other',
    `territory_faction` tinyint unsigned NOT NULL DEFAULT '0',
    `recommended_level` tinyint unsigned NOT NULL DEFAULT '0',
    `is_capital` tinyint unsigned NOT NULL DEFAULT '0',
    `is_protected_faction_zone` tinyint unsigned NOT NULL DEFAULT '0',
    `enabled` tinyint unsigned NOT NULL DEFAULT '1',
    `group_teleport_allowed` tinyint unsigned NOT NULL DEFAULT '1',
    `sort_order` smallint unsigned NOT NULL DEFAULT '0',
    PRIMARY KEY (`game_tele_id`),
    KEY `idx_mod_get_us_there_destination_enabled_sort`
        (`enabled`, `sort_order`, `display_name`),
    KEY `idx_mod_get_us_there_destination_category`
        (`category`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='GetUsThere curated destination metadata';

CREATE TABLE IF NOT EXISTS `mod_get_us_there_alias` (
    `game_tele_id` int unsigned NOT NULL,
    `alias` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
    PRIMARY KEY (`game_tele_id`, `alias`),
    KEY `idx_mod_get_us_there_alias_alias`
        (`alias`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='GetUsThere destination search aliases';

-- Get Us There-owned safe arrival points for curated leveling zones.
-- Plain INSERT is intentional: an ID collision must fail visibly rather than
-- silently overwrite or reuse a different teleport.
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
    (1997, -10546.9,  1197.24, 31.7263, 3.69015, 0,   'GetUsThereWestfallSafe'),
    (1998, -9403.25, -2037.69, 58.3687, 0,       0,   'GetUsThereRedridgeSafe'),
    (1999, -10839.2, -480.764, 42.4602, 0,       0,   'GetUsThereDuskwoodSafe'),
    (2000, -11542.6, -228.637, 27.8427, 0,       0,   'GetUsThereStranglethornSafe'),
    (2001, -8591.8,  -3629.76, 13.5564, 0,       1,   'GetUsThereTanarisSafe'),
    (2002, 700.091,   2207.99, 288.518, 0,       530, 'GetUsThereHellfireSafe'),
    (2003, 3041.21,   4314.9,  29.0761, 0,       571, 'GetUsThereBoreanSafe'),
    (2004, 3599.17,   2846.07, 70.9523, 0,       571, 'GetUsThereDragonblightSafe');

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
    (252,  'Darnassus',       'Capital',     1, 0, 1, 0, 1, 1, 110),
    (507,  'Ironforge',       'Capital',     1, 0, 1, 0, 1, 1, 120),
    (954,  'Stormwind City',  'Capital',     1, 0, 1, 0, 1, 1, 130),
    (1055, 'The Exodar',      'Capital',     1, 0, 1, 0, 1, 1, 140),

    (703,  'Orgrimmar',       'Capital',     2, 0, 1, 0, 1, 1, 210),
    (869,  'Silvermoon City', 'Capital',     2, 0, 1, 0, 1, 1, 220),
    (1212, 'Thunder Bluff',   'Capital',     2, 0, 1, 0, 1, 1, 230),
    (1263, 'Undercity',       'Capital',     2, 0, 1, 0, 1, 1, 240),

    (859,  'Shattrath City',  'Neutral Hub', 0, 0, 0, 0, 1, 1, 310),
    (1398, 'Dalaran',         'Neutral Hub', 0, 0, 0, 0, 1, 1, 320),

    (686,  'Northshire Valley', 'Starter Area', 1, 1, 0, 1, 1, 1, 410),
    (220,  'Coldridge Valley',  'Starter Area', 1, 1, 0, 1, 1, 1, 420),
    (837,  'Shadowglen',        'Starter Area', 1, 1, 0, 1, 1, 1, 430),
    (227,  'Crash Site',        'Starter Area', 1, 1, 0, 1, 1, 1, 440),

    (1278, 'Valley of Trials',  'Starter Area', 2, 1, 0, 1, 1, 1, 510),
    (188,  'Camp Narache',      'Starter Area', 2, 1, 0, 1, 1, 1, 520),
    (838,  'Shadow Grave',      'Starter Area', 2, 1, 0, 1, 1, 1, 530),
    (1168, 'The Sunspire',      'Starter Area', 2, 1, 0, 1, 1, 1, 540),

    (1997, 'Westfall',            'Leveling Zone', 1, 10, 0, 0, 1, 1, 610),
    (1998, 'Redridge Mountains',  'Leveling Zone', 0, 15, 0, 0, 1, 1, 620),
    (1999, 'Duskwood',            'Leveling Zone', 0, 20, 0, 0, 1, 1, 630),
    (2000, 'Stranglethorn Vale',  'Leveling Zone', 0, 30, 0, 0, 1, 1, 640),
    (2001, 'Tanaris',             'Leveling Zone', 0, 40, 0, 0, 1, 1, 650),
    (2002, 'Hellfire Peninsula',  'Leveling Zone', 0, 58, 0, 0, 1, 1, 660),
    (2003, 'Borean Tundra',       'Leveling Zone', 0, 68, 0, 0, 1, 1, 670),
    (2004, 'Dragonblight',        'Leveling Zone', 0, 71, 0, 0, 1, 1, 680);

INSERT INTO `mod_get_us_there_alias`
(
    `game_tele_id`,
    `alias`
)
VALUES
    (507,  'IF'),
    (703,  'Org'),
    (859,  'Shattrath'),
    (859,  'Shatt'),
    (869,  'Silvermoon'),
    (954,  'Stormwind'),
    (954,  'SW'),
    (1055, 'Exodar'),
    (1212, 'TB'),
    (1212, 'ThunderBluff'),
    (1263, 'UC'),
    (1398, 'Dal');
