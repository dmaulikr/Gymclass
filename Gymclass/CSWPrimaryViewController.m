//
//  CSWPrimaryViewController.m
//  Gymclass
//
//  Created by Eric Colton on 8/13/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CSWAppDelegate.h"
#import "CSWPrimaryViewController.h"
#import "CSWWorkout.h"
#import "CSWWod.h"
#import "CSWTime.h"
#import "CSWScheduleStore.h"
#import "CSWScheduleViewCell.h"
#import "CSWWodViewController.h"
#import "CSWColors.h"
#import "CSWLoginViewController.h"

#define ONE_DAY 60*60*24

static NSLocale *gLocale;
static NSDateFormatter *gDayDateFormatter;

typedef NS_ENUM( NSUInteger, WorkoutTimeStatus ) {
    WorkoutTimeStatusFutureNormal
   ,WorkoutTimeStatusFutureCannotUndo
   ,WorkoutTimeStatusPast
};

@interface CSWPrimaryViewController ()
{
    NSTimeZone *_gymTimeZone;
    UILabel *_titleLabel;
    UILabel *_nowLabel;
    UILabel *_configLabel;
    UIBarButtonItem *_wodBarButton;
    UILabel *_wodLabel;
    CSWWodViewController *_wodViewController;
    UIButton *_blackoutButton;
    UILabel *_filterBarButtonLabel;
    CSWLoginViewController *_loginVC;
    CSWWorkout *selectedWorkout;
    WorkoutQueryType selectedWorkoutQueryType;
    UITableViewCell *selectedCell;
    NSIndexPath *selectedIndexPath;
    UIAlertView *cannotUndoAlertView;
}

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) UIActivityIndicatorView *networkIndicator;

@property (weak, nonatomic) IBOutlet CSWScheduleViewCell *cell;

@property (strong, nonatomic) CSWScheduleStore *store;
@property (strong, nonatomic) CSWWodViewController *wodViewController;
@property (strong, nonatomic) CSWFilterViewController *filterViewController;

@end

@implementation CSWPrimaryViewController

