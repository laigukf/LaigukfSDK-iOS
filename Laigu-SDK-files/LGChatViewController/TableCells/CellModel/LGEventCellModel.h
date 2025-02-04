//
//  LGEventCellModel.h
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/29.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGCellModelProtocol.h"
#import "LGEventMessage.h"

/**
 * LGEventCellModel定义了消息事件的基本类型数据，包括产生cell的内部所有view的显示数据，cell内部元素的frame等
 * @warning LGEventCellModel必须满足LGCellModelProtocol协议
 */
@interface LGEventCellModel : NSObject <LGCellModelProtocol>

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readonly, strong) NSString *messageId;

/**
 * @brief cell的高度
 */
@property (nonatomic, readonly, assign) CGFloat cellHeight;

/**
 * @brief 事件文字
 */
@property (nonatomic, readonly, copy) NSString *eventContent;

/**
 * @brief 事件消息的时间
 */
@property (nonatomic, readonly, copy) NSDate *date;

/**
 * @brief 消息气泡button的frame
 */
@property (nonatomic, readonly, assign) CGRect eventLabelFrame;


/**
 *  根据LGMessage内容来生成cell model
 */
- (LGEventCellModel *)initCellModelWithMessage:(LGEventMessage *)message cellWidth:(CGFloat)cellWidth;

@end
