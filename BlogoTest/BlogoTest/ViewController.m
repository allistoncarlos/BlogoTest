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

#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *recentSearchesLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) NSURLConnection *connection;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSMutableArray *jsonResult;
@property (nonatomic,strong) NSMutableArray *trendingResult;

@property (nonatomic,strong) NSString *searchParameter;
@property (nonatomic,assign) Operation operation;

@property (weak, nonatomic) IBOutlet UITableView *trendingsTable;

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
    
    [self getTrendingTopics];
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark Segue Preparation
#pragma mark -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"ShowResults"]) {
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
#pragma mark Twitter Search
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
             NSURL *timelineUrl = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
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
             NSURL *timelineUrl = [NSURL URLWithString:@"https://api.twitter.com/1.1/trends/place.json?id=1"];
             
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
#pragma mark UITableViewDelegate methods
#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *HomeCellIdentifier = @"HomeCell";
    
    HomeCell *cell = [tableView dequeueReusableCellWithIdentifier:HomeCellIdentifier];
    
    if (self.operation == TrendingLoad) {
        NSDictionary *trendingItem = (self.trendingResult)[indexPath.row];
        cell.label.text = trendingItem[@"name"];
    } else {
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row & 1)
    {
        cell.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
}


#pragma mark -
#pragma mark Private Methods
#pragma mark -
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
    
    
    self.trendingResult = trendingResult[@"trends"];
    [self.trendingsTable reloadData];
    
    [self.activityIndicator stopAnimating];
}
@end
