#import <BinartOCUtility/BAError.h>
#import "BARPCScheduler.h"

#undef  IS_MAIN
#define IS_MAIN                          [NSThread isMainThread]

#undef  WEAKLY
#define WEAKLY( value ) __unused __weak typeof(value) _ = value;

#undef  WEAKIFY
#define WEAKIFY( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    autoreleasepool{} __weak __typeof__(x) __weak_##x##__ = x; \
    _Pragma("clang diagnostic pop")

#undef  STRONGIFY
#define STRONGIFY( x ) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    try{} @finally{} __typeof__(x) x = __weak_##x##__; \
    _Pragma("clang diagnostic pop")

#undef  DELAY // timeout ms
#define DELAY(timeout, block) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), block);

// 信号量实现简单的异步转同步
#undef  SYNC_INIT
#define SYNC_INIT dispatch_semaphore_t sema = dispatch_semaphore_create(0);

#undef  SYNC_WAIT
#define SYNC_WAIT dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

#undef  SYNC_SEND
#define SYNC_SEND dispatch_semaphore_signal(sema);

/// 当前方法名称
#undef  SEL_NAME
#define SEL_NAME NSStringFromSelector(_cmd)
#define METHOD_NAME SEL_NAME

/// 属性已过期
#undef  DEPRECATED_PROP
#define DEPRECATED_PROP __attribute__((deprecated("属性已过期")))

// 标记这个属性已过期
//@property (nonatomic, copy) NSString *name __attribute__((deprecated("属性已过期")));
//
//// 标记方法已过期
//- (void)testOld __attribute__((deprecated("方法已过期, 请使用 test2"))) {
//
//}

/// 方法已过期
#undef  DEPRECATED_SEL
#define DEPRECATED_SEL() __attribute__((deprecated("方法已过期")))

// https://cloud.tencent.com/developer/article/1400469
// 可以自定义描述信息
//__attribute__((deprecated("已过期!"))) // 编译警告
// 系统的宏定义
//DEPRECATED_ATTRIBUTE

// 可以自定义描述信息
//__attribute__((unavailable("已经废弃,请使用 xxxx"))) // 编译报错
// 系统宏定义
//NS_UNAVAILABLE;
//UNAVAILABLE_ATTRIBUTE;

@interface BARPC ()

@property (readonly) BOOL isTimeout;
@property (assign) int64_t startAtMS;

@property (weak) BARPCScheduler *currentScheduler;

@end


@implementation BARPC

// MARK: - Private

- (instancetype)init {
    if (self = [super init]) {
        _timeoutMS = 5000; // 5 S
        _retryCount = 0;
        _workMode = BARPCWorkOnce;
        
    }
    
    return self;
}

- (void)setOnComplete:(BARPCCompleteBlock)onComplete {

    if (!onComplete) return;

    if (_workMode == BARPCWorkRegenerate) {
        @WEAKIFY(self)
        _onComplete = ^(NSDictionary *data) {
            @STRONGIFY(self)

            // 现调用原有onComplete，让外部充分计算，产生再生条件
            INVOKE_BLOCK(onComplete, data)
            
            if (self->_onRegenerate && self->_onRegenerate()) {
                // 确认再生
                [self.currentScheduler postRPC:self];
            } else {
                INVOKE_BLOCK_VOID(self->_onFinally)
            }
            
        };
    } else {
        _onComplete = onComplete;
    }
}

- (void)setOnTimeout:(BARPCTimeoutBlock)onTimeout {
    if (!onTimeout) return;
    
    if (_workMode == BARPCWorkRetryable) {
        @WEAKIFY(self)
        _onTimeout = ^() {
            @STRONGIFY(self)
            if (self.retryCount > 0 || self.retryCount == -1) {
                // 超时通知
                INVOKE_BLOCK_VOID(onTimeout) // timeout once, but still post again
                
                // 重试计算
                if (self.retryCount > 0) {
                    --self.retryCount;
                }
                
                // 执行重试
                [self.currentScheduler postRPC:self];
            } else { // 整体超时
                // 超时通知
                INVOKE_BLOCK_VOID(onTimeout)
                
                // 调用结束
                INVOKE_BLOCK_VOID(self.onFinally)
            }
            
        };
    } else {
        _onTimeout = onTimeout;
    }
}

// MARK: - Protected Methods

