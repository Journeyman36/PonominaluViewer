//
//  Config.h
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import <UIKit/UIKit.h>

#define logoImageLink @"http://kupitbilet.com/data/test.jpg"

#define apiSession @"sesson_iphone_2015_ponominalu_msk"

#define imageApiLink @"http://media.cultserv.ru/i/%ldx%ld/%@"

#define categoriesApiLink @"http://poligon.cultserv.ru/v4/categories/list?session=%@"

#define eventsApiLink @"http://poligon.cultserv.ru/v4/events/list?session=%@&category_id=%@"

@interface Config : NSObject

+(NSURL *) getImageUrlForName:(NSString *)imageName  width:(NSNumber *)width height:(NSNumber *)height;

@end
