//
//  LGMessageFormViewStyle.h
//  LGChatViewControllerDemo
//
//  Created by zhangshunxing on 16/5/11.
//  Copyright © 2016年 zhangshunxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIColor+LGHex.h"
#import "LGChatViewStyle.h"

typedef NS_ENUM(NSUInteger, LGMessageFormViewStyleType) {
    LGMessageFormViewStyleTypeDefault,
    LGMessageFormViewStyleTypeBlue,
    LGMessageFormViewStyleTypeGreen,
    LGMessageFormViewStyleTypeDark,
};

@interface LGMessageFormViewStyle : NSObject

@property (nonatomic, copy) UIColor *navTitleColor;

/**
 * 设置导航栏上的元素颜色；
 * @param tintColor 导航栏上的元素颜色
 */
@property (nonatomic, copy) UIColor *navBarTintColor;

/**
 * 设置导航栏的背景色；
 * @param barColor 导航栏背景颜色
 */
@property (nonatomic, copy) UIColor *navBarColor;

/**
 *  留言表单界面背景色
 *
 * @param backgroundColor
 */
@property (nonatomic, strong) UIColor *backgroundColor;

/**
 *  顶部引导文案颜色
 *
 * @param introTextColor
 */
@property (nonatomic, strong) UIColor *introTextColor;

/**
 *  上方提示文案的颜色
 *
 * @param inputTipTextColor
 */
@property (nonatomic, strong) UIColor *tipTextColor;

/**
 *  输入框placeholder文字颜色
 *
 * @param inputPlaceholderTextColor
 */
@property (nonatomic, strong) UIColor *inputPlaceholderTextColor;

/**
 *  输入框上下边框颜色
 *
 * @param inputTopBottomBorderColor
 */
@property (nonatomic, strong) UIColor *inputTopBottomBorderColor;

/**
 *  内容文字颜色
 *
 * @param inputTextColor
 */
@property (nonatomic, strong) UIColor *contentTextColor;

/**
 *  选项未选中的图标
 *
 * @param unselectedImage
 */
@property (nonatomic, strong) UIImage *unselectedImage;

/**
 *  选项选中的图标
 *
 * @param unselectedImage
 */
@property (nonatomic, strong) UIImage *selectedImage;

+ (instancetype)defaultStyle;

+ (instancetype)blueStyle;

+ (instancetype)darkStyle;

+ (instancetype)greenStyle;

@end