+(void)initialize
{
    gLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    gDayDateFormatter = [[NSDateFormatter alloc] init];
    gDayDateFormatter.locale = gLocale;
    gDayDateFormatter.dateFormat = @"EEEE M/d/yyyy";
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.managedObjectContext = [(CSWAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        [self.managedObjectContext setStalenessInterval:0.0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(modelWasUpdated:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.store.backgroundThreadMoc
         ];
        
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setSelectedTimeToNow];
    
    self.scheduleTableView.separatorInset = UIEdgeInsetsZero;

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.backgroundView.frame;
    gradient.colors = @[(id)[UIColor whiteColor].CGColor,(id)[UIColor lightGrayColor].CGColor];
    [self.backgroundView.layer insertSublayer:gradient atIndex:0];

    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,150,30)];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.font = [UIFont fontWithName:@"American Typewriter" size:20];
    _titleLabel.text = [self.store fetchGymConfigValue:@"displayShortName"];
    [self.navigationItem setTitleView:_titleLabel];
    
    NSNumber *canFetchWodDesc       = [self.store fetchGymConfigValue:@"canFetchWodDesc"];
    NSNumber *canFilterByLocation   = [self.store fetchGymConfigValue:@"canFilterByLocation"];
    NSNumber *canFilterByInstructor = [self.store fetchGymConfigValue:@"canFilterByInstructor"];
    
    UILabel *nowLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
    nowLabel.backgroundColor = [UIColor clearColor];
    nowLabel.text = @"now";
    nowLabel.font = [UIFont systemFontOfSize:12];
    nowLabel.textColor = [UIColor whiteColor];
    nowLabel.textAlignment = NSTextAlignmentCenter;
    
    UIButton *nowButton = [UIButton buttonWithType:UIButtonTypeCustom];
    nowButton.frame = nowLabel.frame;
    nowButton.reversesTitleShadowWhenHighlighted = true;
    nowButton.showsTouchWhenHighlighted = true;
    [nowButton addTarget:self action:@selector(nowPressed:) forControlEvents:UIControlEventTouchUpInside];
    [nowButton addSubview:nowLabel];
    
    UIBarButtonItem *nowBarButton = [[UIBarButtonItem alloc] initWithCustomView:nowButton];
    
    UIBarButtonItem *fixedSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                 target:self
                                                                                 action:nil
                                    ];

    NSMutableArray *toolbarItems = [NSMutableArray arrayWithObjects:nowBarButton, fixedSpace1, nil];
    
    if ( canFetchWodDesc && canFetchWodDesc.boolValue ) {
        
        self.wodViewController = [CSWWodViewController new];
        
        // I wish I could use curl, but it screws up the navigationbar and toolbar
        // self.wodViewController.modalTransitionStyle = UIModalTransitionStylePartialCurl;
        self.wodViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        _wodLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
        _wodLabel.backgroundColor = [UIColor clearColor];
        _wodLabel.text = @"wod";
        _wodLabel.font = [UIFont systemFontOfSize:12];
        _wodLabel.textColor = [UIColor grayColor];
        _wodLabel.textAlignment = NSTextAlignmentCenter;
        
        UIButton *wodButton = [UIButton buttonWithType:UIButtonTypeCustom];
        wodButton.frame = _wodLabel.frame;
        wodButton.reversesTitleShadowWhenHighlighted = true;
        wodButton.showsTouchWhenHighlighted = true;
        [wodButton addTarget:self action:@selector(wodPressed:) forControlEvents:UIControlEventTouchUpInside];
        [wodButton addSubview:_wodLabel];
        
        _wodBarButton = [[UIBarButtonItem alloc] initWithCustomView:wodButton];
        _wodBarButton.enabled = false;
        
        UIBarButtonItem *fixedSpace2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                     target:self
                                                                                     action:nil
                                        ];
        
        [toolbarItems addObject:_wodBarButton];
        [toolbarItems addObject:fixedSpace2];
    }

    if (    ( canFilterByLocation && canFilterByLocation.boolValue )
         || ( canFilterByInstructor && canFilterByInstructor.boolValue )
       ) {
        
        self.filterViewController = [CSWFilterViewController new];
        self.filterViewController.delegate = self;
        
        _filterBarButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,50,20)];
        _filterBarButtonLabel.backgroundColor = [UIColor clearColor];
        _filterBarButtonLabel.text = @"filter";
        _filterBarButtonLabel.font = [UIFont systemFontOfSize:12];
        _filterBarButtonLabel.textAlignment = NSTextAlignmentCenter;
        
        UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        filterButton.frame = _filterBarButtonLabel.frame;
        filterButton.reversesTitleShadowWhenHighlighted = true;
        filterButton.showsTouchWhenHighlighted = true;
        [filterButton addTarget:self action:@selector(filterPressed:) forControlEvents:UIControlEventTouchUpInside];
        [filterButton addSubview:_filterBarButtonLabel];
        
        UIBarButtonItem *filterBarButton = [[UIBarButtonItem alloc] initWithCustomView:filterButton];
        
        [toolbarItems addObject:filterBarButton];
    }
    
    [self setToolbarItems:toolbarItems];
    
    UIImage *gearImage = [UIImage imageNamed:@"gear"];
    UIButton *configButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,gearImage.size.width, gearImage.size.height)];
    [configButton setBackgroundImage:gearImage forState:UIControlStateNormal];

    configButton.showsTouchWhenHighlighted = YES;
    [configButton addTarget:self action:@selector(configPressed:) forControlEvents:UIControlEventTouchUpInside];

    UIBarButtonItem *configBarButton = [[UIBarButtonItem alloc] initWithCustomView:configButton];
    [self.navigationItem setLeftBarButtonItems:@[configBarButton]];
    
    self.networkIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.networkIndicator.hidesWhenStopped = true;
    
    UIBarButtonItem *indicatorBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.networkIndicator];

    [self.navigationItem setRightBarButtonItems:@[indicatorBarButtonItem]];

    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextDay:)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.scheduleTableView addGestureRecognizer:swipeLeft];
    
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(prevDay:)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [self.scheduleTableView addGestureRecognizer:swipeRight];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    _fetchedResultsController = nil;
    _store = nil;
    _gymTimeZone = nil;
    _titleLabel = nil;
    _nowLabel = nil;
    _configLabel = nil;
    _wodViewController = nil;
    _filterViewController = nil;
    _loginVC = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:FALSE animated:TRUE];
    
    [self updateDateLabel];

    [self fetchResultsForScheduleView];
    [self updateWodButtonState];
    [self updateFilteringText];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:FALSE animated:TRUE];
    [self scrollToSelectedTime:true];
}


//
#pragma mark accessor methods (public)
//
-(NSFetchedResultsController *)fetchedResultsController
{
    if ( _fetchedResultsController ) {
        return _fetchedResultsController;
    }
    
    NSString *gymId = [CSWMembership sharedMembership].gymId;
    
    NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:@"Workout"];
    
    NSString *predicateStr = @"gymId = %@ AND day = %d AND displayable = 1";
    
    id filterObject;
    if ( self.filterViewController.activeFilterType == CSWFilterTypeInstructor ) {
        predicateStr = [predicateStr stringByAppendingString:@" AND instructor = %@"];
        filterObject = self.filterViewController.filterInstructor;
    } else if ( self.filterViewController.activeFilterType == CSWFilterTypeLocation ) {
        predicateStr = [predicateStr stringByAppendingString:@" AND location = %@"];
        filterObject = self.filterViewController.filterLocation;
    }

    fr.predicate = [NSPredicate predicateWithFormat:predicateStr, gymId, self.selectedDay.asInt, filterObject];
    fr.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"time" ascending:true]
                           ,[[NSSortDescriptor alloc] initWithKey:@"workoutId" ascending:true]
                          ];
    fr.fetchBatchSize = 20;
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fr
                                                                    managedObjectContext:self.managedObjectContext
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil
                                 ];
    
    _fetchedResultsController.delegate = self;
    
    return _fetchedResultsController;
}

