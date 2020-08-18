//
//  LGBotMessageFactory.h
//  Laigu-SDK-Demo
//
//  Created by zhangshunxing on 16/8/24.
//  Copyright © 2016年 Laigu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGMessageFactoryHelper.h"

@class LGMessage, LGBaseMessage;
@interface LGBotMessageFactory : NSObject <LGMessageFactory>

- (LGBaseMessage *)createMessage:(LGMessage *)plainMessage;

@end
