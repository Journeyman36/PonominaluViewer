//
//  EventsCell.h
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventsCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *eventsIcon;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;

+(CGFloat)heightForCell;

@end