//
#pragma mark accessor methods (private)
//
-(CSWScheduleStore *)store
{
    if ( _store ) return _store;
    
    _store = [CSWScheduleStore sharedStore];

    NSString *timeZone = [_store fetchGymConfigValue:@"timeZone"];
    
    if ( !timeZone ) timeZone = @"America/New_York";
    
    _gymTimeZone = [NSTimeZone timeZoneWithName:timeZone];

    return _store;
}

//
#pragma mark instance methods (public)
//
-(IBAction)prevDay:(id)sender
{
    [self.networkIndicator stopAnimating]; // to be sure it resets
    
    NSIndexPath *firstPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath *lastPath = [NSIndexPath indexPathForItem:self.fetchedResultsController.fetchedObjects.count-1 inSection:0];

    if ( [self.scheduleTableView.indexPathsForVisibleRows containsObject:firstPath] ) {
        self.selectedTime = [CSWTime timeWithNumber:@0];
    } else if ( [self.scheduleTableView.indexPathsForVisibleRows containsObject:lastPath] ) {
        self.selectedTime = [CSWTime timeWithNumber:@99999];
    } else if ( self.scheduleTableView.indexPathsForVisibleRows.count > 0 ) {
        
        NSIndexPath *firstVisible = self.scheduleTableView.indexPathsForVisibleRows[0];
        CSWWorkout *workout = [self.fetchedResultsController objectAtIndexPath:firstVisible];
        self.selectedTime = [CSWTime timeWithNumber:workout.time];
    }

    self.selectedDay = [CSWDay dayWithDate:[[self.selectedDay toDate] dateByAddingTimeInterval:-ONE_DAY]];
    [self updateDateLabel];
    
    [UIView transitionWithView:self.dateLabel
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [self updateDateLabel];
                    }
                    completion:nil
     ];
    
    [UIView transitionWithView:self.scheduleTableView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
                        [self focusOnSelectedDateAndTime:false];
                    }
                    completion:nil
     ];
}

-(IBAction)nextDay:(id)sender
{
    [self.networkIndicator stopAnimating]; // to be sure it resets
    
    NSIndexPath *firstPath = [NSIndexPath indexPathForItem:0 inSection:0];
    NSIndexPath *lastPath = [NSIndexPath indexPathForItem:self.fetchedResultsController.fetchedObjects.count-1 inSection:0];
    
    if ( [self.scheduleTableView.indexPathsForVisibleRows containsObject:firstPath] ) {
        self.selectedTime = [CSWTime timeWithNumber:@0];
    } else if ( [self.scheduleTableView.indexPathsForVisibleRows containsObject:lastPath] ) {
        self.selectedTime = [CSWTime timeWithNumber:@99999];
    } else if ( self.scheduleTableView.indexPathsForVisibleRows.count > 0 ) {
        
        NSIndexPath *firstVisible = self.scheduleTableView.indexPathsForVisibleRows[0];
        CSWWorkout *workout = [self.fetchedResultsController objectAtIndexPath:firstVisible];
        self.selectedTime = [CSWTime timeWithNumber:workout.time];
    }
    
    self.selectedDay = [CSWDay dayWithDate:[self.selectedDay.toDate dateByAddingTimeInterval:ONE_DAY]];

    [UIView transitionWithView:self.dateLabel
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [self updateDateLabel];
                    }
                    completion:nil
     ];
    
    [UIView transitionWithView:self.scheduleTableView
                      duration:0.2
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{
                        [self focusOnSelectedDateAndTime:false];
                    }
                    completion:nil
     ];
}

-(void)setSelectedTimeToNow
{
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    
    NSTimeZone *gymTimeZone = [NSTimeZone timeZoneWithName:[self.store fetchGymConfigValue:@"timeZone"]];
    
    NSInteger localOffset = timeZone.secondsFromGMT;
    NSInteger gymOffset = gymTimeZone.secondsFromGMT;
    NSInteger tzAdjustmentSecs = gymOffset - localOffset;
    
    NSDate *nowAdjusted = [NSDate dateWithTimeInterval:tzAdjustmentSecs sinceDate:[NSDate date]];
    
    self.selectedDay = [CSWDay dayWithDate:nowAdjusted];
    self.selectedTime = [CSWTime timeWithDate:nowAdjusted];
    
    [self updateDateLabel];
}

-(void)focusOnSelectedDateAndTime:(bool)animated
{
    [self updateWodButtonState];
    
    _fetchedResultsController = nil;
    [self fetchResultsForScheduleView];
    [self scrollToSelectedTime:animated];
}

