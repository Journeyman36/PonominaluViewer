//
//  EventsVC.m
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import "EventsVC.h"
#import "DetailsVC.h"
#import "EventsCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "reachability.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "Config.h"

@interface EventsVC () {
  
  Reachability *_reachability;
  NSManagedObjectContext *_context;
  AppDelegate *_appDelegate;
  
  NSNumber *_selectedEvent;
}

@property (nonatomic, strong) NSArray *listData;

@end

@implementation EventsVC

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor blackColor];
  _eventsList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  
  _reachability = [Reachability reachabilityForInternetConnection];
  _appDelegate = [[UIApplication sharedApplication] delegate];
  _context = [_appDelegate managedObjectContext];
  _listData = [NSArray array];
  
  [_backButton addTarget:self action:@selector(backButtonPressed) forControlEvents:UIControlEventTouchUpInside];
}

-(void)viewWillAppear:(BOOL)animated {
  
  [super viewWillAppear:animated];
  
  [_reachability startNotifier];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(networkStateChanged:)
                                               name:kReachabilityChangedNotification object:nil];
  
  NetworkStatus status = [_reachability currentReachabilityStatus];
  if (status == NotReachable)
  {
    _listData = [self getEventsFromStorageForCategoryId:_categoryId];
    
    if(_listData.count > 0)
    {
      [_eventsList reloadData];
    }
    else
    {
      NSString *title = @"Error";
      NSString *message = @"No Internet Connection.\nNo Local Data to show.";
      
      [self showErrorAlertWithTitle:title message:message];
    }
  }
  else
  {
    NSString *categoryIdString = [_categoryId stringValue];
    NSString *urlString = [NSString stringWithFormat:eventsApiLink,apiSession,categoryIdString];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSError *loadingError = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&loadingError];
    
    if(loadingError == nil)
    {
      NSError *jsonError = nil;
      id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
      
      if(jsonError == nil)
      {
        NSDictionary *dict = (NSDictionary *)jsonObject;
        
        NSArray *message = dict[@"message"];
        
        [self updateEventsWithArray:message];
        
        _listData = [self getEventsFromStorageForCategoryId:_categoryId];
        
        if(_listData.count > 0)
        {
          [_eventsList reloadData];
        }
        else
        {
          NSString *title = @"Error";
          NSString *message = @"No Local Data to show.";
          
          [self showErrorAlertWithTitle:title message:message];
        }
      }
    }
    else
    {
      NSString *title = @"Error";
      NSString *message = @"Data Loding failed.";
      
      [self showErrorAlertWithTitle:title message:message];
    }
  }
}

