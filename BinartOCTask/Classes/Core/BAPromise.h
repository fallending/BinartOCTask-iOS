#import <Foundation/Foundation.h>

typedef void (^bound_block)(void);
typedef id (^transform_block)(id);

@class BADeferred;
@class BAPromise;

typedef void (^resolved_block)(id);
typedef void (^rejected_block)(NSError *);
typedef void (^any_block)(void);

typedef BAPromise *(^promise_returning_block)(void);
typedef BAPromise *(^promise_returning_arg_block)(id arg);

typedef enum {
    Incomplete = 0,
    Rejected   = 1,
    Resolved   = 2
} BAPromiseState;

@interface BAPromise : NSObject {
    NSMutableArray *_callbackBindings;
    dispatch_queue_t _queue;
    
    NSObject *_stateLock;
    BAPromiseState _state;
    
    id _result;
    NSError *_reason;
}

@property (readonly) id result;
@property (readonly) NSError *reason;
@property (readonly) BOOL isResolved;
@property (readonly) BOOL isRejected;

+ (BAPromise *)resolved:(id)result;
+ (BAPromise *)rejected:(NSError *)reason;

+ (BAPromise *)or:(NSArray *)promises;
+ (BAPromise *)and:(NSArray *)promises;

/**
 * Calls each supplied block with the result of the promise from the previously executed
 * block. If any promise rejects, the chain is broken. If all promises resolve, the result
 * of the last promise will be returned.
 *
 * @returns a promise which is resolved with the result of the last executed block
 */
+ (BAPromise *)chain:(promise_returning_arg_block)firstBlock, ... NS_REQUIRES_NIL_TERMINATION;

- (BAPromise *)when:(resolved_block)resolvedBlock;
- (BAPromise *)failed:(rejected_block)rejectedBlock;
- (BAPromise *)any:(any_block)anyBlock;
- (BAPromise *)when:(resolved_block)whenBlock failed:(rejected_block)rejectedBlock;
- (BAPromise *)when:(resolved_block)whenBlock failed:(rejected_block)rejectedBlock any:(any_block)anyBlock;

- (BAPromise *)on:(dispatch_queue_t)queue;
- (BAPromise *)onMainQueue;

- (BAPromise *)timeout:(NSTimeInterval)interval;
- (BAPromise *)timeout:(NSTimeInterval)interval leeway:(NSTimeInterval)leeway;

- (BAPromise *)transform:(transform_block)block;

- (id)wait:(NSTimeInterval)timeout;

// MARK: -

- (id)initWithQueue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

- (void)executeBlock:(bound_block)block;

@end


// 需求场景 1:
// 消息协议，客户端发送消息 A，服务器处理并给 A 的回执，怎么确定是A的回执呢？
// 使用 SequenceId 序列号，自增