//
#pragma mark instance methods (private)
//
-(void)configureCell:(UITableViewCell *)aCell atIndexPath:(NSIndexPath *)aIndexPath
{
    CSWWorkout *workout = [self.fetchedResultsController objectAtIndexPath:aIndexPath];
    
    CSWScheduleViewCell *cell = (CSWScheduleViewCell *)aCell;
    
    static NSNumber *nearFullConfigured = nil;
    if ( !nearFullConfigured ) {
        nearFullConfigured = [self.store fetchGymConfigValue:@"nearFull"];
        if ( !nearFullConfigured ) nearFullConfigured = @0;
    }
    
    int nearFull = nearFullConfigured.intValue;
    bool isNearFull = false;
    
    UIColor *statusColor;
    int available = workout.placesAvailable.intValue;
    
    if ( self.store.isLoggedIn
         && ( workout.isSignedUp.boolValue || workout.isOnWaitlist.boolValue )
       ) {
        statusColor = nil;
    } else if ( workout.isFull.boolValue ) {
        statusColor = [UIColor redColor];
    } else if ( available == -1 ) {
        statusColor = nil;
    } else if ( available <= nearFull ) {
        statusColor = [UIColor yellowColor];
        isNearFull = true;
    } else {
        statusColor = nil;
    }

    // time (12 hour)
    UILabel *label = (UILabel *)[cell viewWithTag:1];
    label.text = [[CSWTime timeWithNumber:workout.time] toDisplayTime12Hour];

    // time (AM/PM)
    label = (UILabel *)[cell viewWithTag:2];
    label.text = [[CSWTime timeWithNumber:workout.time] toDisplayTimeAmPm];
    
    // workout type
    label = (UILabel *)[cell viewWithTag:3];
    label.text = workout.displayType;
    
    // location
    label = (UILabel *)[cell viewWithTag:4];
    label.text = workout.location.displayName;
    
    // instructor
    label = (UILabel *)[cell viewWithTag:5];
    label.text = workout.instructor.displayName;
    
    UIImageView *checkmark = (UIImageView *)[cell viewWithTag:6];
    checkmark.hidden = !workout.isSignedUp.boolValue;
    
    WorkoutTimeStatus timeStatus = [self calculateWorkoutTimeStatus:workout];

    bool displayStatusColor = true;
    if ( self.store.isLoggedIn && !workout.isUpdatingToPurpose && workout.isSignedUp.boolValue ) {
        
        cell.desiredBackgroundColor = [CSWColors colorForPurpose:@"signedUp"];
        displayStatusColor = false;
        
    } else if ( self.store.isLoggedIn && !workout.isUpdatingToPurpose && workout.isOnWaitlist.boolValue ) {
        
        cell.desiredBackgroundColor = [CSWColors colorForPurpose:@"waitlisted"];
        displayStatusColor = false;
        
    } else {
        
        static UIColor *pastColor = nil, *cannotUndoColor = nil;
        if ( !pastColor ) {
            pastColor = [UIColor colorWithWhite:0.6 alpha:1.0];
            cannotUndoColor = [UIColor colorWithWhite:0.8 alpha:1.0];
        }
        
        if ( timeStatus == WorkoutTimeStatusPast ) {
            displayStatusColor = false;
            cell.desiredBackgroundColor = pastColor;
        } else if ( timeStatus == WorkoutTimeStatusFutureCannotUndo ) {
            displayStatusColor = true;
            cell.desiredBackgroundColor = cannotUndoColor;
        } else {
            displayStatusColor = true;
            cell.desiredBackgroundColor = [CSWColors colorForPurpose:@"notSignedUp"];
        }
    }
    
    // status color
    UILabel *statusColorLeft = (UILabel *)[cell viewWithTag:9];
    
    if ( displayStatusColor && statusColor ) {
        
        statusColorLeft.backgroundColor = statusColor;
        statusColorLeft.hidden = false;
        
    } else {
        
        statusColorLeft.hidden = true;
    }
    
    // spacesRemain
    label = (UILabel *)[aCell viewWithTag:8];
    if ( available > 0 && isNearFull && timeStatus != WorkoutTimeStatusPast ) {
        NSString *spots = ( available > 1 ) ? @"spots" : @"spot";
        label.text = [NSString stringWithFormat:@"%d %@", available, spots];
    } else {
        label.text = @"";
    }
    
    cell.calculatedAsPast = (timeStatus == WorkoutTimeStatusPast);
}


