
#import <Foundation/Foundation.h>
#import <BinartOCUtility/BAUtility.h>

#import "BAEvent.h"

@interface BAEventBus : NSObject

@SINGLETON(BAEventBus)

///// 注册即可，方法名规则：on<EventName> 所以建议EventName第一个字母大写
//- (void)all:(NSObject *)subscriber; // 未实现
//
///// 根据事件名，注册block
//- (void)each:(NSString *)eventName block:(BAEventHandler)handler;
//- (void)once:(NSString *)eventName block:(BAEventHandler)handler;
//
////- (void)all:(BAEventHandler)handler;
//
/////
//- (void)each:(NSString *)eventName target:(NSObject *)target selector:(SEL)handler;
//- (void)once:(NSString *)eventName target:(NSObject *)target selector:(SEL)handler;
//- (void)all:(NSObject *)target selector:(SEL)handler;
//
/////
//- (void)off:(NSString *)eventName;

@end
