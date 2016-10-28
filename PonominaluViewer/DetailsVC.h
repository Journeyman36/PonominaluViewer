//
//  DetailsVC.h
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsVC : UIViewController

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (nonatomic, weak) IBOutlet UIImageView *detailsImageView;

@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, weak) IBOutlet UIButton *backButton;

@property (nonatomic, strong) NSNumber *categoryId;

@property (nonatomic, strong) NSNumber *eventId;

@end
