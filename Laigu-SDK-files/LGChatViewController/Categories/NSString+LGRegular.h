//
//  NSString+LGRegular.h
//  LGEcoboostSDK-test
//
//  Created by qipeng_yuhao on 2020/5/26.
//  Copyright © 2020 MeiQia. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (LGRegular)

- (BOOL)isQQ;

- (BOOL)isPhoneNumber;

- (BOOL)isTelNumber;

@end

NS_ASSUME_NONNULL_END
