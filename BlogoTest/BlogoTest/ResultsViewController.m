//
//  ResultsViewController.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 27/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "ResultsViewController.h"
#import "TweetCell.h"

@interface ResultsViewController ()

@end

@implementation ResultsViewController

@synthesize result;

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
#pragma mark UITableViewDataSource Methods
#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.result count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *TweetCellIdentifier = @"TweetCell";
    
    NSUInteger count = [self.result count];
    
    TweetCell *cell = [tableView dequeueReusableCellWithIdentifier:TweetCellIdentifier];
    NSDictionary *tweet = (self.result)[indexPath.row];
    cell.message.text = tweet[@"text"];
    cell.message.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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

@end