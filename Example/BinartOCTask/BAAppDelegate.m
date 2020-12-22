//
//  BAAppDelegate.m
//  BinartOCTask
//
//  Created by fallending on 08/15/2020.
//  Copyright (c) 2020 fallending. All rights reserved.
//

#import "BAAppDelegate.h"
#import <BinartOCUtility/BAUtility.h>
#import <BinartOCUtility/BAError.h>
#import <BinartOCTask/BATesla.h>

@implementation BAAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    
//    [self testRPCOnce];
//    [self testRPCRetry];
    [self testRPCRegenerate];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// MARK: -

- (void)testRPCRegenerate {
    self.regenerateCount = 15;
    NSDictionary *responseData = @{
        
        @"SEQ": @1,
        @"ACTIONID": @120,
//        @"DATA": @{ @"key": @"value" },
        @"ERROR": @"fsdfasfda" // 一旦有错误，应该立即结束
        
    };
    
    // 配置 rpc scheduler 的两个重要回调
    BARPCScheduler *sche = BARPCScheduler.defaultScheduler;
    
    sche.uniqueGenerator = ^(BAUniqueResolver resolver) {
        resolver(1);
    };
    
    sche.resultDemuxxer = ^(NSDictionary *data, BAFieldsParser parser) {
        parser(data[@"DATA"], data[@"ERROR"] ? [NSError errorWithDomain:@"AppDelegate" code:999 desc:data[@"ERROR"]] : data[@"ERROR"], [data[@"SEQ"] longLongValue]);
    };
    
    // 创建一个RPC
    BARPC *rpc = [BARPC new];
    rpc.workMode = BARPCWorkRegenerate;
    rpc.timeoutMS = 5000;
    rpc.commandId = 120;
    
    rpc.onExecute = ^(int64_t uniqueId) {
        NSLog(@"%@ running", @(uniqueId));
    };
    
    rpc.onComplete = ^(NSDictionary *data) {
        NSLog(@"a rpc received %@", data);
    };
    
    rpc.onError = ^(NSError *error) {
        NSLog(@"a rpc occurred error %@", error);
    };
    
    rpc.onTimeout = ^{
        NSLog(@"a rpc timeout");
    };
    
    rpc.onFinally = ^{
        NSLog(@"a rpc finally ended");
    };
    
    rpc.onRegenerate = ^BOOL{
        NSLog(@"a rpc regenerated %@", @(self.regenerateCount-1));
        
        return --self.regenerateCount > 0;
    };
    
    [sche postRPC:rpc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        sleep(1);

        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
        
        sleep(1);
        
        [sche recvRPC:responseData];
    });
}

