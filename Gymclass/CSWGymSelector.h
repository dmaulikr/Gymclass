//
//  CSWGymSelector.h
//  Gymclass
//
//  Created by ERIC COLTON on 9/22/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CSWGymSelectorDelegate <NSObject>

@optional
-(void)dismissGymSelector:(id)sender;
-(void)longNameWasSet:(NSString *)aName;
@end

@interface CSWGymSelector : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *picker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) UIActivityIndicatorView *networkIndicator;

@property (weak, nonatomic) id<CSWGymSelectorDelegate> delegate;

@property (strong, nonatomic) NSString *selectedGymId;
@property BOOL shouldAddNewGym;

@property (strong, nonatomic) NSDictionary *configForSelectedGymId;

-(IBAction)donePressed:(id)sender;
-(void)prepareView;

@end
