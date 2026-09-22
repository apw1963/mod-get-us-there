-- Get Us There
-- Settlement expansion batch 11 world database update.
--
-- Adds 15 individually researched Settlement destinations.
-- Adds five Get Us There-owned safe game_tele rows: IDs 2006-2010.
-- Stock AzerothCore game_tele rows remain unchanged.
-- territory_faction: 0 = neutral, 1 = Alliance, 2 = Horde.
--
-- IMPORTANT:
-- Acherus: The Ebon Hold (game_tele 2006) requires the matching server-side
-- DEATH_KNIGHT_ONLY policy before this migration is applied to a live catalog.

INSERT INTO `game_tele`
(`id`,`position_x`,`position_y`,`position_z`,`orientation`,`map`,`name`)
VALUES
(2006,2352.370,-5666.910,382.240,0.645772,0,'GetUsThereAcherusSafe'),
(2007,6402.060,467.860,511.290,1.23918,571,'GetUsThereCrusadersPinnacleSafe'),
(2008,8472.460,-335.950,906.480,2.87979,571,'GetUsThereBouldercragsRefugeSafe'),
(2009,7427.320,4224.160,314.110,4.34587,571,'GetUsThereDeathsRiseSafe'),
(2010,2792.450,908.960,22.330,1.64061,571,'GetUsThereMoakiHarborSafe');

INSERT INTO `mod_get_us_there_destination`
(`game_tele_id`,`display_name`,`category`,`territory_faction`,`recommended_level`,
 `is_capital`,`is_protected_faction_zone`,`enabled`,`group_teleport_allowed`,`sort_order`)
VALUES
(449,'Grom''gol Base Camp','Settlement',2,35,0,0,1,1,1960),
(2006,'Acherus: The Ebon Hold','Settlement',0,55,0,0,1,1,1970),
(917,'Spinebreaker Post','Settlement',2,58,0,0,1,1,1980),
(1506,'Amber Ledge','Settlement',0,70,0,0,1,1,1990),
(855,'Shattered Sun Staging Area','Settlement',0,70,0,0,1,1,2000),
(1381,'Valgarde','Settlement',1,70,0,0,1,1,2010),
(2010,'Moa''ki Harbor','Settlement',0,71,0,0,1,1,2020),
(1547,'Transitus Shield','Settlement',0,71,0,0,1,1,2030),
(1812,'Kor''kron Vanguard','Settlement',2,72,0,0,1,1,2040),
(1778,'Westfall Brigade Encampment','Settlement',1,74,0,0,1,1,2050),
(2008,'Bouldercrag''s Refuge','Settlement',0,78,0,0,1,1,2060),
(1771,'Grom''arsh Crash-Site','Settlement',2,78,0,0,1,1,2070),
(1414,'Argent Tournament Grounds','Settlement',0,80,0,0,1,1,2080),
(2007,'Crusaders'' Pinnacle','Settlement',0,80,0,0,1,1,2090),
(2009,'Death''s Rise','Settlement',0,80,0,0,1,1,2100);