- (void)testRPCRetry {
    NSDictionary *responseData = @{
        
        @"SEQ": @1,
        @"ACTIONID": @120,
        @"DATA": @{ @"key": @"value" },
//        @"ERROR": @"fsdfasfda"
        
    };
    
    // 配置 rpc scheduler 的两个重要回调
    BARPCScheduler *sche = BARPCScheduler.defaultScheduler;
    
    sche.uniqueGenerator = ^(BAUniqueResolver resolver) {
        resolver(1);
    };
    
    sche.resultDemuxxer = ^(NSDictionary *data, BAFieldsParser parser) {
        parser(data[@"DATA"], data[@"ERROR"] ? [NSError errorWithDomain:@"AppDelegate" code:999 desc:data[@"ERROR"]] : data[@"ERROR"], [data[@"SEQ"] longLongValue]);
    };
    
    // 创建一个RPC
    BARPC *rpc = [BARPC new];
    rpc.workMode = BARPCWorkRetryable;
    rpc.timeoutMS = 1000;
    rpc.commandId = 120;
    rpc.retryCount = 5;
    
    rpc.onExecute = ^(int64_t uniqueId) {
        NSLog(@"%@ running", @(uniqueId));
    };
    
    rpc.onComplete = ^(NSDictionary *data) {
        NSLog(@"a rpc received %@", data);
    };
    
    rpc.onError = ^(NSError *error) {
        NSLog(@"a rpc occurred error %@", error);
    };
    
    rpc.onTimeout = ^{
        NSLog(@"a rpc timeout");
    };
    
    rpc.onFinally = ^{
        NSLog(@"a rpc finally ended");
    };
    
    [sche postRPC:rpc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        sleep(20);
//        2020-12-22 20:55:08.073671+0800 BinartOCTask_Example[79193:816952] 1 running
//        2020-12-22 20:55:18.110513+0800 BinartOCTask_Example[79193:816947] a rpc timeout
//        2020-12-22 21:19:19.212380+0800 BinartOCTask_Example[79900:845428] a rpc finally ended

//        sleep(1);
//        2020-12-22 21:10:05.356098+0800 BinartOCTask_Example[79655:837382] 1 running
//        2020-12-22 21:10:05.367312+0800 BinartOCTask_Example[79655:837382] a rpc occurred error Error Domain=AppDelegate Code=999 "(null)" UserInfo={messagedKey=fsdfasfda}
//        2020-12-22 21:10:05.367435+0800 BinartOCTask_Example[79655:837382] a rpc finally ended
        
        sleep(3);
        
//        if (rpc.retryCount == 1) {
        [sche recvRPC:responseData];
//        }
    });
}

- (void)testRPCOnce {
    
    NSDictionary *responseData = @{
        
        @"SEQ": @1,
        @"ACTIONID": @120,
//        @"DATA": @{ @"key": @"value" },
        @"ERROR": @"fsdfasfda"
        
    };
    
    // 配置 rpc scheduler 的两个重要回调
    BARPCScheduler *sche = BARPCScheduler.defaultScheduler;
    
    sche.uniqueGenerator = ^(BAUniqueResolver resolver) {
        resolver(1);
    };
    
    sche.resultDemuxxer = ^(NSDictionary *data, BAFieldsParser parser) {
        parser(data[@"DATA"], [NSError errorWithDomain:@"AppDelegate" code:999 desc:data[@"ERROR"]], [data[@"SEQ"] longLongValue]);
    };
    
    
    // 创建一个RPC
    BARPC *rpc = [BARPC new];
    rpc.workMode = BARPCWorkOnce;
    rpc.timeoutMS = 10000;
    rpc.commandId = 120;
    
    rpc.onExecute = ^(int64_t uniqueId) {
        NSLog(@"%@ running", @(uniqueId));
    };
    
    rpc.onComplete = ^(NSDictionary *data) {
        NSLog(@"a rpc received %@", data);
    };
    
    rpc.onError = ^(NSError *error) {
        NSLog(@"a rpc occurred error %@", error);
    };
    
    rpc.onTimeout = ^{
        NSLog(@"a rpc timeout");
    };
    
    rpc.onFinally = ^{
        NSLog(@"a rpc finally ended");
    };
    
    [sche postRPC:rpc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        sleep(20);
//        2020-12-22 20:55:08.073671+0800 BinartOCTask_Example[79193:816952] 1 running
//        2020-12-22 20:55:18.110513+0800 BinartOCTask_Example[79193:816947] a rpc timeout
//        2020-12-22 21:19:19.212380+0800 BinartOCTask_Example[79900:845428] a rpc finally ended

//        sleep(1);
//        2020-12-22 21:10:05.356098+0800 BinartOCTask_Example[79655:837382] 1 running
//        2020-12-22 21:10:05.367312+0800 BinartOCTask_Example[79655:837382] a rpc occurred error Error Domain=AppDelegate Code=999 "(null)" UserInfo={messagedKey=fsdfasfda}
//        2020-12-22 21:10:05.367435+0800 BinartOCTask_Example[79655:837382] a rpc finally ended
        
        [sche recvRPC:responseData];
    });
}

@end
