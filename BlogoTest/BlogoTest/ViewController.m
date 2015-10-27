//
//  ViewController.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 26/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "ViewController.h"
#import <Accounts/Accounts.h>
#import <Social/Social.h>

@interface ViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *recentSearchesLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic,strong) ACAccountStore *accountStore;
@property (nonatomic,strong) NSURLConnection *connection;
@property (nonatomic,strong) NSMutableData *data;
@property (nonatomic,strong) NSMutableArray *jsonResult;

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -
#pragma mark UITextFieldDelegate Methods
#pragma mark -
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    [self doSearch:textField.text];
    
    return YES;
}

#pragma mark -
#pragma mark Twitter Search
#pragma mark -
- (void)doSearch: (NSString* ) searchParameter {
    [self.activityIndicator startAnimating];
    
    NSString *encodedQuery = [searchParameter stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    ACAccountType *accountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [self.accountStore requestAccessToAccountsWithType:accountType options:NULL completion:^(BOOL allowed, NSError *error)
     {
         if (allowed)
         {
             NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
             NSDictionary *parameters = @{@"count" : @10, @"q" : encodedQuery};
             
             SLRequest *slRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                       requestMethod:SLRequestMethodGET
                                                                 URL:url
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.data = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
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
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Atenção" message:@"Erro na autenticação com o Twitter" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alertView.message = @"Erro na autenticação com o Twitter";
        
        [alertView show];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self.activityIndicator stopAnimating];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.connection = nil;
    self.data = nil;
}
@end
