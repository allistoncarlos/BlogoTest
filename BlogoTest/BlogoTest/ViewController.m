//
//  ViewController.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 26/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "ViewController.h"
#import "ResultsViewController.h"
#import "Operation.m"
#import "HomeCell.h"

#import "NSMutableArray+Queue.h"
#import "Constants.m"

#import "TrendingDelegate.h"
#import "RecentSearchDelegate.h"

#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()<UITextFieldDelegate>

#pragma mark -
#pragma mark Outlets
#pragma mark -
@property (weak, nonatomic) IBOutlet UIImageView *twitterLogo;
@property (weak, nonatomic) IBOutlet UILabel *recentSearchesLabel;
@property (weak, nonatomic) IBOutlet UILabel *trendingsLabel;
@property (weak, nonatomic) IBOutlet UIView *recentSearchesBar;
@property (weak, nonatomic) IBOutlet UIView *trendingsBar;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *trendingsTable;
@property (weak, nonatomic) IBOutlet UITableView *recentSearchesTable;
@property (weak, nonatomic) IBOutlet UIImageView *searchIcon;
@property (weak, nonatomic) IBOutlet UIView *searchGroup;

#pragma mark -
#pragma mark Properties
#pragma mark -
@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) NSURLConnection *connection;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSMutableArray *jsonResult;
@property (nonatomic,strong) NSMutableArray *trendingResult;
@property (nonatomic,strong) NSString *searchParameter;
@property (nonatomic,strong) NSUserDefaults *userDefaults;

@property (nonatomic,strong) RecentSearchDelegate *recentSearchDelegate;
@property (nonatomic,strong) TrendingDelegate *trendingDelegate;

@property (nonatomic,assign) Operation operation;

@end

@implementation ViewController
#pragma mark -
#pragma mark Private Fields
#pragma mark -
CGRect searchFieldOriginalFrame;


#pragma mark -
#pragma mark Account Store
#pragma mark -
- (ACAccountStore *)accountStore
{
    if (_accountStore == nil)
    {
        _accountStore = [[ACAccountStore alloc] init];
    }
    
    return _accountStore;
}


#pragma mark -
#pragma mark View methods
#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    searchFieldOriginalFrame = self.searchField.frame;
    
    self.recentSearchDelegate = [[RecentSearchDelegate alloc] init];
    self.recentSearchesTable.delegate = self.recentSearchDelegate;
    self.recentSearchesTable.dataSource = self.recentSearchDelegate;
    
    if (!IS_IPHONE) {
        // Carrega os Trending Topics somente no iPad
        self.trendingDelegate = [[TrendingDelegate alloc] init];
        self.trendingsTable.delegate = self.trendingDelegate;
        self.trendingsTable.dataSource = self.trendingDelegate;
        
        //[self getTrendingTopics];
    }
    else {
        // Operação de resign do teclado somente no iPhone
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                       initWithTarget:self
                                       action:@selector(dismissKeyboard)];
        
        [self.view addGestureRecognizer:tap];
    }
    
    [self adjustLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self getRecentSearches];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self adjustLayout];
}

#pragma mark -
#pragma mark Segue Preparation
#pragma mark -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"ShowResults"]) {
        NSArray *recentSearchesInmutable = [self.userDefaults objectForKey:RECENT_SEARCHES_KEY];
        NSMutableArray *recentSearches = [[NSMutableArray alloc] initWithArray:recentSearchesInmutable];
        
        if ([recentSearches count] == 5) {
            [recentSearches dequeue];
        }
        
        [recentSearches enqueue:self.searchParameter];
        
        [self.userDefaults setObject:recentSearches forKey:RECENT_SEARCHES_KEY];
        
        ResultsViewController* resultVC = segue.destinationViewController;
        resultVC.result = self.jsonResult;
        resultVC.searchParameter = self.searchParameter;
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods
#pragma mark -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    self.searchParameter = textField.text;
    [self doSearch];
    
    return YES;
}

#pragma mark -
#pragma mark Keyboard Resize Methods
#pragma mark -
static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat MINIMUM_SCROLL_FRACTION = 0.2;
static const CGFloat MAXIMUM_SCROLL_FRACTION = 0.8;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 216;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 252;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT_IPHONE = 186;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT_IPHONE = 152;

