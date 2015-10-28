//
//  TrendingTableDelegate.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 28/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "TrendingDelegate.h"
#import "TableDelegateProtocol.h"
#import "HomeCell.h"

#import "Constants.m"

@interface TrendingDelegate ()<UITableViewDataSource, UITableViewDelegate, TableDelegateProtocol>

@end

@implementation TrendingDelegate
#pragma mark -
#pragma mark Properties
#pragma mark -
@synthesize userDefaults;
@synthesize tableData;

#pragma mark -
#pragma mark UITableViewDelegate methods
#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData count];
}

#pragma mark -
#pragma mark UITableViewDataSource methods
#pragma mark -
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *HomeCellIdentifier = @"HomeCell";
    
    HomeCell *cell = [tableView dequeueReusableCellWithIdentifier:HomeCellIdentifier];
            
    NSDictionary *trendingItem = (self.tableData)[indexPath.row];
    cell.label.text = trendingItem[@"name"];
    
    return cell;
}

@end