- (BOOL)isTimeout {
    int64_t currentTimestamp = (int64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    return self.timeoutMS > 0
            && (currentTimestamp - self.startAtMS) > self.timeoutMS;
}

- (void)beforePost:(int64_t)uniqueId {
    self.uniqueId = uniqueId;
}

- (void)beforeExecute {
    self.startAtMS = (int64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
}

@end

//@implementation BARetryTask

//- (void)setTimeoutCallback:(BABlock)timeoutCallback {
//    @WEAKIFY(self)
//    BABlock callback = ^(void) {
//        @STRONGIFY(self)
//        [self superTimeoutCallback];
//        if (self.retry > 0 || self.retry == -1) {
//            if (self.retry > 0) {
//                --self.retry;
//            }
//            [BATaskScheduler.shared postNewAction:self];
//        } else {
//            if (self.finallyTimeoutCallback) {
//                self.finallyTimeoutCallback();
//            }
//        }
//
//    };
//
//    [super setTimeoutCallback:callback];
//}
//
//- (void)setErrorCallback:(BAErrorBlock)errorCallback {
//    @WEAKIFY(self)
//    BAErrorBlock callback = ^(NSError *error) {
//        @STRONGIFY(self)
//        if (self->_retry > 0 || self->_retry == -1) {
//            if (self->_retry > 0) {
//                --self->_retry;
//            }
//            int64_t remaining = self->_timeout - self.startAtMS;
//            if (remaining <= 0) {
//                [BATaskScheduler.shared postNewAction:self];
//            } else {
//                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(remaining / 1000 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                    [BATaskScheduler.shared postNewAction:self];
//                });
//            }
//        } else {
//            self.finallyErrorCallback(error);
//        }
//    };
//
//    [super setErrorCallback:callback];
////    _errorCallback = [callback copy];
//}
//
//- (void)superTimeoutCallback {
//    if (super.timeoutCallback) {
//        super.timeoutCallback();
//    }
//}
//
//- (void)superSetTimeoutCallback {
//    if (super.timeoutCallback) {
//        super.timeoutCallback();
//    }
//}

//@end


// MARK: -

@interface BARPCScheduler () {
    NSMutableDictionary<NSNumber *, BARPC *> *_waitings; // 优先级队列, uniqueId -> RPC
    NSMutableDictionary<NSNumber *, BARPC *> *_runnings;
}

@property (atomic, assign) BARPCSchedulerState state;

@SINGLETON(BARPCScheduler)

@end

@implementation BARPCScheduler

@DEF_SINGLETON(BARPCScheduler)

- (instancetype)init {
    self = [super init];
    if (self) {
        _waitings = [@{} mutableCopy];
        _runnings = [@{} mutableCopy];
        _sleepInterval = 1.0f;
        _state = BARPCSchedulerStateInit;
        
        [self start];
    }
    return self;
}

// MARK: - Public

+ (BARPCScheduler *)defaultScheduler {
    return BARPCScheduler.shared;
}

- (void)start {
    self.state = BARPCSchedulerStateStart;
    
    [NSThread detachNewThreadSelector:@selector(workloop)
                             toTarget:self
                           withObject:nil];
}

- (void)pause {
    self.state = BARPCSchedulerStatePause;
}

- (void)stop {
    self.state = BARPCSchedulerStateInit;
}

- (void)workloop {
    while (self.state > 0) {
        [NSThread sleepForTimeInterval:self.sleepInterval];
        
        if (self.state > BARPCSchedulerStateStart) {
            continue;
        }

        @synchronized (self) {
            // 1. 检查执行队列，是否有超时任务
            if (_runnings.count > 0) {
                for (NSNumber *key in _runnings.allKeys) {
                    BARPC *rpc = _runnings[key];
                    
                    if (rpc.isTimeout) {
                        [_runnings removeObjectForKey:key];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            
                            if (rpc.onTimeout) {
                                INVOKE_BLOCK(rpc.onTimeout)
                            }
                            
                            // 如果是单次模式或再生模式(非重试模式)，则直接结束
                            if (rpc.workMode != BARPCWorkRetryable) {
                                INVOKE_BLOCK(rpc.onFinally)
                            }
                            
                        });
                    }
                }
            }
            
            // 2. 查找执行队列中rpc的优先级
            BARPCPriority currentRunningPriority = BARPCPriorityNormal;
            for (BARPC *rpc in _runnings.allValues) {
                if (rpc.priority > currentRunningPriority) {
                    currentRunningPriority = rpc.priority;
                }
            }
            
            // 3. 有高优先级执行rpc，如果有，跳过等待队列
            if (currentRunningPriority > BARPCPriorityNormal) { // FIXME: 当前未对等待队列，采取根据优先级重排措施！！
                continue;
            }
            
            // 4. 尝试从等待队列中，取出一个做处理
            if (_waitings.count > 0) {
                NSNumber *key = _waitings.allKeys.firstObject;
                BARPC *rpc = _waitings[key];
                
                // 判断running里面是否有该commandid的rpc
                BOOL findEquallyCommandRPC = NO;
                if (rpc.commandId>0) {
                    for (BARPC *r in _runnings.allValues) {
                        if (r.commandId == rpc.commandId) {
                            findEquallyCommandRPC = YES;
                            
                            if (r.priority >= rpc.priority) {
                                // runnings里面已经存在该commandId，踢掉新增
                                INVOKE_BLOCK(rpc.onCancel)
                                
                                INVOKE_BLOCK(rpc.onFinally)
                                
                                // 将低优先级从等待队列删除
                                [_waitings removeObjectForKey:@(rpc.uniqueId)];
                            } else {
                                INVOKE_BLOCK(r.onInterrupt)
                                
                                INVOKE_BLOCK(r.onFinally)
                                
                                // 中断当前运行的低优先级
                                [_runnings removeObjectForKey:@(r.uniqueId)];
                                
                                // 将高优先级放入运行队列并执行
                                [_runnings setObject:rpc forKey:@(rpc.uniqueId)];
                                
                                [rpc beforeExecute];
                                
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    
                                    @try {
                                        INVOKE_BLOCK(rpc.onExecute, rpc.uniqueId)
                                    }
                                    @catch (NSException *exception) {
                                        NSLog(@"%@", exception.reason);
                                        
                                        INVOKE_BLOCK(rpc.onError, [NSError errorWithDomain:@"BARPCScheduler" code:999 desc:[NSString stringWithFormat:@"%@", exception.reason]])
                                        
                                        INVOKE_BLOCK(rpc.onFinally)
                                        
                                        // 移除抛异常的rpc
                                        [self->_runnings removeObjectForKey:@(rpc.uniqueId)];
                                    }
                                    @finally {
                                        
                                    }
                                    
                                });
                                
                                // 放入当前等待的高优先级
                                [_waitings removeObjectForKey:@(rpc.uniqueId)];
                            }
                        }
                    }
                }
                
                if (!findEquallyCommandRPC) {
                    // 将高优先级放入运行队列并执行
                    [_runnings setObject:rpc forKey:@(rpc.uniqueId)];
                    
                    [rpc beforeExecute];
                    
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        @try {
                            INVOKE_BLOCK(rpc.onExecute, rpc.uniqueId)
                        }
                        @catch (NSException *exception) {
                            NSLog(@"%@", exception.reason);
                            
                            INVOKE_BLOCK(rpc.onError, [NSError errorWithDomain:@"BARPCScheduler" code:999 desc:[NSString stringWithFormat:@"%@", exception.reason]])
                            
                            INVOKE_BLOCK(rpc.onFinally)
                            
                            // 移除抛异常的rpc
                            [self->_runnings removeObjectForKey:@(rpc.uniqueId)];
                        }
                        @finally {
                            
                        }
                    });
                    
                    // 放入当前等待的高优先级
                    [_waitings removeObjectForKey:@(rpc.uniqueId)];
                }
            }
        }
    }
}