-(void)viewWillDisappear:(BOOL)animated {
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [_reachability stopNotifier];
  
  [super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  return _listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"EventCellID";
  
  EventsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[EventsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  id currentItem = _listData[indexPath.row];
  
  NSDate *date = [currentItem valueForKey:@"min_date"];
  NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
  [dateFormat setDateFormat:@"yyyy-MM-dd  HH:mm:ss"];
  NSString *dateString = [dateFormat stringFromDate:date];
  
  cell.titleLabel.text = [currentItem valueForKey:@"title"];
  cell.timeLabel.text = dateString;
  
  NSManagedObject *subevent = [currentItem valueForKey:@"eventSubeventRel"];
  NSString *imageName = [subevent valueForKey:@"image_name"];
  
  CGFloat imageSize = [EventsCell heightForCell];
  NSNumber *w = [NSNumber numberWithFloat: imageSize];
  NSNumber *h = [NSNumber numberWithFloat: imageSize];
  
  NSURL *url = [Config getImageUrlForName:imageName width:w height:h];
  
  [cell.eventsIcon sd_setImageWithURL:url
               placeholderImage:nil];
  
  return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return [EventsCell heightForCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
  id currentItem = _listData[indexPath.row];
  _selectedEvent = [currentItem valueForKey:@"id"];
  [self performSegueWithIdentifier:@"toDetailsSegue" sender:self];
  
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

#pragma mark - Network Reachability Changed events

- (void)networkStateChanged:(NSNotification *)notice {
  
  // TODO: network events handling
  /*NetworkStatus status = [_reachability currentReachabilityStatus];
  if (status == NotReachable)
  {
  }
  else
  {
  }*/
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"toDetailsSegue"])
  {
    DetailsVC *detailsController = [segue destinationViewController];
    detailsController.categoryId = _categoryId;
    detailsController.eventId = _selectedEvent;
  }
}

#pragma mark - Core Data procedures

-(void) updateEventsWithArray:(NSArray *)array {
  
  if(_context)
  {
    NSArray *eventsInStorage = [self getEventsFromStorage];
    
    for(NSDictionary *currentDict in array)
    {
      BOOL shouldAdd = YES;
      NSNumber *dictId = currentDict[@"id"];
      
      for(id storageCategory in eventsInStorage)
      {
        NSNumber *storageId = [storageCategory valueForKey:@"id"];
        if([storageId integerValue] == [dictId integerValue])
        {
          shouldAdd = NO;
          break;
        }
      }
      
      if(shouldAdd == YES)
      {
        NSManagedObject *eventToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:_context];
        
        NSNumber *eventId = currentDict[@"id"];
        NSString *title = currentDict[@"title"];
        NSNumber *eticketPossible = currentDict[@"eticket_possible"];
        NSString *minDateString = currentDict[@"min_date"];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        NSDate *minDate = [dateFormat dateFromString:minDateString];
        NSString *eventDescription = currentDict[@"description"];
        
        [eventToAdd setValue:eventId forKey:@"id"];
        [eventToAdd setValue:title forKey:@"title"];
        [eventToAdd setValue:eticketPossible forKey:@"eticket_possible"];
        [eventToAdd setValue:minDate forKey:@"min_date"];
        [eventToAdd setValue:eventDescription forKey:@"event_description"];
        
        NSArray *categories = currentDict[@"categories"];
        [self setCategoryRelations:categories forEvent:eventToAdd];
        
        NSArray *subeventArray = currentDict[@"subevents"];
        [self updateSubeventsWithArray:subeventArray parentEvent:eventToAdd];
      }
    }
    
    [_appDelegate saveContext];
  }
}

-(NSArray *) getEventsFromStorage {
  
  NSEntityDescription *eventsEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:_context];
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setEntity:eventsEntity];
  
  NSArray *eventsInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  return [eventsInStorage copy];
}

-(NSArray *) getEventsFromStorageForCategoryId:(NSNumber *)categoryId {
  
  // TODO: predicate to get events immediately
  
  NSEntityDescription *eventsEntity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:_context];
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setIncludesPendingChanges:YES];
  [fetchRequest setEntity:eventsEntity];

  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  
  NSArray *eventsInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  NSMutableArray *result = [NSMutableArray array];
  for(id item in eventsInStorage)
  {
    NSSet *categoryRelSet = [item valueForKey:@"categoryRel"];
    NSArray *categoryRelArray = [categoryRelSet allObjects];
    for(NSManagedObject *categoryRelation in categoryRelArray)
    {
      NSNumber *currentId = [categoryRelation valueForKey:@"id"];
      if([categoryId integerValue] == [currentId integerValue])
      {
        [result addObject:item];
        break;
      }
    }
  }

  return [result copy];
}

-(void) updateSubeventsWithArray:(NSArray *)array parentEvent:(NSManagedObject *)event{
  if(_context)
  {
    NSArray *subeventsInStorage = [self getSubeventsFromStorage];
    
    for(NSDictionary *currentDict in array)
    {
      BOOL shouldAdd = YES;
      NSNumber *dictId = currentDict[@"id"];
      
      for(id storageCategory in subeventsInStorage)
      {
        NSNumber *storageId = [storageCategory valueForKey:@"subevent_id"];
        if([storageId integerValue] == [dictId integerValue])
        {
          shouldAdd = NO;
          break;
        }
      }
      
      if(shouldAdd == YES)
      {
        NSManagedObject *subeventToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"Subevent" inManagedObjectContext:_context];
        
        NSNumber *subeventId = currentDict[@"id"];
        NSString *imageName = currentDict[@"image"];
        NSString *dateString = currentDict[@"date"];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
        NSDate *date = [dateFormat dateFromString:dateString];
        NSNumber *count = currentDict[@"count"];
        NSNumber *maxPrice = currentDict[@"max_price"];
        NSNumber *minPrice = currentDict[@"min_price"];
        
        [subeventToAdd setValue:subeventId forKey:@"subevent_id"];
        [subeventToAdd setValue:imageName forKey:@"image_name"];
        [subeventToAdd setValue:date forKey:@"date"];
        [subeventToAdd setValue:count forKey:@"count"];
        [subeventToAdd setValue:maxPrice forKey:@"max_price"];
        [subeventToAdd setValue:minPrice forKey:@"min_price"];
        
        [subeventToAdd setValue:event forKey:@"eventRel"];
        
        NSDictionary *venueDict = currentDict[@"venue"];
        [self updateVenuesWithDictionary:venueDict parentSubevent:subeventToAdd];
      }
      
      // We take only the 1st subevent
      break;
    }
  }
}

