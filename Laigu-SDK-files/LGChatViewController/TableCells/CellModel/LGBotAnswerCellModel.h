//
//  LGBotAnswerCellModel.h
//  LGChatViewControllerDemo
//
//  Created by zhangshunxing on 16/4/27.
//  Copyright © 2016年 zhangshunxing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGCellModelProtocol.h"
#import "LGBotAnswerMessage.h"

/**
 * LGBotAnswerCellModel 定义了机器人回答消息的基本类型数据，包括产生cell的内部所有view的显示数据，cell内部元素的frame等
 * @warning LGBotAnswerCellModel 必须满足LGCellModelProtocol协议
 */
@interface LGBotAnswerCellModel : NSObject <LGCellModelProtocol>

/**
 * @brief cell中消息的id
 */
@property (nonatomic, readonly, strong) NSString *messageId;

/**
 * @brief 用户名字，暂时没用
 */
@property (nonatomic, readonly, copy) NSString *userName;

/**
 * @brief 该cellModel的委托对象
 */
@property (nonatomic, weak) id<LGCellModelDelegate> delegate;

/**
 * @brief cell的高度
 */
@property (nonatomic, readonly, assign) CGFloat cellHeight;

/**
 * @brief cell的宽度
 */
@property (nonatomic, readonly, assign) CGFloat cellWidth;

/**
 * @brief 消息的文字
 */
@property (nonatomic, readonly, copy) NSAttributedString *cellText;

/**
 * @brief 消息的文字属性
 */
@property (nonatomic, readonly, copy) NSDictionary *cellTextAttributes;

/**
 * @brief 消息的时间
 */
@property (nonatomic, readonly, copy) NSDate *date;

/**
 * @brief 发送者的头像Path
 */
@property (nonatomic, readonly, copy) NSString *avatarPath;

/**
 * @brief 发送者的头像的图片
 */
@property (nonatomic, readonly, copy) UIImage *avatarImage;

/**
 * @brief 聊天气泡的image
 */
@property (nonatomic, readonly, copy) UIImage *bubbleImage;

/**
 * @brief 消息气泡的frame
 */
@property (nonatomic, readonly, assign) CGRect bubbleImageFrame;

/**
 * @brief 消息气泡中的文字的frame
 */
@property (nonatomic, readonly, assign) CGRect textLabelFrame;

/**
 * @brief 发送者的头像frame
 */
@property (nonatomic, readonly, assign) CGRect avatarFrame;

/**
 * @brief 发送状态指示器的frame
 */
@property (nonatomic, readonly, assign) CGRect sendingIndicatorFrame;

/**
 * @brief 发送出错图片的frame
 */
@property (nonatomic, readonly, assign) CGRect sendFailureFrame;

/**
 * @brief 消息的来源类型
 */
@property (nonatomic, readonly, assign) LGChatCellFromType cellFromType;

/**
 * @brief 消息文字中，数字选中识别的字典 [number : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *numberRangeDic;

/**
 * @brief 消息文字中，url选中识别的字典 [url : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *linkNumberRangeDic;

/**
 * @brief 消息文字中，email选中识别的字典 [email : range]
 */
@property (nonatomic, readonly, strong) NSDictionary *emailNumberRangeDic;

/**
 * @brief 「有用」「无用」上方的线条 frame
 */
@property (nonatomic, readonly, assign) CGRect evaluateUpperLineFrame;

/**
 * @brief 「有用」「无用」中间的线条 frame
 */
@property (nonatomic, readonly, assign) CGRect evaluateMiddleLineFrame;

/**
 * @brief 「有用」按钮的 frame
 */
@property (nonatomic, readonly, assign) CGRect positiveBtnFrame;

/**
 * @brief 「无用」按钮的 frame
 */
@property (nonatomic, readonly, assign) CGRect negativeBtnFrame;

/**
 * @brief 「留言」按钮的 frame
 */
@property (nonatomic, readonly, assign) CGRect replyBtnFrame;

/**
 * @brief 「已反馈」按钮的 frame
 */
@property (nonatomic, readonly, assign) CGRect evaluateDoneBtnFrame;

/**
 * @brief 是否已反馈标记
 */
@property (nonatomic, readonly, assign) BOOL isEvaluated;

/**
 * @brief 消息的发送状态
 */
@property (nonatomic, assign) LGChatMessageSendStatus sendStatus;

/**
 * @brief 消息的 sub type
 */
@property (nonatomic, readonly, copy) NSString *messageSubType;

/**
 * @brief 普通类型的集合
 */
@property (nonatomic, readonly, copy) NSArray *normalSubTypes;

/**
 *  根据LGMessage内容来生成cell model
 */
- (LGBotAnswerCellModel *)initCellModelWithMessage:(LGBotAnswerMessage *)message
                                         cellWidth:(CGFloat)cellWidth
                                          delegate:(id<LGCellModelDelegate>)delegator;

/**
 *  已做评价
 */
- (void)didEvaluate;

@end
