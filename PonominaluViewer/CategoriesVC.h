//
//  CategoriesVC.h
//  PonominaluViewer
//
//  Copyright © 2016 DeveloperJourneyman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoriesVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *categoriesList;

@end