-(NSArray *) getSubeventsFromStorage {
  
  NSEntityDescription *subeventsEntity = [NSEntityDescription entityForName:@"Subevent" inManagedObjectContext:_context];
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setEntity:subeventsEntity];
  
  NSArray *subeventsInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  return [subeventsInStorage copy];
}

-(void) updateVenuesWithDictionary:(NSDictionary *)dict parentSubevent:(NSManagedObject *)subevent {
  
  if(_context)
  {
    NSArray *venuesInStorage = [self getVenuesFromStorage];
    
    BOOL shouldAdd = YES;
    NSNumber *dictId = dict[@"id"];
    
    for(id storageCategory in venuesInStorage)
    {
      NSNumber *storageId = [storageCategory valueForKey:@"id"];
      if([storageId integerValue] == [dictId integerValue])
      {
        shouldAdd = NO;
        break;
      }
    }
    
    if(shouldAdd == YES)
    {
      NSManagedObject *venueToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"Venue" inManagedObjectContext:_context];
      
      NSNumber *venueId = dict[@"id"];
      NSString *title = dict[@"title"];
      NSString *address = dict[@"address"];
      NSDictionary *regionDict = dict[@"region"];
      NSString *regionTitle = regionDict[@"title"];
      
      [venueToAdd setValue:venueId forKey:@"id"];
      [venueToAdd setValue:title forKey:@"title"];
      [venueToAdd setValue:address forKey:@"address"];
      [venueToAdd setValue:regionTitle forKey:@"region_title"];
      
      [subevent setValue:venueToAdd forKey:@"venueRel"];
    }
  }
}

-(NSArray *) getVenuesFromStorage {
  
  NSEntityDescription *venuesEntity = [NSEntityDescription entityForName:@"Venue" inManagedObjectContext:_context];
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setEntity:venuesEntity];
  
  NSArray *venuesInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  return [venuesInStorage copy];
}

-(void) setCategoryRelations:(NSArray *)categories forEvent:(NSManagedObject *)event {
  
  for(NSDictionary *category in categories)
  {
    NSString *categoryId = category[@"id"];
    
    NSEntityDescription *categoriesEntity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:_context];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:categoriesEntity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id == %@", categoryId];
    [fetchRequest setPredicate:predicate];
    
    NSArray *categoriesInStorage = [_context executeFetchRequest:fetchRequest error:nil];
    
    NSMutableSet *categoryRelSet = [event mutableSetValueForKey:@"categoryRel"];
    
    for(NSManagedObject *categoryInStorage in categoriesInStorage)
    {
      [categoryRelSet addObject:categoryInStorage];
    }
    
    [event setValue:categoryRelSet forKey:@"categoryRel"];
  }
}

#pragma mark - error alerts, alert view delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  
  // TODO: alerts buttons handlers
  /*
   if (buttonIndex == 0)
   {
   }*/
}

-(void) showErrorAlertWithTitle:(NSString *)title message:(NSString *)message {
  
  NSString *okButtonTitle = @"OK";
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                  message:message
                                                 delegate:self
                                        cancelButtonTitle:okButtonTitle
                                        otherButtonTitles:nil,nil];
  [alert show];
  
}

-(void)backButtonPressed {

  [self performSegueWithIdentifier:@"backToCategoriesSegue" sender:self];
}

@end
