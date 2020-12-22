#import "BAEventBus.h"

// MARK: -

@interface BAEventSubscriber : NSObject

// as target/selector
@property (nonatomic, strong) NSObject *target;
@property (nonatomic, assign) SEL selector;

// as block
@property (nonatomic, strong) BAEventHandler handler;

@property (nonatomic, assign) int32_t times; // 次数, -1 为始终监听

@end

@implementation BAEventSubscriber

@end

// MARK: -

@interface BAEventBus () {
    NSMutableArray * _events; // 已经注册的事件名
    NSMutableDictionary * _occurrences; // 最近发生的事件
    NSMutableDictionary * _subscribers; // 订阅者
}

@end

@implementation BAEventBus

@DEF_SINGLETON(BAEventBus)

- (instancetype)init {
    if (self = [super init]) {
        _events = [@[] mutableCopy];
        _occurrences = [@{} mutableCopy];
        _subscribers = [@{} mutableCopy];
    }
    
    return self;
}

// MARK: - 缓存管理

- (void)addEvent:(NSString *)eventName {
    
}
- (void)removeEvent:(NSString *)eventName {
    
}

// MARK: - 事件分发



@end
