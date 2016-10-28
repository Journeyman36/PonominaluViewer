//
//  EventsVC.h
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsVC : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *eventsList;

@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (nonatomic, strong) NSNumber *categoryId;

@end
