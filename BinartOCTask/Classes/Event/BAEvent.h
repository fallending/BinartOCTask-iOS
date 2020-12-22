#import <Foundation/Foundation.h>
#import <YYModel/YYModel.h>

typedef void (^ BAEventHandler)(NSString *name, NSDictionary *data);

@interface BAEvent : NSObject <YYModel>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary *data;

@end
