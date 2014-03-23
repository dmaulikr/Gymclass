//
//  CSWWodViewController.h
//  Gymclass
//
//  Created by ERIC COLTON on 9/8/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CSWWodViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) NSString *content;
@property (strong, nonatomic) NSString *dateString;

-(IBAction)closePressed:(id)sender;

@end
