#import "BAPromise.h"

@interface BADeferred : BAPromise

+ (BADeferred *)deferred;

- (BAPromise *)promise;
- (BAPromise *)resolve:(id)result;
- (BAPromise *)reject:(NSError *)reason;

@end
