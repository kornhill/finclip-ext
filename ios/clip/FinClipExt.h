//
//  FinClipExt.h
//  clip
//
//  Created by c. liang on 26/4/2022.
//

#ifndef FinClipExt_h
#define FinClipExt_h

#import <FinApplet/FinApplet.h>
#import "libfinclipext.h"

@interface FinClipExt : NSObject {
    FATClient *finclipSDK;
}

+(FinClipExt*)singleton;
-(void)installFor:(FATClient*)finclipInst;

@end
#endif /* FinClipExt_h */
