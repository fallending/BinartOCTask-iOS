
#import <Foundation/Foundation.h>
#import <BinartOCUtility/BAUtility.h>

// MARK: -

/// 回调定义
typedef void (^ BARPCExecuteBlock)( int64_t uniqueId );
typedef void (^ BARPCCompleteBlock)( NSDictionary *data );
typedef void (^ BARPCCancelBlock)( void );
typedef void (^ BARPCInterruptBlock)( void );
typedef void (^ BARPCTimeoutBlock)( void );
typedef void (^ BARPCErrorBlock)( NSError *error );
typedef BOOL (^ BARPCRegenerateBlock)( void );
typedef void (^ BARPCFinallyBlock)( void );

/// 优先级定义
typedef enum : NSUInteger {
    BARPCPriorityNormal = 0,
    
    // 高优先级在执行的之后，整个等待队列会被冻结，慎用！
    BARPCPriorityHigh,
} BARPCPriority;

typedef enum : NSUInteger {
    BARPCWorkOnce,          // 执行一次
    
    // 什么时候回触发再生？onComplete
    BARPCWorkRegenerate,    // 可再生：依赖上一次的结果
    
    // 什么时候会触发重试？retryCount>0, onTimeout, 其中 onError 是错误，是不会重试的
    BARPCWorkRetryable,     // 可重试：原参数开始
} BARPCWorkMode;

/// RPC 对象
@interface BARPC : NSObject

@property (atomic, assign) int64_t commandId;                       // 远程调用命令 ID ===> 指令 ID ===> 一次可以移除同样id的多个处理队列
@property (atomic, assign) int64_t uniqueId;                        // 唯一 ID ===> 指令处理的序列 ID ===> 队列中以它为唯一码

@property (atomic, assign) BARPCWorkMode workMode;                  // 工作模式
@property (atomic, assign) BARPCPriority priority;                  // 优先级
@property (atomic, assign) int32_t retryCount;                      // 重试次数，-1为一直重试
@property (atomic, assign) int64_t timeoutMS;                       // 超时时间

// 时机：当前队列正在调度它
@property (nonatomic, copy) BARPCExecuteBlock onExecute;            // 指令发送

// 时机：单次call->recv
@property (nonatomic, copy) BARPCCompleteBlock onComplete;          // 指令应答

// 时机：执行队列中有两个同优先级同commandid的rpc时，newer被cancel；
@property (nonatomic, copy) BARPCCancelBlock onCancel;              // 指令取消

// 时机：执行队列中有两个同commandId不同优先级，低优先级者被interrupt，理论上该情况下，不存在低优先级被cancel
@property (nonatomic, copy) BARPCInterruptBlock onInterrupt;        // 指令中断

// 时机：单次call->recv超时
@property (nonatomic, copy) BARPCTimeoutBlock onTimeout;            // 指令处理过程超时

// 时机：单次call->recv->parse error，此时不会触发再生、重试
@property (nonatomic, copy) BARPCErrorBlock onError;                // 指令处理过程出错

// 时机：onComplete
@property (nonatomic, copy) BARPCRegenerateBlock onRegenerate;      // 指令再生，表示指令按流程继续进行；注意它和retryCount冲突，后者覆盖前者

// 时机：普通模式时，onComplete/onTimeout/onError 后调用；再生模式下，onRegenerate返回否/onTimeout/onError；重试模式下，retryCount消费完毕/onError
@property (nonatomic, copy) BARPCFinallyBlock onFinally;            // rpc 调用结束

@end

// MARK: - RPC 调度

/// 回调定义
typedef void (^ BAUniqueResolver)(int64_t uniqueId);
typedef void (^ BAUniqueGenerator)(BAUniqueResolver resolver);

typedef void (^ BAFieldsParser)(NSDictionary *data, NSError *error, int64_t uniqueId); // int64_t commandId
typedef void (^ BAResultDemuxxer)(NSDictionary *data, BAFieldsParser parser);

/// 状态定义
typedef enum : NSUInteger {
    BARPCSchedulerStateInit = 0,
    BARPCSchedulerStateStart,
    BARPCSchedulerStatePause,
} BARPCSchedulerState;

/// RPC 调度器
@interface BARPCScheduler : NSObject

@property (class, readonly) BARPCScheduler *defaultScheduler; // shared instance

@property (atomic, assign) int64_t sleepInterval; // default: 1.f

@property (atomic, copy) BAUniqueGenerator uniqueGenerator;
@property (atomic, copy) BAResultDemuxxer resultDemuxxer;       // 从应答数据解析 命令ID ===> 指令ID

- (void)start;
- (void)pause;
- (void)stop;

- (void)removeByCommandId:(int64_t)commandId;
- (void)removeByUniqueId:(int64_t)uniqueId;

- (void)recvRPC:(NSDictionary *)remoteData;

- (void)postRPC:(BARPC *)rpc;


// Old apis
//- (void)didActionReceiveResult:(NSDictionary *)data;
//- (void)didActionWithSeqId:(NSInteger)seqId receiveError:(NSError *)error;



@end
