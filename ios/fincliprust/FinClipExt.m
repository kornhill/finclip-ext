//
//  FinClipExt.m
//  clip
//
//  Created by c. liang on 26/4/2022.
//

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