CGFloat animatedDistance;

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    [self keyboardVisibilityChanged:YES];
    
    CGRect textFieldRect = [self.view.window convertRect:textField.bounds fromView:textField];
    CGRect viewRect = [self.view.window convertRect:self.view.bounds fromView:self.view];
    CGFloat midline = textFieldRect.origin.y + 0.5 * textFieldRect.size.height;
    CGFloat numerator = midline - viewRect.origin.y - MINIMUM_SCROLL_FRACTION * viewRect.size.height;
    CGFloat denominator = (MAXIMUM_SCROLL_FRACTION - MINIMUM_SCROLL_FRACTION) * viewRect.size.height;
    CGFloat heightFraction = numerator / denominator;
    
    if (heightFraction < 0.0)
    {
        heightFraction = 0.0;
    }
    else if (heightFraction > 1.0)
    {
        heightFraction = 1.0;
    }
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (!IS_IPHONE) {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT * heightFraction);
        else
            animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT * heightFraction);
    }
    else {
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            animatedDistance = floor(PORTRAIT_KEYBOARD_HEIGHT_IPHONE * heightFraction);
        else
            animatedDistance = floor(LANDSCAPE_KEYBOARD_HEIGHT_IPHONE * heightFraction);
    }

    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y -= animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textfield{
    
    CGRect viewFrame = self.view.frame;
    viewFrame.origin.y += animatedDistance;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:KEYBOARD_ANIMATION_DURATION];
    
    [self.view setFrame:viewFrame];
    
    [self keyboardVisibilityChanged:NO];
    
    [UIView commitAnimations];
}

#pragma mark -
#pragma mark Connection Methods
#pragma mark -
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    switch (self.operation)
    {
        case TrendingLoad:
            [self trendingTopicsLoaded];
            break;
        case TimelineLoad:
            [self timelineLoaded];
            break;
        default:
            break;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    self.data = nil;
}

#pragma mark -
#pragma mark Private Methods
#pragma mark -
- (void)doSearch {
    [self.activityIndicator startAnimating];
    self.operation = TimelineLoad;
    
    NSString *encodedQuery = [self.searchParameter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType options:NULL completion:^(BOOL allowed, NSError *error)
     {
         if (allowed)
         {
             NSURL *timelineUrl = [NSURL URLWithString:TIMELINE_URL];
             NSDictionary *parameters = @{@"count" : @10, @"q" : encodedQuery};
             
             SLRequest *slRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:timelineUrl
                                                          parameters:parameters];
             
             NSArray *accounts = [self.accountStore accountsWithAccountType:accountType];
             slRequest.account = [accounts lastObject];
             NSURLRequest *request = [slRequest preparedURLRequest];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
             });
         }
     }];
}

- (void)getTrendingTopics {
    [self.activityIndicator startAnimating];
    self.operation = TrendingLoad;
    
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType options:NULL completion:^(BOOL allowed, NSError *error)
     {
         if (allowed) {
             // Worldwide trending topics
             NSURL *timelineUrl = [NSURL URLWithString:TRENDINGS_URL];
             
             SLRequest *slRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:timelineUrl
                                                          parameters:nil];
             
             NSArray *accounts = [self.accountStore accountsWithAccountType:accountType];
             slRequest.account = [accounts lastObject];
             NSURLRequest *request = [slRequest preparedURLRequest];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
                 [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
             });
         }
     }];
}

- (void)getRecentSearches {
    NSMutableArray* recentSearches = [self.userDefaults objectForKey:RECENT_SEARCHES_KEY];
    
    if (recentSearches == nil) {
        recentSearches = [[NSMutableArray alloc] init];
        [self.userDefaults setObject:recentSearches forKey:RECENT_SEARCHES_KEY];
    }
    
    [self.recentSearchesTable reloadData];
}

- (void) timelineLoaded {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    
    NSError *jsonParsingError = nil;
    NSDictionary *jsonResults = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonParsingError];
    
    self.jsonResult = jsonResults[@"statuses"];
    
    [self.activityIndicator stopAnimating];
    
    if ([self.jsonResult count] != 0)
    {
        self.data = nil;
        
        [self performSegueWithIdentifier:@"ShowResults" sender:self];
    }
    else {
        NSArray* errorsArray = jsonResults[@"errors"];
        NSDictionary* errorMessage = [errorsArray objectAtIndex:0];
        NSString* message = errorMessage[@"message"];
        
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Atenção" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        
        [alertView show];
    }
}

