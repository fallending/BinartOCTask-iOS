# BinartOCTask

[![CI Status](https://img.shields.io/travis/fallending/BinartOCTask.svg?style=flat)](https://travis-ci.org/fallending/BinartOCTask)
[![Version](https://img.shields.io/cocoapods/v/BinartOCTask.svg?style=flat)](https://cocoapods.org/pods/BinartOCTask)
[![License](https://img.shields.io/cocoapods/l/BinartOCTask.svg?style=flat)](https://cocoapods.org/pods/BinartOCTask)
[![Platform](https://img.shields.io/cocoapods/p/BinartOCTask.svg?style=flat)](https://cocoapods.org/pods/BinartOCTask)

* Core 高可用基础类
* Event 事件总线
* Scheduler 调度器
  * TimeScheduler 时间调度：1秒后执行一次、每5秒执行一次、每1秒在什么条件下执行一次、每1秒执行一次共5次，等
  * TaskScheduler 任务调度：常规任务调度器

## Requirements

## Installation

BinartOCTask is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BinartOCTask'
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

### Scheduler

#### RPC Scheduler

> 为了让长连接的指令交互能像http REP/RES 这样调用，所以有了它

 * 单次收发

```objc
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
```
 
 * 可重试收发
 
```objc
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
```
 
 * 可再生收发（一般用于多次触发，且触发条件需要依赖上一次应答来计算得出）
 
```objc
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
```

## Author

fallending, fengzilijie@qq.com

## License

BinartOCTask is available under the MIT license. See the LICENSE file for more info.