- (void)removeByUniqueId:(int64_t)uniqueId {
    @synchronized (self) {
        [_waitings removeObjectForKey:@(uniqueId)];
        [_runnings removeObjectForKey:@(uniqueId)];
    }
}

- (void)removeByCommandId:(int64_t)commandId {
    @synchronized (self) {
        for (NSNumber *key in _waitings.allKeys) {
            BARPC *rpc = _waitings[key];
            if (rpc.commandId == commandId) {
                [_waitings removeObjectForKey:key];
            }
        }
        
        for (NSNumber *key in _runnings.allKeys) {
            BARPC *rpc = _runnings[key];
            if (rpc.commandId == commandId) {
                [_runnings removeObjectForKey:key];
            }
        }
    }
}

- (void)recvRPC:(NSDictionary *)remoteData {
    if (remoteData && _resultDemuxxer) {
        @WEAKIFY(self)
        _resultDemuxxer(remoteData, ^(NSDictionary *data, NSError *error, int64_t uniqueId) {
            @STRONGIFY(self)
            
            // uniqueId, commandId is for rpc routing
            BARPC *rpc;
            @synchronized (self) {
                rpc = self->_runnings[@(uniqueId)];
                [self->_runnings removeObjectForKey:@(uniqueId)];
            }
            
            // data, error is for rpc response parse
            if (rpc) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    if (error) {
                        INVOKE_BLOCK(rpc.onError, error)
                        
                        // 任何一种模式的rpc，出错后不允许恢复
                        INVOKE_BLOCK(rpc.onFinally)
                    } else {
                        INVOKE_BLOCK(rpc.onComplete, data)
                        
                        // 如果是非再生模式，则直接结束
                        if (rpc.workMode != BARPCWorkRegenerate) {
                            INVOKE_BLOCK(rpc.onFinally)
                        }
                    }
                    
                    
                });
            }
        });
    }
}

- (void)postRPC:(BARPC *)rpc {
    if (rpc) {
        rpc.currentScheduler = self;
        if (_uniqueGenerator) {
            @WEAKIFY(self)
            _uniqueGenerator(^(int64_t uniqueId) {
                @STRONGIFY(self)
                @synchronized (self) {
                    [rpc beforePost:uniqueId]; // 参数记录
                    
                    // 入队列
                    [self->_waitings setObject:rpc forKey:@(uniqueId)];
                }
            });
        }
    }
}

@end