- (void) trendingTopicsLoaded {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    
    NSError *jsonParsingError = nil;
    NSArray *jsonResults = [NSJSONSerialization JSONObjectWithData:self.data options:0 error:&jsonParsingError];
    NSDictionary* trendingResult = [jsonResults objectAtIndex:0];
    
    self.trendingDelegate.tableData = trendingResult[@"trends"];
    
    self.trendingsTable.delegate = self.trendingDelegate;
    self.trendingsTable.dataSource = self.trendingDelegate;
    
    [self.trendingsTable reloadData];
    
    [self.activityIndicator stopAnimating];
}

- (void) adjustLayout {
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation);
    
    if (IS_IPHONE) {
        if (!isPortrait) {
            // Landscape iPhone
            self.recentSearchesLabel.hidden = YES;
            self.recentSearchesBar.hidden = YES;
            self.recentSearchesTable.hidden = YES;
        } else {
            // Portrait iPhone
            self.recentSearchesLabel.hidden = NO;
            self.recentSearchesBar.hidden = NO;
            self.recentSearchesTable.hidden = NO;
        }
    }
    else {
        if (!isPortrait) {
            // Landscape iPad
            self.recentSearchesLabel.hidden = YES;
            self.recentSearchesBar.hidden = YES;
            self.recentSearchesTable.hidden = YES;
            
            self.trendingsLabel.hidden = YES;
            self.trendingsBar.hidden = YES;
            self.trendingsTable.hidden = YES;
        }
        else {
            // Portrait iPad
            self.recentSearchesLabel.hidden = NO;
            self.recentSearchesBar.hidden = NO;
            self.recentSearchesTable.hidden = NO;
            
            self.trendingsLabel.hidden = NO;
            self.trendingsBar.hidden = NO;
            self.trendingsTable.hidden = NO;
        }
    }
}

- (void) keyboardVisibilityChanged: (BOOL)isVisible {
    BOOL isPortrait = UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation);
    
    if (!IS_IPHONE) {
        // iPad
        if (isPortrait) {
            self.trendingsTable.hidden = isVisible;
            self.trendingsLabel.hidden = isVisible;
            self.trendingsBar.hidden = isVisible;
            
            self.recentSearchesTable.hidden = isVisible;
            self.recentSearchesLabel.hidden = isVisible;
            self.recentSearchesBar.hidden = isVisible;
        }
        else {
            self.trendingsTable.hidden = YES;
            self.trendingsLabel.hidden = YES;
            self.trendingsBar.hidden = YES;
            
            self.recentSearchesTable.hidden = YES;
            self.recentSearchesLabel.hidden = YES;
            self.recentSearchesBar.hidden = YES;
        }
        
        CGRect searchGroupOriginalFrame = CGRectMake(0, 491, self.searchGroup.frame.size.width, self.searchGroup.frame.size.height);
        CGRect searchGroupModifiedFrame = CGRectMake(0, 512, self.searchGroup.frame.size.width, self.searchGroup.frame.size.height);
        
        self.searchGroup.frame = isVisible ? searchGroupModifiedFrame : searchGroupOriginalFrame;
        
        CGRect searchIconOriginalFrame = CGRectMake(185, self.searchIcon.frame.origin.y, self.searchIcon.frame.size.width, self.searchIcon.frame.size.height);
        CGRect searchIconModifiedFrame = CGRectMake(55, self.searchIcon.frame.origin.y, self.searchIcon.frame.size.width, self.searchIcon.frame.size.height);
        
        self.searchIcon.frame = isVisible ? searchIconModifiedFrame : searchIconOriginalFrame;
        
        CGRect searchFieldModifiedFrame = CGRectMake(165, 18, self.searchField.frame.size.width, 74);
        self.searchField.frame = isVisible ? searchFieldModifiedFrame : searchFieldOriginalFrame;
        
        CGFloat twitterLogoYOffset;
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
            twitterLogoYOffset = 165 + PORTRAIT_KEYBOARD_HEIGHT;
        else
            twitterLogoYOffset = 165 + LANDSCAPE_KEYBOARD_HEIGHT;
        
        CGRect twitterLogoOriginalFrame = CGRectMake(302, 165, 165, 135);
        CGRect twitterLogoModifiedFrame = CGRectMake(0, twitterLogoYOffset, self.twitterLogo.frame.size.width, self.twitterLogo.frame.size.height);
        
        [self.twitterLogo setFrame:isVisible ? twitterLogoModifiedFrame : twitterLogoOriginalFrame];
    } else {
        // iPhone
        if (isPortrait)
            self.recentSearchesLabel.hidden = isVisible;
        else
            self.recentSearchesLabel.hidden = YES;
    }
}

-(void)dismissKeyboard {
    [self.searchField resignFirstResponder];
}
@end
