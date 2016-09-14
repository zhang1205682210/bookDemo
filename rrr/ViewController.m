//
//  ViewController.m
//  rrr
//
//  Created by  张晓宇 on 16/7/15.
//  Copyright © 2016年 SH. All rights reserved.
//

#import "ViewController.h"
#import "LSYReadViewController.h"
#import "LSYReadPageViewController.h"
#import "LSYReadUtilites.h"
#import "LSYReadModel.h"
@interface ViewController ()
@property (nonatomic,strong) UIActivityIndicatorView * activity;
@property (nonatomic,strong) UIActivityIndicatorView * epubActivity;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createUI];
    _activity.hidesWhenStopped = YES;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"1111"]];
}
-(void)createUI
{
    UIButton * btn1 = [UIButton buttonWithType:UIButtonTypeSystem];
    btn1.frame = CGRectMake(self.view.frame.size.width / 2 - 50, 100, 100, 50);
    [btn1 setTitle:@"one book" forState:UIControlStateNormal];
    btn1.backgroundColor = [UIColor grayColor];
    [btn1 addTarget:self action:@selector(btn1:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
}
-(void)btn1:(UIButton *)btn1
{
//    [_activity startAnimating];
// 
//    LSYReadPageViewController *pageView = [[LSYReadPageViewController alloc] init];
//    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"mdjyml"withExtension:@"txt"];
//    pageView.resourceURL = fileURL;    //文件位置
//    
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        
//        pageView.model = [LSYReadModel getLocalModelWithURL:fileURL];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [_activity stopAnimating];
//          
//            
//            [self presentViewController:pageView animated:YES completion:nil];
//        });
//    });
//    
    
    
    [_epubActivity startAnimating];
//    [_beginEpub setTitle:@"" forState:UIControlStateNormal];
//    [_beginEpub setEnabled:NO];
    LSYReadPageViewController *pageView = [[LSYReadPageViewController alloc] init];
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"未来边缘" withExtension:@"epub"];
    pageView.resourceURL = fileURL;    //文件位置
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        pageView.model = [LSYReadModel getLocalModelWithURL:fileURL];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_epubActivity stopAnimating];
//            [_beginEpub setTitle:@"Beign epub Read" forState:UIControlStateNormal];
//            [_beginEpub setEnabled:YES];
//            
            [self presentViewController:pageView animated:YES completion:nil];
        });
    });
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
