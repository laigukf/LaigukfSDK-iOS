//
//  UIControl+LGControl.h
//  Laigu-SDK-Demo
//
//  Created by zhangshunxing on 2018/1/11.
//  Copyright © 2018年 Laigu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^XLPButtonDownBlock)(UIButton *sender);
typedef void(^XLPButtonUpInsideBlock)(UIButton *sender);
typedef void(^XLPValueChangedBlock)(id sender);


@interface UIControl (LGControl)
/**
 *  按钮按下事件回调
 */
@property (nonatomic, copy) XLPButtonDownBlock xlp_touchDown;

/**
 *  按钮松开事件回调
 */
@property (nonatomic, copy) XLPButtonUpInsideBlock xlp_touchUpInside;

/**
 *  值改变时的回调block
 */
@property (nonatomic, copy) XLPValueChangedBlock xlp_valueChangedBlock;
@end
