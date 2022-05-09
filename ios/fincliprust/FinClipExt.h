//
//  FinClipExt.h
//
//  Created by c. liang on 26/4/2022.
//

#ifndef FinClipExt_h
#define FinClipExt_h

#import <Foundation/Foundation.h>

//! Project version number for FinClipRustExt.
FOUNDATION_EXPORT double FinClipRustExtVersionNumber;

//! Project version string for FinClipRustExt.
FOUNDATION_EXPORT const unsigned char FinClipRustExtVersionString[];

#import "FinApplet.h"
#import "libfinclipext.h"

@interface FinClipExt : NSObject {
    FATClient *finclipSDK;
}

+(FinClipExt*)singleton;
-(void)installFor:(FATClient*)finclipInst;

@end
#endif /* FinClipExt_h */
