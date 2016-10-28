//
//  Config.m
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import "Config.h"

@implementation Config

+(NSURL *) getImageUrlForName:(NSString *)imageName  width:(NSNumber *)width height:(NSNumber *)height {
  
  
  
  NSInteger localWidth = [width integerValue];
  NSInteger localHeight = [height integerValue];
  
  // Dirty huck cause of api bug. Too large sizes don't return any image
  if([width integerValue] > 400)
    localWidth = 400;
  if([height integerValue] > 300)
    localHeight = 300;
  
  NSString *urlString = [NSString stringWithFormat:imageApiLink, localWidth,localHeight, imageName];
  
  NSURL *url = [NSURL URLWithString:urlString];

  return url;
}

@end
