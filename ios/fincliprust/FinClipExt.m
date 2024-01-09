//
//  FinClipExt.m
//  clip
//
//  Created by c. liang on 26/4/2022.
//

/**
这段 Objective-C 代码试图实现以下主要功能:

1.单例模式
通过单例模式实现一个 FinClipExt 的全局实例,方便作为扩展模块被外部访问和使用。
2.动态注册扩展 API
提供了一个添加扩展 API 的机制,可以在运行时动态将 Rust 实现的扩展函数注册成 Objective-C 的方法。
3.与宿主应用交互
通过传入的 FATClient 实例,可以获得宿主应用提供的机制来注册扩展 API,以便宿主应用可以调用这些扩展。
4.数据转换
实现了 JSON 序列化和反序列化的机制,用来在 Objective-C 和 Rust 实现的函数之间转换数据。
5.Rust FFI
使用 Rust 的 FFI 特性,调用由 Rust 语言实现的扩展模块的函数,将 Objective-C 和 Rust 语言连接了起来。
主要目的是提供一个 Objective-C 的扩展封装,方便第三方开发者基于 Rust 开发一些扩展插件,并可以轻松集成到现有的 Objective-C 应用中。

这样的动态扩展机制可以提高应用的扩展性和开发效率。
*/

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "FinClipExt.h"

@implementation FinClipExt

static FinClipExt *_sharedMySingleton = nil;

+(FinClipExt*)singleton{
    @synchronized([FinClipExt class]) {
        if (!_sharedMySingleton){
            _sharedMySingleton = [[self alloc] init];
        }
        return _sharedMySingleton;
    }
    return nil;
}

+(id)alloc {
    @synchronized([FinClipExt class])
    {
        NSAssert(_sharedMySingleton == nil, @"Singleton already initialized.");
        _sharedMySingleton = [super alloc];
        return _sharedMySingleton;
    }
    return nil;
}

-(id)init {
    self = [super init];
    if (self != nil) {
        // initialize stuff here
    }   return self;
}

-(void) installFor:(FATClient *)finclipInst withExt:(struct HashMap_String__FinClipCall*)map
{
    finclipSDK = finclipInst;
    finclip_init(map);
    [self addExtensionApi];
}

static NSDictionary *finclipCall(id self, SEL _cmd, NSDictionary *input)
 {
    NSLog(@"%@ call",NSStringFromSelector(_cmd));
    
    NSString *json = [self toJsonString:input];
    const char *cjson = [json UTF8String];
    
    NSString *api = NSStringFromSelector(_cmd);
    const char *capi = [api UTF8String];
    
    // Rust FFI tansfer returned data ownership here. Should be release back to Rust later
    char *cresult = finclip_call(capi, cjson);
    NSDictionary *output = [self jsonStringToDictionary:@(cresult)];
    
    // release resource back to Rust
    finclip_release(cresult);
    
    return output;
 }

- (NSDictionary *)exemplar:(NSDictionary *)param
{
    NSLog(@"%s", __func__);
    
    NSDictionary *resultDict = @{
        @"errMsg":[NSString stringWithFormat:@"%s:%s", __func__, "ok"]
    };
    return resultDict;
}

- (void) addExtensionApi {
    Method exemplar_func = class_getInstanceMethod([self class],
                                                   @selector(exemplar:));
    const char *types = method_getTypeEncoding(exemplar_func);
    
    for (int i = 0; i < finclip_set(); i++) {
        char* name_owned_by_rust = finclip_api_name(i);
        NSString *name = [NSString stringWithUTF8String:name_owned_by_rust];
        NSLog(@"adding extension API %@", name);
        
        class_addMethod([self class], NSSelectorFromString(name), (IMP)finclipCall, types);
        [finclipSDK registerSyncExtensionApi:name target:self];
        
        // should comment out - verify dynamic methods are correctly registered
        // and can truly be invoked
        NSDictionary *param = @{
                @"name": name
        };
        [self performSelectorOnMainThread:NSSelectorFromString(name) withObject:param waitUntilDone:YES];
        
        // remember to release resource back to Rust, or memory leak will result
        finclip_release(name_owned_by_rust);
    }
    
}

- (NSString *)toJsonString:(NSDictionary *)dict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    NSString *jsonString;

    if (!jsonData) {
        NSLog(@"%@",error);
    } else {
        jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    NSMutableString *mutStr = [NSMutableString stringWithString:jsonString];

    NSRange range = {0,jsonString.length};

    //去掉字符串中的空格
    [mutStr replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];

    NSRange range2 = {0,mutStr.length};

    //去掉字符串中的换行符
    [mutStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range2];

    return mutStr;
}

- (NSDictionary *)jsonStringToDictionary:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json parsing failure：%@",err);
        return nil;
    }
    return dic;
}

@end