-(WorkoutTimeStatus)calculateWorkoutTimeStatus:(CSWWorkout *)aWorkout
{
    static NSUInteger currentTime, currentDate, cannotUndoTime;
    static CFTimeInterval lastTimeCheck = 0;
    
    // calculate times
    CFTimeInterval now = CFAbsoluteTimeGetCurrent();
    
    if ( !lastTimeCheck || now - lastTimeCheck > 60 ) {
        
        lastTimeCheck = now;
        
        static NSDateFormatter *dateDf = nil, *timeDf = nil;
        if ( !dateDf ) {
            
            dateDf = [[NSDateFormatter alloc] init];
            dateDf.timeZone = _gymTimeZone;
            dateDf.locale = gLocale;
            dateDf.dateFormat = @"yyyyMMdd";
            
            timeDf = [[NSDateFormatter alloc] init];
            timeDf.timeZone = _gymTimeZone;
            timeDf.locale = gLocale;
            timeDf.dateFormat = @"HHmm";
        }
        
        NSDate *nowDate = [NSDate date];
        
        NSNumber *cannotUndoMins = [self.store fetchGymConfigValue:@"cannotUndoWithinMins"];
        if ( !cannotUndoMins ) cannotUndoMins = @0;
        
        NSDate *cannotUndoDate = [nowDate dateByAddingTimeInterval:cannotUndoMins.intValue * 60];
        
        currentDate    = [dateDf stringFromDate:nowDate].integerValue;
        currentTime    = [timeDf stringFromDate:nowDate].integerValue;
        cannotUndoTime = [timeDf stringFromDate:cannotUndoDate].integerValue;
    }
    
    if ( aWorkout.day.integerValue < currentDate ) {
        
        return WorkoutTimeStatusPast;
        
    } else if ( aWorkout.day.integerValue > currentDate ) {
        
        return WorkoutTimeStatusFutureNormal;
        
    } else {
        
        if ( aWorkout.time.integerValue < currentTime ) {
            
            return WorkoutTimeStatusPast;
            
        } else if ( aWorkout.time.integerValue > cannotUndoTime ) {
            
            return WorkoutTimeStatusFutureNormal;
            
        } else {
            
            return WorkoutTimeStatusFutureCannotUndo;
        }
    }
}


-(void)fetchResultsForScheduleView
{
    [self.fetchedResultsController performFetch:NULL];
    [self.scheduleTableView reloadData];
    
    __block int refreshesNeededForIndicatorStop = 2;
    if ( [self.store fetchGymConfigValue:@"canFetchWodDesc"] ) refreshesNeededForIndicatorStop++;
    if ( self.store.isLoggedIn )                               refreshesNeededForIndicatorStop++;
    
    __block bool didShowAlert = NO;
    
    //completion blocks for this call are already on main thread
    bool refreshing = [self.store loadScheduleForDay:self.selectedDay
                              weekScheduleCompletion:^(bool didRefresh, NSError *error) {
                                  
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                      
                                      if ( --refreshesNeededForIndicatorStop <= 0 ) {
                                          [self.networkIndicator stopAnimating];
                                      }
                                      
                                      if ( error ) {
                                          
                                          if ( !didShowAlert ) {
                                              
                                              NSString *msg = [NSString stringWithFormat:@"Unable to update schedule for %@.", [self.store fetchGymConfigValue:@"displayShortName"]];
                                              
                                              [[[UIAlertView alloc] initWithTitle:@"Network Unavailable"
                                                                          message:msg
                                                                         delegate:nil
                                                                cancelButtonTitle:@"ok"
                                                                otherButtonTitles:nil] show];
                                              
                                              didShowAlert = YES;
                                          }
                                          
                                      } else if ( didRefresh ) {
                                          
                                          [self.fetchedResultsController performFetch:NULL];
                                          [self.scheduleTableView reloadData];
                                      }
                                  }];
                              }
                       
                              reservationsCompletion:^(NSError *error) {
                                  
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                      
                                      if ( --refreshesNeededForIndicatorStop <= 0 ) {
                                          [self.networkIndicator stopAnimating];
                                      }
                                      
                                      if ( error ) {
                                          
                                          if ( !didShowAlert ) {
                                              
                                              NSString *msg = [NSString stringWithFormat:@"Unable to signup statuses for %@.", [self.store fetchGymConfigValue:@"displayShortName"]];
                                              [[[UIAlertView alloc] initWithTitle:@"Network Unavailable"
                                                                          message:msg
                                                                         delegate:nil
                                                                cancelButtonTitle:@"ok"
                                                                otherButtonTitles:nil] show];
                                          }
                                      }
                                  }];
                              }
                       
                              daySpotsLeftCompletion:^(NSError *error) {
                                  
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                      
                                      if ( --refreshesNeededForIndicatorStop <= 0 ) {
                                          [self.networkIndicator stopAnimating];
                                      }
                                      
                                      if ( error ) {
                                          
                                          if ( !didShowAlert ) {
                                              
                                              NSString *msg = [NSString stringWithFormat:@"Unable to fetch remaining class openings for %@.", [self.store       fetchGymConfigValue:@"displayShortName"]];
                                              
                                              [[[UIAlertView alloc] initWithTitle:@"Network Unavailable"
                                                                          message:msg
                                                                         delegate:nil
                                                                cancelButtonTitle:@"ok"
                                                                otherButtonTitles:nil] show];
                                          }
                                      }
                                  }];
                              }
                       
                              wodDescCompletion:^(NSError *error) {
                                  
                                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                      
                                      if ( --refreshesNeededForIndicatorStop <= 0 ) {
                                          [self.networkIndicator stopAnimating];
                                      }
                                      
                                      // error is normal here; means wod is not yet available
                                      if ( !error ) {
                                          [self updateWodButtonState];
                                      }
                                  }];
                              }
                       ];

    if ( refreshing ) {
        [self.networkIndicator startAnimating];
    }
}

