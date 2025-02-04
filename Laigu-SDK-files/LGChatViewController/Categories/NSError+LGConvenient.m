//
//  NSError+LGConvenient.m
//  Laigu-SDK-Demo
//
//  Created by zhangshunxing on 2017/1/19.
//  Copyright © 2017年 Laigu. All rights reserved.
//

#import "NSError+LGConvenient.h"

@implementation NSError(LGConvenient)

+ (NSError *)reason:(NSString *)reason {
    NSError *error = [NSError errorWithDomain:@"" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey : reason}];
    return error;
}

+ (NSError *)reason:(NSString *)reason code:(NSInteger)code {
    NSError *error = [NSError errorWithDomain:@"" code:code userInfo:@{NSLocalizedFailureReasonErrorKey : reason}];
    return error;
}

+ (NSError *)reason:(NSString *)reason code:(NSInteger) code domain:(NSString *)domain {
    NSError *error = [NSError errorWithDomain:domain code:0 userInfo:@{NSLocalizedFailureReasonErrorKey : reason}];
    return error;
}

- (NSString *)reason {
    id reason = [self.userInfo objectForKey:NSLocalizedFailureReasonErrorKey];
    if ([reason isKindOfClass:NSString.class]) {
        return (NSString *)reason;
    } else {
        return @"";
    }
}

- (NSString *)shortDescription {
    return [NSString stringWithFormat:@"%@ (%d)", [self reason], (int)self.code];
}

@end
