//
//  AppDelegate.m
//  Shadowdrome
//
//  Created by John Calhoun on 3/7/24.
//

#import "AppDelegate.h"
#include "BitmapContext.h"
#include "Lamp.h"
#include "Obstacle.h"
#include "ShadowContext.h"
#include "ShadowContextJSONLayer.h"


@interface AppDelegate ()
@property (strong) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSImageView *shadowImageView;
@property (strong) NSString *contextJSON;
@end

@implementation AppDelegate

BMContext *bitmap;
SDContext *shadowContext;

- (void) test0 {
	shadowContext = sdContextCreate ("Test", 1024, 2048);
	shadowContext->tempScalar = 200000;
	
	sdContextAddLamp (shadowContext, lampCreate (450, 990));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (550, 1010, 10));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (380, 800, 400, 1200), 0.5));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (330, 800, 350, 950));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (330, 1050, 350, 1200), 0.5));
}

- (void) addKingOfDiamondsLightsAndObstacles {
	shadowContext = sdContextCreate ("King of Diamonds", 1024, 2048);
	shadowContext->tempScalar = 40000;
	
	sdContextAddLamp (shadowContext, lampCreate (432, 215));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (432, 240, 8));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (381, 240, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (481, 240, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (432, 132, 8));
	
	sdContextAddLamp (shadowContext, lampCreate (84, 387));
	sdContextAddLamp (shadowContext, lampCreate (183, 380));
	sdContextAddLamp (shadowContext, lampCreate (285, 390));
	sdContextAddLamp (shadowContext, lampCreate (59, 490));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (86, 318, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (83, 417, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (184, 312, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (184, 409, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (285, 322, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (285, 420, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (96, 454, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (76, 500, 8));

	sdContextAddLamp (shadowContext, lampCreate (579, 391));
	sdContextAddLamp (shadowContext, lampCreate (680, 379));
	sdContextAddLamp (shadowContext, lampCreate (777, 391));
	sdContextAddLamp (shadowContext, lampCreate (805, 489));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (578, 322, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (578, 420, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (680, 311, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (680, 409, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (776, 319, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (778, 420, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (767, 456, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (787, 501, 8));
	
	// Bumpers
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (200, 572, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (430, 422, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (671, 574, 40));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 546, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 778, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 811, 8));
	sdContextAddLamp (shadowContext, lampCreate (52, 730));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 543, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (818, 779, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (819, 816, 8));
	sdContextAddLamp (shadowContext, lampCreate (811, 731));
	
	sdContextAddLamp (shadowContext, lampCreate (356, 751));
	sdContextAddLamp (shadowContext, lampCreate (509, 753));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (287, 900, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (260, 757, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (286, 735, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (431, 626, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (431, 585, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (576, 732, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (602, 757, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (575, 900, 8));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (339, 907, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (380, 937, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (431, 949, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (481, 939, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (526, 908, 8));
	
	sdContextAddLamp (shadowContext, lampCreate (112, 962));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (131, 975, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (101, 892, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (166, 934, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (103, 1017, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (49, 1106, 8));
	
	sdContextAddLamp (shadowContext, lampCreate (752, 962));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (732, 976, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (759, 892, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (695, 934, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (757, 1016, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (813, 1106, 8));
	
	sdContextAddLamp (shadowContext, lampCreate (172, 1275));
	sdContextAddLamp (shadowContext, lampCreate (220, 1381));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (159, 1195, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (159, 1374, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (261, 1434, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (207, 1323, 8));
	
	sdContextAddLamp (shadowContext, lampCreate (692, 1281));
	sdContextAddLamp (shadowContext, lampCreate (641, 1384));
	
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (705, 1198, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (702, 1376, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (600, 1435, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (653, 1328, 8));

	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism(842, 482, 862, 1532));
}

- (void) addSlickChickLightsAndObstacles {
	shadowContext = sdContextCreate ("Slick Chick", 1024, 2048);
	shadowContext->tempScalar = 80000;
	
	// Lights.
	sdContextAddLamp (shadowContext, lampCreate (436, 421));
	sdContextAddLamp (shadowContext, lampCreate (80, 784));
	sdContextAddLamp (shadowContext, lampCreate (791, 792));
	sdContextAddLamp (shadowContext, lampCreate (68, 1402));
	sdContextAddLamp (shadowContext, lampCreate (175, 1520));
	sdContextAddLamp (shadowContext, lampCreate (707, 1517));
	sdContextAddLamp (shadowContext, lampCreate (802, 1420));
	
	// Bumpers.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (150, 493, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (718, 497, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (288, 647, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (578, 647, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (430, 798, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (290, 946, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (576, 950, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (158, 1099, 40));
//	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (150, 1099, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (720, 1101, 40));

	// Lane walls.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (304, 354.5, 123.4, 8, -62));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (561, 354.5, 123.4, 8, 62));

	// Targets.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (111, 825, 40, 2, -40));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (756, 830, 40, 2, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (434, 465, 40, 2, 0));

	// Pegs
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (333, 300, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (275, 409, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (433, 327, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (358, 470, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (509, 467, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (532, 300, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (590, 409, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (105, 418, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (104, 566, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (764, 424, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (764, 571, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (51, 650, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (151, 772, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (823, 653, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (721, 774, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (50, 862, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (50, 956, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (822, 859, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (822, 954, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (429, 977, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (105, 1029, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (104, 1176, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (766, 1029, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (765, 1175, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (51, 1270, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (825, 1268, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (48, 1338, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (50, 1490, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (230, 1537, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (231, 1598, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (288, 1633, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (366, 1678, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (507, 1679, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (584, 1634, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (646, 1602, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (645, 1540, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (828, 1497, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (832, 1351, 8));
	
	// Blocked off left and right sides.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (844, 447, 867, 2048));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (0, 0, 25, 2048));
	
	// Apron.
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (25, 1512, 397, 1723, 397, 2048, 25, 2048));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (461, 1727, 850, 1509, 850, 2048, 461, 2048));
	
	// Arch.
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (38, 384 - 30, 0, 400 - 30, 0, 0, 38, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (97, 246 - 30, 38, 384 - 30, 38, 0, 97, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (166, 161 - 30, 97, 246 - 30, 97, 0, 166, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (257, 94 - 30, 166, 161 - 30, 166, 0, 257, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (383, 51 - 30, 257, 94 - 30, 257, 0, 383, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (527, 45 - 30, 383, 51 - 30, 383, 0, 527, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (630, 64 - 30, 527, 45 - 30, 527, 0, 630, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (730, 106 - 30, 630, 64 - 30, 630, 0, 730, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (816, 179 - 30, 730, 106 - 30, 730, 0, 816, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (895, 301 - 30, 816, 179 - 30, 816, 0, 895, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (936, 418 - 30, 895, 301 - 30, 895, 0, 936, 0));
	
	// Voids.
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (430, 522, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (431, 581, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (430, 640, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (432, 1112, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (434, 1412, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (234, 1358, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (627, 1360, 22), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (112, 1224, 18), 0.0));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateCylinder (756, 1226, 18), 0.0));
}

- (void) addDominoLightsAndObstacles {
	shadowContext = sdContextCreate ("Domino", 1024, 2048);
	shadowContext->tempScalar = 25000;	// 20000, kind of dark, 30000 maybe too bright?
	
	// Lights.
	sdContextAddLamp (shadowContext, lampCreate (94, 362));
	sdContextAddLamp (shadowContext, lampCreate (248, 385));
	sdContextAddLamp (shadowContext, lampCreate (344, 385));
	sdContextAddLamp (shadowContext, lampCreate (442, 383));
	sdContextAddLamp (shadowContext, lampCreate (539, 383));
	sdContextAddLamp (shadowContext, lampCreate (637, 381));
	sdContextAddLamp (shadowContext, lampCreate (789, 365));
	sdContextAddLamp (shadowContext, lampCreate (67, 590));
	sdContextAddLamp (shadowContext, lampCreate (820, 578));
	sdContextAddLamp (shadowContext, lampCreate (61, 828));
	sdContextAddLamp (shadowContext, lampCreate (816, 818));
	sdContextAddLamp (shadowContext, lampCreate (85, 994));
	sdContextAddLamp (shadowContext, lampCreate (791, 988));
	sdContextAddLamp (shadowContext, lampCreate (65, 1085));
	sdContextAddLamp (shadowContext, lampCreate (807, 1095));
	sdContextAddLamp (shadowContext, lampCreate (53, 1188));
	sdContextAddLamp (shadowContext, lampCreate (817, 1187));
	sdContextAddLamp (shadowContext, lampCreate (130, 1373));
	sdContextAddLamp (shadowContext, lampCreate (737, 1374));
	sdContextAddLamp (shadowContext, lampCreate (219, 1469));
	sdContextAddLamp (shadowContext, lampCreate (654, 1471));
	sdContextAddLamp (shadowContext, lampCreate (348, 990));
	sdContextAddLamp (shadowContext, lampCreate (544, 988));
	
	// Posts.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (128, 304, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (151, 353, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (149, 421, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (248, 348, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (248, 421, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (757, 298, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (344, 348, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (344, 421, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (732, 346, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (442, 347, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (442, 420, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (730, 415, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (540, 348, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (540, 421, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (384, 828, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (635, 346, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (635, 419, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (491, 828, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (261, 926, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (613, 923, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (263, 999, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (401, 1011, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (482, 1009, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (615, 1000, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (70, 549, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (67, 689, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (817, 542, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 684, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (68, 731, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (67, 868, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (62, 907, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (101, 955, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (88, 1052, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (75, 1145, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (64, 1228, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (125, 1320, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (198, 1423, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (275, 1516, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (126, 1434, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 724, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 859, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (815, 909, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (772, 957, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (786, 1047, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (800, 1142, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (812, 1227, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (752, 1321, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (752, 1436, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (601, 1518, 8));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (686, 1417, 8));
	
	// Bumpers.
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (245, 670, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (441, 563, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (636, 665, 40));
	sdContextAddObstacle (shadowContext, obstacleCreateCylinder (439, 772, 40));
	
	// Targets.
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (442, 1034, 40, 2, 0));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (102, 1001, 40, 2, -80));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (92, 1100, 40, 2, -80));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (80, 1187, 40, 2, -80));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (769, 1002, 40, 2, -110));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (785, 1099, 40, 2, -110));
	sdContextAddObstacle (shadowContext, obstacleCreateRotatedRectangularPrism (795, 1188, 40, 2, -110));
	
	// Lanes.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (243, 348, 253, 421));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (339, 348, 349, 421));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (437, 348, 447, 421));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (535, 348, 545, 421));
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (630, 348, 640, 421));
	
	// Blocked off left and right sides.
	sdContextAddObstacle (shadowContext, obstacleCreateRectangluarPrism (0, 0, 25, 2048));
	sdContextAddObstacle (shadowContext, obstacleSetOpacity (obstacleCreateRectangluarPrism (838, 482, 861, 2048), 0.7));
	
	// Apron.
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (25, 1512, 397, 1723, 397, 2048, 25, 2048));
	sdContextAddObstacle (shadowContext, obstacleCreateQuadPrism (461, 1727, 850, 1509, 850, 2048, 461, 2048));
}

- (void) renderPlayfield {
	bmContextFillBuffer (bitmap, 0, 0, 0, 255);
	sdContextRenderToBitmap (shadowContext, bitmap);
	
	CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(bitmap), bmContextBufferSize(bitmap), NULL);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGImageRef imageRef = CGImageCreate(bmContextWidth (bitmap), bmContextHeight (bitmap), 8, 32,
			4 * bmContextWidth (bitmap), colorSpaceRef,
			kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, provider, NULL, YES,
			kCGRenderingIntentDefault);
	
	NSImage *image = [[NSImage alloc] initWithCGImage: imageRef
			size: NSMakeSize (bmContextWidth (bitmap), bmContextHeight (bitmap))];
	self.shadowImageView.image = image;
	
	CGImageRelease (imageRef);
	CGColorSpaceRelease (colorSpaceRef);
	CGDataProviderRelease (provider);
}

- (void) applicationDidFinishLaunching: (NSNotification *) aNotification {
	// Create bitmap context.
	int bitmapWidth = 256; 	// 512;
	int bitmapHeight = 512;	// 1024;
	bitmap = bmContextCreate (bitmapWidth, bitmapHeight);
	
	[self test0];
//	[self addKingOfDiamondsLightsAndObstacles];
//	[self addSlickChickLightsAndObstacles];
//	[self addDominoLightsAndObstacles];

//	char *json = sdContextJSONRepresentation (shadowContext);
//	self.contextJSON = [NSString stringWithCString: json encoding: NSASCIIStringEncoding];
	
	[self renderPlayfield];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
	return YES;
}

- (IBAction) tempSlider: (id) sender {
	shadowContext->tempScalar = [sender intValue];
	[self renderPlayfield];
}

- (NSData *) getFullsizeBitmapData {
	NSData *bitmapData = NULL;
	BMContext *fullBitmap;
	
	fullBitmap = bmContextCreate (1024, 2048);
	bmContextFillBuffer (fullBitmap, 0, 0, 0, 255);
	sdContextRenderToBitmap (shadowContext, fullBitmap);
	
	CGDataProviderRef provider = CGDataProviderCreateWithData (NULL, bmContextBufferPtr(fullBitmap), bmContextBufferSize(fullBitmap), NULL);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGImageRef imageRef = CGImageCreate(bmContextWidth (fullBitmap), bmContextHeight (fullBitmap), 8, 32,
			4 * bmContextWidth (fullBitmap), colorSpaceRef,
			kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast, provider, NULL, YES,
			kCGRenderingIntentDefault);
	
	NSImage *image = [[NSImage alloc] initWithCGImage: imageRef
			size: NSMakeSize (bmContextWidth (fullBitmap), bmContextHeight (fullBitmap))];
	
	// No compression
	NSData *data = [image TIFFRepresentation];
	if (data != nil) {
		NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData: data];
		if (bitmapRep != nil) {
			bitmapData = [bitmapRep representationUsingType: NSBitmapImageFileTypePNG properties: @{}];
		}
	}
	
	CGImageRelease (imageRef);
	CGColorSpaceRelease (colorSpaceRef);
	CGDataProviderRelease (provider);
	
	return bitmapData;
}

- (IBAction) openJSONRepresentation: (id) sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	openPanel.allowsMultipleSelection = NO;
	[openPanel beginWithCompletionHandler:^ (NSInteger result) {
		if (result == NSModalResponseOK) {
			for (NSURL *oneURL in [openPanel URLs]) {
				NSError *error;
				NSString *json = [NSString stringWithContentsOfURL: oneURL encoding: NSASCIIStringEncoding error: &error];
				if (json) {
					if (shadowContext) {
						sdContextFree (shadowContext);
						shadowContext = NULL;
					}
					shadowContext = sdContextCreateFromJSONRepresentation ([json cStringUsingEncoding: NSASCIIStringEncoding]);
					[self renderPlayfield];
				}
			}
		}
	}];
}

- (IBAction) saveJSONRepresentation: (id) sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s.shadow", shadowContext->name];
	[panel beginWithCompletionHandler: ^(NSModalResponse result) {
		if (result == NSModalResponseOK) {
			NSString *json = [NSString stringWithCString: sdContextJSONRepresentation (shadowContext) encoding: NSASCIIStringEncoding];
			if (json) {
				NSError *error;
				[json writeToURL: [panel URL] atomically: YES encoding: NSUTF8StringEncoding error: &error];
			}
		}
	}];
}

- (IBAction) saveBitmap: (id) sender {
	NSSavePanel *panel = [NSSavePanel savePanel];
	panel.nameFieldStringValue = [NSString stringWithFormat: @"%s_shadows.png", shadowContext->name];
	[panel beginWithCompletionHandler: ^(NSModalResponse result) {
		if (result == NSModalResponseOK) {
			NSData *bitmapData = [self getFullsizeBitmapData];
			if (bitmapData) {
				[bitmapData writeToURL: [panel URL] atomically: YES];
			}
		}
	}];
}

@end
