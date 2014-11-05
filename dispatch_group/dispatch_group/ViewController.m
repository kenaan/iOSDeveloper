//
//  ViewController.m
//  dispatch_group
//
//  Created by lijian on 14/11/5.
//  Copyright (c) 2014年 youku. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
{
    dispatch_group_t group;
    dispatch_semaphore_t semaphore;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    group = dispatch_group_create();
    semaphore = dispatch_semaphore_create(0);
    
////    dispatch_group_enter(group);
//    dispatch_group_async(group, dispatch_get_main_queue(), ^{
//        AVAsset *asset1 = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"system1080*1920_2" ofType:@"MOV"]]];
//        NSError *error = nil;
//        AVKeyValueStatus status =  [asset1 statusOfValueForKey:@"tracks" error:&error];
//        
//        NSLog(@"1 status:%ld, %@", status, error);
//        [asset1 loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
//            NSLog(@"1 tracks loaded");
////            dispatch_group_leave(group);
//        }];
//    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AVAsset *asset1 = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"system1080*1920_2" ofType:@"MOV"]]];
        NSError *error = nil;
        AVKeyValueStatus status =  [asset1 statusOfValueForKey:@"tracks" error:&error];
        
        NSLog(@"1 status:%ld, %@", status, error);
        [asset1 loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            NSLog(@"1 tracks loaded");
            //            dispatch_group_leave(group);
            dispatch_semaphore_signal(semaphore);
        }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });

//    dispatch_group_enter(group);
////    dispatch_group_async(group, dispatch_get_main_queue(), ^{
//        AVAsset *asset2 = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"system1080*1920" ofType:@"MOV"]]];
//        NSError *error2 = nil;
//        AVKeyValueStatus status2 =  [asset2 statusOfValueForKey:@"tracks" error:&error2];
//        
//        NSLog(@"2 status:%ld, %@", status2, error2);
//        [asset2 loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
//            NSLog(@"2 tracks loaded");
//            dispatch_group_leave(group);
//        }];
////    });
//
//    dispatch_group_enter(group);
////    dispatch_group_async(group, dispatch_get_main_queue(), ^{
//        AVAsset *asset3 = [AVAsset assetWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"system1920*1080" ofType:@"MOV"]]];
//        NSError *error3 = nil;
//        AVKeyValueStatus status3 =  [asset3 statusOfValueForKey:@"tracks" error:&error3];
//        
//        NSLog(@"3 status:%ld, %@", status3, error3);
//        [asset3 loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
//            NSLog(@"3 tracks loaded");
//            dispatch_group_leave(group);
//        }];
////    });
    
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"all loaded");
//    });
    
    NSLog(@"xxx");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
