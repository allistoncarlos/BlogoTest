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
@property (weak, nonatomic) IBOutlet UILabel *recentSearchesLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UITableView *trendingsTable;
@property (weak, nonatomic) IBOutlet UITableView *recentSearchesTable;

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
    
    self.recentSearchDelegate = [[RecentSearchDelegate alloc] init];
    self.recentSearchesTable.delegate = self.recentSearchDelegate;
    self.recentSearchesTable.dataSource = self.recentSearchDelegate;
    
    self.trendingDelegate = [[TrendingDelegate alloc] init];
    self.trendingsTable.delegate = self.trendingDelegate;
    self.trendingsTable.dataSource = self.trendingDelegate;
    
    [self getTrendingTopics];
}

- (void)viewWillAppear:(BOOL)animated {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    [self getRecentSearches];
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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

@end