-(void)modelWasUpdated:(NSNotification *)aNotication
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.fetchedResultsController.managedObjectContext mergeChangesFromContextDidSaveNotification:aNotication];
    }];
}

-(void)scrollToSelectedTime:(bool)animated
{
    NSArray *workouts = self.fetchedResultsController.fetchedObjects;
    if ( workouts.count == 0 ) return;

    NSInteger scrollToIndex = -1;
    for ( CSWWorkout *workout in workouts ) {
        if ( workout.time.integerValue >= self.selectedTime.asInt ) {
            scrollToIndex = [workouts indexOfObject:workout];
            break;
        }
    }
    
    if ( scrollToIndex == -1 ) {
        scrollToIndex = [self.fetchedResultsController indexPathForObject:workouts.lastObject].row;
    }
    
    [self.scheduleTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:scrollToIndex inSection:0]
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:animated
     ];
}

-(void)updateWodButtonState
{
    if ( _wodBarButton ) {
        
        CSWWod *wod = [CSWWod wodWithDay:self.selectedDay withMoc:self.managedObjectContext];
        
        if ( wod && wod.wodDesc && ![wod.wodDesc isEqualToString:@""] ) {
            
            self.wodViewController.content = wod.wodDesc;
            _wodLabel.textColor = [UIColor whiteColor];
            _wodBarButton.enabled = true;
            
        } else {
            
            _wodBarButton.enabled = false;
            _wodLabel.textColor = [UIColor grayColor];
        }
    }
}

-(void)configPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)nowPressed:(id)sender
{
    CSWDay *today = [CSWDay dayWithDate:[NSDate date]];
    
    UIViewAnimationOptions transition;

    if ( self.selectedDay.asInt == today.asInt ) {
        transition = UIViewAnimationOptionTransitionNone;
    } else if ( self.selectedDay.asInt > today.asInt ) {
        transition = UIViewAnimationOptionTransitionFlipFromLeft;
    } else {
        transition = UIViewAnimationOptionTransitionFlipFromRight;
    }
    
    [self setSelectedTimeToNow];
    
    [UIView transitionWithView:self.dateLabel
                      duration:0.2
                       options:transition
                    animations:^{
                        [self updateDateLabel];
                    }
                    completion:nil
     ];
    
    [UIView transitionWithView:self.scheduleTableView
                      duration:0.2
                       options:transition
                    animations:^{
                        [self focusOnSelectedDateAndTime:true];
                    }
                    completion:nil
     ];
}

-(void)wodPressed:(id)sender
{
    CSWWod *wod = [CSWWod wodWithDay:self.selectedDay withMoc:self.managedObjectContext];

    self.wodViewController.content = wod.wodDesc;
    self.wodViewController.dateString = self.dateLabel.text;
    
    [self presentViewController:self.wodViewController
                       animated:TRUE
                     completion:nil
     ];
}

-(void)updateFilteringText
{
    if ( self.filterViewController.activeFilterType == CSWFilterTypeNoFilter ) {
        
        _filterBarButtonLabel.textColor = [UIColor whiteColor];
        self.filteringLabel.text = @"";
        
    } else {
        
        _filterBarButtonLabel.textColor = [UIColor redColor];
        
        NSString *displayName, *type;
        if ( self.filterViewController.activeFilterType == CSWFilterTypeInstructor ) {
            displayName = [self.filterViewController.filterInstructor displayName];
            type = @"instructor";
        } else {
            displayName = [self.filterViewController.filterLocation displayName];
            type = @"location";
        }
        
        self.filteringLabel.text = [NSString stringWithFormat:@"showing only %@: %@", type, displayName];
    }
}

-(void)filterPressed:(id)sender
{
    CGRect winRect = [UIScreen mainScreen].bounds;
   
    if ( !_blackoutButton ) {
        _blackoutButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _blackoutButton.frame = winRect;
        _blackoutButton.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.0];
        [_blackoutButton addTarget:self action:@selector(dismissFilterViewController:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.navigationController.view addSubview:_blackoutButton];
    
    CGFloat screenHeight = winRect.size.height;
    
    [self.navigationController addChildViewController:self.filterViewController];
    [self.navigationController.view addSubview:self.filterViewController.view];
    self.filterViewController.view.frame = CGRectMake(0,screenHeight,320,256);

    [self.filterViewController prepareView];

    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.filterViewController.view.frame = CGRectMake(0,screenHeight-256,320,256);
                         _blackoutButton.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.75];
                     }
                     completion:nil
     ];
}


