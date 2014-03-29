//
//  CSWWodViewController.m
//  Gymclass
//
//  Created by ERIC COLTON on 9/8/13.
//  Copyright (c) 2013 Cindy Software. All rights reserved.
//

#import "CSWWodViewController.h"
#import "Flurry.h"

@interface CSWWodViewController ()
{
    NSString *_content;
}

@end

@implementation CSWWodViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _webView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    _webView = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *html = [NSString stringWithFormat:@"<br><br><h2>%@</h2><br>%@<br><br>", self.dateString, self.content];
    [self.webView loadHTMLString:html baseURL:nil];
}

//
#pragma mark accessor methods (public)
//

//
#pragma mark instance methods (public)
//
-(void)closePressed:(id)sender
{
    [Flurry endTimedEvent:kWodViewed withParameters:nil];
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

//
#pragma mark UIWebViewDelegate methods
//
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

@end
