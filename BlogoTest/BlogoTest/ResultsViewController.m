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
@synthesize searchParameter;
@synthesize leftButton;

#pragma mark -
#pragma mark View methods
#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = NO;
    [self setTitle:searchParameter];
    
    // Cria o LeftButton com imagem de busca
    leftButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Icon_search_small"] style:UIBarButtonItemStylePlain target:self action:@selector(back:)];
    leftButton.title = @"";
    leftButton.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = leftButton;
    
    // Seta a cor da NavigationBar
    UIColor* bg = [UIColor colorWithRed:94.0/255.0 green:159.0/255.0 blue:202.0/255.0 alpha:0];
    [self.navigationController.navigationBar setBarTintColor:bg];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) back:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UITableViewDelegate Methods
#pragma mark -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.result count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 165;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"TweetCell";
    
    TweetCell *cell = (TweetCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Add utility buttons
    NSMutableArray *leftUtilityButtons = [NSMutableArray new];
    
    UIImage* backgroundCellImage = [UIImage imageNamed:@"cell_pattern"];
    UIColor* backgroundCellColor = [UIColor colorWithPatternImage:backgroundCellImage];

    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor title:@""];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor title:@""];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor icon:[UIImage imageNamed:@"botao_generico_on"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor title:@""];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor icon:[UIImage imageNamed:@"botao_generico_off"]];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor title:@""];
    [leftUtilityButtons sw_addUtilityButtonWithColor: backgroundCellColor title:@""];
    
    cell.leftUtilityButtons = leftUtilityButtons;
    cell.delegate = self;
    
    // Configure the cell...
    NSDictionary *tweet = (self.result)[indexPath.row];
    cell.message.text = tweet[@"text"];
    
    NSDictionary* user = tweet[@"user"];
    cell.username.text = user[@"name"];
    
    // Carrega a imagem de maneira assíncrona
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        NSString* imageProfileUrl = user[@"profile_image_url"];

        NSData * data = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: imageProfileUrl]];

        if (data != nil )
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.profileImage.image = [UIImage imageWithData: data];
                
                cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width / 2;
                cell.profileImage.clipsToBounds = YES;
             });
    });

    
    return cell;
}

#pragma mark -
#pragma mark SWTableViewCellDelegate methods
#pragma mark -
- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerLeftUtilityButtonWithIndex:(NSInteger)index {
    TweetCell* tweetCell = (TweetCell*)cell;
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[tweetCell.message.text] applicationActivities:nil];
    
    NSArray *excludeActivities = @[UIActivityTypePostToWeibo,
                                   UIActivityTypeMessage,
                                   UIActivityTypeMail,
                                   UIActivityTypePrint,
                                   UIActivityTypeCopyToPasteboard,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo,
                                   UIActivityTypePostToTencentWeibo,
                                   UIActivityTypeAirDrop];
    
    activityVC.excludedActivityTypes = excludeActivities;
    
    activityVC.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:activityVC animated:YES completion:nil];
}

@end