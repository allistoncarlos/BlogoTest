//
//  ResultsViewController.h
//  BlogoTest
//
//  Created by Alliston Aleixo on 27/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface ResultsViewController : UITableViewController<SWTableViewCellDelegate>

@property (nonatomic, retain) UIBarButtonItem *leftButton;

@property (nonatomic, retain) NSMutableArray *result;
@property (nonatomic, retain) NSString *searchParameter;

@end