//
//  CategoriesCell.h
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoriesCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *countLabel;

+(CGFloat)heightForCell;

@end
