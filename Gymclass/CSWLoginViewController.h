//
//  CSWLoginViewController.h
//  Gymclass
//
//  Created by ERIC COLTON on 9/20/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "CSWGymSelector.h"

@interface CSWLoginViewController : UIViewController <CSWGymSelectorDelegate, UITextFieldDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *gymLongNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectGymLabel;
@property (weak, nonatomic) IBOutlet UILabel *devWarningLabel;
@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *networkActivity;

@property (weak, nonatomic) CSWPrimaryViewController *scheduleViewController;


-(id)initForcingGymSelection:(bool)aForceSelection;
-(IBAction)skipPressed:(id)sender;
-(IBAction)loginPressed:(id)sender;
-(IBAction)logoutPressed:(id)sender;

@end

