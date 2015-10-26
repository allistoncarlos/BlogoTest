//
//  ViewController.m
//  BlogoTest
//
//  Created by Alliston Aleixo on 26/10/15.
//  Copyright © 2015 Alliston Aleixo. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UILabel *recentSearchesLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self performSegueWithIdentifier:@"ShowResults" sender:self];
    [textField resignFirstResponder];
    
    return YES;
}

@end