-(void)handleSignupRequest
{
    NSString *opDesc, *purpose;
    
    switch( (int)selectedWorkoutQueryType ) {
            
        case WorkoutQueryTypeSignup:
            opDesc = @"signup";
            purpose = @"signedUp";
            break;
        case WorkoutQueryTypeWaitlist:
            opDesc = @"waitlist";
            purpose = @"waitlisted";
            break;
        case WorkoutQueryTypeCancelSignup:
            opDesc = @"cancel";
            purpose = @"notSignedUp";
            break;
        case WorkoutQueryTypeCancelWaitlist:
            opDesc = @"cancel";
            purpose = @"notSignedUp";
            break;
    }
    
    selectedWorkout.isUpdatingToPurpose = purpose;
    
    [self.scheduleTableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    
    NSNumber *dayForSelectedWorkout = selectedWorkout.day;
    
    [self.store queryWorkout:selectedWorkout
               withQueryType:selectedWorkoutQueryType
              withCompletion:^(NSError *error) {
                  
                  [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                      
                      selectedWorkout.isUpdatingToPurpose = nil;
                      
                      // cannot refer to 'selectedCell' in the completion block because it may have been pushed offscreen and used for a different workout
                      if ( self.selectedDay.asInt == dayForSelectedWorkout.intValue
                           && [[self.scheduleTableView indexPathsForVisibleRows] containsObject:selectedIndexPath]
                         ) {
                          UITableViewCell *cell = [self.scheduleTableView cellForRowAtIndexPath:selectedIndexPath];
                          [cell.layer removeAllAnimations];
                          [self.scheduleTableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationMiddle];
                      }
                      
                      if ( error ) {
                          
                          NSString *timeDisp = [[CSWTime timeWithNumber:selectedWorkout.time] toDisplayTime12Hour];
                          NSString *ampmDisp = [[CSWTime timeWithNumber:selectedWorkout.time] toDisplayTimeAmPm];
                          NSString *message  = [NSString stringWithFormat:@"Unable to %@ for %@ %@", opDesc, timeDisp, ampmDisp];
                          
                          NSString *msg;
                          if ( error.code == kErrorCodeCannotUndo ) {
                              msg = @"This signup could not be cancelled because it begins within 60 minutes";
                          } else if ( error.code == kErrorCodeWaitlistIsFull ) {
                              msg = @"Sorry, the waitlist for this class is full";
                          } else if ( error.code == kErrorCodeUnexpectedServicerResponse ) {
                              msg = @"The response from the servicer could not be understood";
                              
                          } else {
                              msg = [error localizedDescription];
                          }
                          [[[UIAlertView alloc] initWithTitle:message
                                                      message:msg
                                                     delegate:nil
                                            cancelButtonTitle:@"ok"
                                            otherButtonTitles:nil
                            ] show];
                      }
                  }];
              }
     ];
}

-(void)updateDateLabel
{
    NSString *dateString = [gDayDateFormatter stringFromDate:[self.selectedDay toDate]];
    self.dateLabel.text = dateString;
}


//
#pragma mark CSWFilterViewControllerDelegate protocol methods
//
-(void)didSpecifyFilterItem
{
    [self updateFilteringText];
    [self focusOnSelectedDateAndTime:true];
}

-(void)dismissFilterViewController:(id)sender
{
    [self updateFilteringText];
    
    [UIView animateWithDuration:0.25 animations:^{
        _blackoutButton.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.0];
    }
                     completion:^(BOOL finished){
                         [_blackoutButton removeFromSuperview];
                     }
    ];
     
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.filterViewController.view.frame = CGRectMake(0,screenHeight,320,256);
                     }
                     completion:^(BOOL finished){
                         [self.filterViewController.view removeFromSuperview];
                         [self.filterViewController removeFromParentViewController];
                         [self focusOnSelectedDateAndTime:true];
                     }
     ];
}

