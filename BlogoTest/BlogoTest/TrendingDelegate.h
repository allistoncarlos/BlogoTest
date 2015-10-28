//
//  TrendingTableDelegate.h
//  BlogoTest
//
//  Created by Alliston Aleixo on 28/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TrendingDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,strong) NSMutableArray *tableData;

@end