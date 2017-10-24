//
//  PointsVCViewController.m
//  stockPython
//
//  Created by Omar on 24/10/17.
//  Copyright © 2017 coneptum. All rights reserved.
//

#import "PointsVCViewController.h"

@interface PointsVCViewController ()
@property (weak, nonatomic) IBOutlet UIView *viewDraw;

@end

@implementation PointsVCViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void) InsertView:(UIView*) viewPoints
{
    if (viewPoints) {
        [self.viewDraw addSubview:viewPoints];
    }
}

- (IBAction)btnClose:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