//
#pragma mark UITableViewDataSource protocol methods
//
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = [self.fetchedResultsController.sections[0] numberOfObjects];
    return numberOfRows;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseId = @"CSWScheduleViewCell";
    
    CSWScheduleViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if ( !cell ) {
        [[NSBundle mainBundle] loadNibNamed:@"CSWScheduleViewCell" owner:self options:nil];
        cell = self.cell;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSWScheduleViewCell *scheduleCell = (CSWScheduleViewCell *)cell;
    
    CSWWorkout *workout = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *isUpdatingToPurpose = workout.isUpdatingToPurpose;
    if ( isUpdatingToPurpose ) {
    
        UIColor *origColorForAnimation;
        if ( [isUpdatingToPurpose isEqualToString:@"notSignedUp"] ) {
            origColorForAnimation = [CSWColors colorForPurpose:workout.isSignedUp.boolValue ? @"signedUp" : @"waitlisted"];
        } else {
            origColorForAnimation = scheduleCell.desiredBackgroundColor;
        }
        
        UIColor *isUpdatingToColor;
        if ( [workout.isUpdatingToPurpose isEqualToString:@"notSignedUp"] ) {
            isUpdatingToColor = scheduleCell.desiredBackgroundColor;
        } else {
            isUpdatingToColor = [CSWColors colorForPurpose:workout.isUpdatingToPurpose];
        }
    
        scheduleCell.backgroundColor = origColorForAnimation;
        
        [UIView animateWithDuration:0.75
                              delay:0.0
                            options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             scheduleCell.backgroundColor = isUpdatingToColor;
                         }
                         completion:nil
         ];
        
    } else if ( scheduleCell.desiredBackgroundColor ) {
        
        scheduleCell.backgroundColor = scheduleCell.desiredBackgroundColor;
        
    } else {
        
        scheduleCell.backgroundColor = [CSWColors colorForPurpose:@"notSignedUp"];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CSWWorkout *workout = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    WorkoutTimeStatus timeStatus = [self calculateWorkoutTimeStatus:workout];
    
    if ( timeStatus == WorkoutTimeStatusPast ) return;
    
    if ( !self.store.isLoggedIn ) {
        [[[UIAlertView alloc] initWithTitle:@"Must login to sign up for a class"
                                    message:@"Touch the gear icon in upper-left corner of the screen to login"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil]
         show];
        return;
    }
    
    selectedWorkout = workout;
    selectedIndexPath = indexPath;
    
    NSString *opDesc;
    if ( selectedWorkout.isSignedUp.boolValue ) {
        selectedWorkoutQueryType = WorkoutQueryTypeCancelSignup;
        opDesc = @"CANCEL my";
    } else if ( selectedWorkout.isOnWaitlist.boolValue ) {
        selectedWorkoutQueryType = WorkoutQueryTypeCancelWaitlist;
        opDesc = @"CANCEL waitlist for";
    } else if ( selectedWorkout.isFull.boolValue ) {
        selectedWorkoutQueryType = WorkoutQueryTypeWaitlist;
        opDesc = @"WAITLIST me for";
    } else {
        selectedWorkoutQueryType = WorkoutQueryTypeSignup;
        opDesc = @"Signup for";
    }
    
    CSWTime *time = [CSWTime timeWithNumber:workout.time];
    NSString *desc = [NSString stringWithFormat:@"%@\n%@\n%@", workout.displayType, workout.instructor.displayName, workout.location.displayName];
    NSString *yesTitle = [NSString stringWithFormat:@"%@ %@", opDesc, time.toDisplayTime];
    UIActionSheet *sheet = [[UIActionSheet alloc] init];
    sheet.title = desc;
    sheet.delegate = self;
    [sheet addButtonWithTitle:yesTitle];
    [sheet addButtonWithTitle:@"nevermind"];
    sheet.cancelButtonIndex = 1;
    sheet.destructiveButtonIndex = 1;
    
    [sheet showFromToolbar:self.navigationController.toolbar];
}

//
#pragma mark UIActionSheetDelegate Protocol Methods
//
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 0 ) { // do the signup

        if (    ( [self calculateWorkoutTimeStatus:selectedWorkout] == WorkoutTimeStatusFutureCannotUndo )
             && ( selectedWorkoutQueryType == WorkoutQueryTypeSignup || selectedWorkoutQueryType == WorkoutQueryTypeWaitlist )
           ) {
            
            NSString *msg = [NSString stringWithFormat:@"Because this class begins in under %d minutes, you may not be able to undo this action", [[self.store fetchGymConfigValue:@"cannotUndoWithinMins"] intValue]];
            
            [[[UIAlertView alloc] initWithTitle:@"WARNING!"
                                        message:msg
                                       delegate:self
                              cancelButtonTitle:@"nevermind"
                              otherButtonTitles:@"proceed", nil
              ] show];
            return;
            
        } else {
            
            [self handleSignupRequest];
        }
        
    } else if ( buttonIndex == 1 ) {
        // buttonIndex == 2 means "nevermind"
    }
}


////
#pragma UIAlertView Delegate protocol methods
////
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( alertView == cannotUndoAlertView ) {
        
        if ( buttonIndex == 1 ) {
            
            [self handleSignupRequest];
            
        } else if ( buttonIndex == 0 ) {
            // cancel button pressed
        }
    }
}


////
#pragma mark NSFetchedResultsControllerDelegate protocol methods
////
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.scheduleTableView beginUpdates];
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.scheduleTableView endUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.scheduleTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.scheduleTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.scheduleTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.scheduleTableView deleteRowsAtIndexPaths:@[indexPath]
                                          withRowAnimation:UITableViewRowAnimationFade
             ];
            [self.scheduleTableView insertRowsAtIndexPaths:@[newIndexPath]
                                          withRowAnimation:UITableViewRowAnimationFade
             ];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{

    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.scheduleTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.scheduleTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}



@end
