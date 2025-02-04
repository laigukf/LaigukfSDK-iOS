//
//  LGBotMenuMessage.h
//  LGChatViewControllerDemo
//
//  Created by zhangshunxing on 16/4/27.
//  Copyright © 2016年 zhangshunxing. All rights reserved.
//

#import "LGBaseMessage.h"

@interface LGBotMenuMessage : LGBaseMessage

/** 消息content */
@property (nonatomic, copy) NSString *content;

/** 富文本消息 */
@property (nonatomic, copy) NSString *richContent;

/** 消息 menu */
@property (nonatomic, copy) NSArray *menu;

/**
 * 初始化message
 */
- (instancetype)initWithContent:(NSString *)content menu:(NSArray *)menu;


@end
