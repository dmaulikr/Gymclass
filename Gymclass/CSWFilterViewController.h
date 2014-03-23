//
//  CSWFilterViewController.h
//  Gymclass
//
//  Created by Eric Colton on 9/11/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum CSWFilterType {
     CSWFilterTypeNoFilter
    ,CSWFilterTypeInstructor
    ,CSWFilterTypeLocation
} CSWFilterType;

@protocol CSWFilterViewControllerDelegate <NSObject>

@optional
-(void)didSpecifyFilterItem;
-(void)dismissFilterViewController:(id)sender;
@end

@interface CSWFilterViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *noFilterSpecifiedLabel;

@property (weak, nonatomic) IBOutlet UIPickerView *picker;

@property (weak,nonatomic) id<CSWFilterViewControllerDelegate> delegate;

@property (assign, nonatomic) CSWFilterType activeFilterType;
@property (strong, nonatomic) id filterInstructor;
@property (strong, nonatomic) id filterLocation;

-(IBAction)donePressed:(id)sender;
-(IBAction)segControlChanged:(id)sender;

-(void)prepareView;


@end
