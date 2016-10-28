//
//  ViewController.m
//  PonominaluViewer
//
//  Copyright © 2016 Journeyman. All rights reserved.
//

#import "StartVC.h"
#import "CategoriesVC.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "Config.h"

@interface StartVC (){

  NSTimer *_timer;
}

@end

@implementation StartVC

- (void)viewDidLoad {
  
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  NSURL *url = [NSURL URLWithString:logoImageLink];
  
  [_launchImageView sd_setImageWithURL:url placeholderImage:nil];
  
  UITapGestureRecognizer *singleTap =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleSingleTap:)];
  _launchImageView.userInteractionEnabled = YES;
  [_launchImageView addGestureRecognizer:singleTap];
}

-(void) viewDidAppear:(BOOL)animated {

  [super viewDidAppear:animated];
  
  _timer = [NSTimer timerWithTimeInterval:3.0 target:self selector:@selector(showCategories) userInfo:nil repeats:NO];
  [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
  
  [super viewWillDisappear:animated];
  
  if ([_timer isValid])
  {
    [_timer invalidate];
  }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
  
  if ([_timer isValid])
  {
    [_timer invalidate];
  }
  
  [self showCategories];
  
}

- (void) showCategories {

  [self performSegueWithIdentifier:@"toCategoriesSegue" sender:self];
}

@end
