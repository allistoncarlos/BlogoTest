//
//  TweetCell.h
//  BlogoTest
//
//  Created by Alliston Aleixo on 27/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TweetCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *message;
@property (weak, nonatomic) IBOutlet UIImageView *profileImage;

@end