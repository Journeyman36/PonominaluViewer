//
//  DetailsVC.m
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import "DetailsVC.h"
#import "EventsVC.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Config.h"

@interface DetailsVC () {
  
  NSManagedObjectContext *_context;
  AppDelegate *_appDelegate;
}

@end

@implementation DetailsVC

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  _appDelegate = [[UIApplication sharedApplication] delegate];
  _context = [_appDelegate managedObjectContext];
  
  [_backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  NSManagedObject *event = [self getEventWithId:_eventId];
  NSManagedObject *subevent = [event valueForKey:@"eventSubeventRel"];
  NSManagedObject *venue = [subevent valueForKey:@"venueRel"];
  
  NSString *imageName = [subevent valueForKey:@"image_name"];
  
  CGRect applicationFrame = [[UIScreen mainScreen] bounds];
  CGFloat screenWidth = applicationFrame.size.width;
  
  NSNumber *w = [NSNumber numberWithFloat: screenWidth];
  NSNumber *h = [NSNumber numberWithFloat: ceil((screenWidth/4.0) * 3.0)];
  NSURL *url = [Config getImageUrlForName:imageName width:w height:h];
  
  [_detailsImageView sd_setImageWithURL:url placeholderImage:nil];
  
  NSString *title = [event valueForKey:@"title"];
  NSString *descr = [event valueForKey:@"event_description"];
  
  NSNumber *minPrice = [subevent valueForKey:@"min_price"];
  NSString *minPriceString = [minPrice stringValue];
  
  NSNumber *maxPrice = [subevent valueForKey:@"max_price"];
  NSString *maxPriceString = [maxPrice stringValue];
  
  NSNumber *count = [subevent valueForKey:@"count"];
  NSString *countString = [count stringValue];
  
  NSDate *date = [event valueForKey:@"min_date"];
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy-MM-dd  HH:mm:ss"];
  NSString *dateString = [dateFormat stringFromDate:date];
  
  NSString *venueTitle = [venue valueForKey:@"title"];
  
  NSString *venueAddress =[venue valueForKey:@"address"];
  
  NSString *labelText = @"No Data";
  
  if(title && title.length)
  {
    labelText = title;
  }
  
  if(descr && descr.length)
  {
    labelText = [labelText stringByAppendingString:@"\n\n"];
    labelText = [labelText stringByAppendingString:descr];
  }
  
  if(minPriceString && minPriceString.length)
  {
    labelText = [labelText stringByAppendingString:@"Price: "];
    labelText = [labelText stringByAppendingString:minPriceString];
    
    if(maxPriceString && maxPriceString.length)
    {
      labelText = [labelText stringByAppendingString:@" - "];
      labelText = [labelText stringByAppendingString:maxPriceString];
    }
  }

  if(countString && countString.length)
  {
    labelText = [labelText stringByAppendingString:@"\n\n"];
    labelText = [labelText stringByAppendingString:@"Count: "];
    labelText = [labelText stringByAppendingString:countString];
  }
  
  if(dateString && dateString.length)
  {
    labelText = [labelText stringByAppendingString:@"\n\n"];
    labelText = [labelText stringByAppendingString:@"Date: "];
    labelText = [labelText stringByAppendingString:dateString];
  }
  
  if(venueTitle && venueTitle.length)
  {
    labelText = [labelText stringByAppendingString:@"\n\n"];
    labelText = [labelText stringByAppendingString:@"Venue: "];
    labelText = [labelText stringByAppendingString:venueTitle];
  }
  
  if(venueAddress && venueAddress.length)
  {
    labelText = [labelText stringByAppendingString:@"\n\n"];
    labelText = [labelText stringByAppendingString:venueAddress];
  }

  _descriptionLabel.text = labelText;
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"backToEventsSegue"])
  {
    EventsVC *eventsController = [segue destinationViewController];
    eventsController.categoryId = _categoryId;
  }
}

-(void)backButtonPressed {
  
  [self performSegueWithIdentifier:@"backToEventsSegue" sender:self];
}

#pragma mark - Core Data procedures

-(NSManagedObject *) getEventWithId:(NSNumber *)eventId {
  
  NSEntityDescription *eventsEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:_context];
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setEntity:eventsEntity];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", eventId];
  [fetchRequest setPredicate:predicate];
  
  
  NSArray *eventsInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  NSManagedObject *event = [eventsInStorage firstObject];
  
  return event;
}

@end
