#import "BADeferred.h"

@implementation BADeferred (Private)

- (void)transitionToState:(BAPromiseState)state {
    NSArray *blocksToExecute = nil;
    BOOL shouldComplete = NO;
    
    @synchronized (_stateLock) {
        if (_state == Incomplete) {
            _state = state;
            
            shouldComplete = YES;
            
            blocksToExecute = _callbackBindings;
            
            _callbackBindings = nil;
        }
    }
    
    if (shouldComplete) {
        for (bound_block block in blocksToExecute) {
            [self executeBlock:block];
        }
    }
}

@end


@implementation BADeferred

- (id)init {
    if (self = [super init]) {
    }
    
    return self;
}

+ (BADeferred *)deferred {
    return [[BADeferred alloc] init];
}

- (BAPromise *)promise {
    return self;
}

- (BAPromise *)resolve:(id)result {
    _result = result;
    
    [self transitionToState:Resolved];
    
    return [self promise];
}

- (BAPromise *)reject:(NSError *)reason {
    _reason = reason;
    
    [self transitionToState:Rejected];
    
    return [self promise];
}


@end
