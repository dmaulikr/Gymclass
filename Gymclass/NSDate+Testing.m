//
//  NSDate+Testing.m
//  Gymclass
//
//  Created by ERIC COLTON on 4/6/14.
//  Copyright (c) 2014 Cindy Software. All rights reserved.
//

#import <objc/runtime.h>

@implementation NSDate (Testing)

+(void)load
{
    //NORMALLY, we don't want swizzeling on (so INCLUDE the 'return;' statement below!)
    return;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SEL orig = @selector(date);
        SEL new = @selector(Testing_date);
        
        
        Class c = [self class];
//        Class c =object_getClass((id)self);
        
        Method origMethod = class_getClassMethod(c, orig);
        Method newMethod = class_getClassMethod(c, new);
        
        c = object_getClass((id)c);
        
            if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
                class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
            else
                method_exchangeImplementations(origMethod, newMethod);
    });
}

#pragma mark - Method Swizzling
+(instancetype)Testing_date
{
    NSLog(@"[NSDate date] swizzeled");
    return [NSDate dateWithTimeIntervalSince1970:1396800141];
}

@end
