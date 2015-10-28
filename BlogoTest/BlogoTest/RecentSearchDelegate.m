//
//  RecentSearchDelegate.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 28/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "RecentSearchDelegate.h"
#import "TableDelegateProtocol.h"
#import "HomeCell.h"

#import "Constants.m"

@interface RecentSearchDelegate ()<UITableViewDataSource, UITableViewDelegate, TableDelegateProtocol>

@end

@implementation RecentSearchDelegate

#pragma mark -
#pragma mark Properties
#pragma mark -
@synthesize userDefaults;

#pragma mark -
#pragma mark Constructor
#pragma mark -
- (id)init
{
    self = [super init];
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    
    return self;
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
    NSArray* recentSearches = [self.userDefaults objectForKey:RECENT_SEARCHES_KEY];
    return [recentSearches count];
}

#pragma mark -
#pragma mark UITableViewDataSource methods
#pragma mark -
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *HomeCellIdentifier = @"HomeCell";
    
    HomeCell *cell = [tableView dequeueReusableCellWithIdentifier:HomeCellIdentifier];
            
    NSArray* recentSearches = [self.userDefaults objectForKey:RECENT_SEARCHES_KEY];
    cell.label.text = [recentSearches objectAtIndex:indexPath.row];
    
    return cell;
}
@end