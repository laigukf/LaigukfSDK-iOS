//
//  LGJsonUtil.h
//  LGEcoboostSDK-test
//
//  Created by shunxingzhang on 2020/7/9.
//  Copyright © 2020 zhangshunxing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LGJsonUtil : NSObject

+ (NSString *)JSONStringWith:(id)obj;

+ (id)createWithJSONString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
