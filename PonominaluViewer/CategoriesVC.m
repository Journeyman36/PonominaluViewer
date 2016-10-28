//
//  CategoriesVC.m
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import "CategoriesVC.h"
#import "CategoriesCell.h"
#import "reachability.h"
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "EventsVC.h"
#import "Config.h"

@interface CategoriesVC() {

  Reachability *_reachability;
  NSManagedObjectContext *_context;
  AppDelegate *_appDelegate;
  
  NSNumber *_selectedCategory;
}

@property (nonatomic, strong) NSArray *listData;

@end

@implementation CategoriesVC

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor blackColor];
  _categoriesList.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
  
  _reachability = [Reachability reachabilityForInternetConnection];
  _appDelegate = [[UIApplication sharedApplication] delegate];
  _context = [_appDelegate managedObjectContext];
  _listData = [NSArray array];
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
    _listData = [self getCategoriesFromStorage];
    
    if(_listData.count > 0)
    {
      [_categoriesList reloadData];
    }
    else
    {
      // TODO: Localize messages
      
      NSString *title = @"Error";
      NSString *message = @"No Internet Connection.\nNo Local Data to show.";
      
      [self showErrorAlertWithTitle:title message:message];
    }
  }
  else
  {
    NSString *urlString = [NSString stringWithFormat:categoriesApiLink, apiSession];
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
        [self updateCategoriesWithArray:message];
        
        _listData = [self getCategoriesFromStorage];
        if(_listData.count > 0)
        {
          [_categoriesList reloadData];
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

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([[segue identifier] isEqualToString:@"toEventsSegue"])
  {
    EventsVC *eventsController = [segue destinationViewController];
    eventsController.categoryId = _selectedCategory;
  }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  
  return _listData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"CategoriesCellID";
  
  CategoriesCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil)
  {
    cell = [[CategoriesCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  
  id currentItem = _listData[indexPath.row];
  NSNumber *eventsCount = [currentItem valueForKey:@"events_count"];
  
  cell.titleLabel.text = [currentItem valueForKey:@"title"];
  cell.countLabel.text = [eventsCount stringValue];
  
  return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  return [CategoriesCell heightForCell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   id currentItem = _listData[indexPath.row];
  _selectedCategory = [currentItem valueForKey:@"id"];
  
  [self performSegueWithIdentifier:@"toEventsSegue" sender:self];
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

#pragma mark - Core Data procedures

-(void) updateCategoriesWithArray:(NSArray *)array {
  
  if(_context)
  {
    NSArray *categoriesInStorage = [self getCategoriesFromStorage];
    
    for(NSDictionary *currentDict in array)
    {
      BOOL shouldAdd = YES;
      NSNumber *dictId = currentDict[@"id"];
      
      for(id storageCategory in categoriesInStorage)
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
        NSManagedObject *categoryToAdd = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:_context];
        
        NSNumber *categoryId = currentDict[@"id"];
        NSString *title = currentDict[@"title"];
        NSString *alias = currentDict[@"alias"];
        NSNumber *eventsCount = currentDict[@"events_count"];
        
        [categoryToAdd setValue:categoryId forKey:@"id"];
        [categoryToAdd setValue:title forKey:@"title"];
        [categoryToAdd setValue:alias forKey:@"alias"];
        [categoryToAdd setValue:eventsCount forKey:@"events_count"];
      }
    }

    [_appDelegate saveContext];
  }
}

-(NSArray *) getCategoriesFromStorage {
  
  NSEntityDescription *categoriesEntity = [NSEntityDescription entityForName:@"Category" inManagedObjectContext:_context];
  
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  [fetchRequest setEntity:categoriesEntity];
  
  NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES];
  [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
  
  NSArray *categoriesInStorage = [_context executeFetchRequest:fetchRequest error:nil];
  
  return [categoriesInStorage copy];
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

@end
