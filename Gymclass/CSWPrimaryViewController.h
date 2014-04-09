//
//  CSWPrimaryViewController.h
//  Gymclass
//
//  Created by Eric Colton on 8/13/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSWDay.h"
#import "CSWTime.h"
#import "CSWScheduleViewCell.h"
#import "CSWFilterViewController.h"
#import "CSWIndicatorManager.h"

@interface CSWPrimaryViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, CSWFilterViewControllerDelegate, CSWIndicatorManagerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *devLabel;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UILabel *filteringLabel;
@property (weak, nonatomic) IBOutlet UIButton *prevDayButton;
@property (weak, nonatomic) IBOutlet UIButton *nextDayButton;
@property (strong, nonatomic) UIActivityIndicatorView *networkIndicator;

@property (weak, nonatomic) IBOutlet UITableView *scheduleTableView;

@property (strong, nonatomic) CSWDay *selectedDay;
@property (strong, nonatomic) CSWTime *selectedTime;

-(IBAction)prevDay:(id)sender;
-(IBAction)nextDay:(id)sender;

-(void)setSelectedTimeToNow;
-(void)focusOnSelectedDateAndTime:(bool)animated;

@end
