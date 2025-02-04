//
//  LGMessage.h
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/23.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGAgent.h"
#import "LGCardInfo.h"

#define QUEUEING_SYMBOL 999

typedef enum : NSUInteger {
    LGMessageActionMessage                      = 0,   //普通消息 (message)
    LGMessageActionInitConversation             = 1,   //初始化对话 (init_conv)
    LGMessageActionAgentDidCloseConversation    = 2,   //客服结束对话 (end_conv_agent)
    LGMessageActionEndConversationTimeout       = 3,   //对话超时，系统自动结束对话 (end_conv_timeout)
    LGMessageActionRedirect                     = 4,   //顾客被转接 (agent_redirect)
    LGMessageActionAgentInputting               = 5,   //客服正在输入 (agent_inputting)
    LGMessageActionInviteEvaluation             = 6,   //收到客服邀请评价 (invite_evaluation)
    LGMessageActionClientEvaluation             = 7,   //顾客评价的结果 (client_evaluation)
    LGMessageActionTicketReply                  = 8,   //客服留言回复的消息
    LGMessageActionAgentUpdate                  = 9,    //客服的状态发生了改变
    LGMessageActionListedInBlackList            = 10,  //被客户加入到黑名单
    LGMessageActionRemovedFromBlackList         = 11,  //被客户从黑名单中移除
    LGMessageActionQueueingAdd                  = 12,  //顾客被添加到等待客服队列
    LGMessageActionQueueingRemoved              = 13,  //顾客从等待队列中移除
    LGMessageActionWithdrawMessage              = 14,  //消息撤回(withdraw_msg)
    LGMessageActionAgentSendCard                = 15   // 线索卡片
} LGMessageAction;

typedef enum : NSUInteger {
    LGMessageContentTypeText                 = 0,//文字
    LGMessageContentTypeImage                = 1,//图片
    LGMessageContentTypeVoice                = 2, //语音
    LGMessageContentTypeFile                 = 3, //文件传输
    LGMessageContentTypeBot                  = 4,  //机器人消息
    LGMessageContentTypeRichText             = 5, //图文消息
    LGMessageContentTypeCard                 = 6, //卡片消息
    LGMessageContentTypeHybrid               = 7, //混合消息
} LGMessageContentType;

typedef enum : NSUInteger {
    LGMessageFromTypeClient                  = 0,//来自 顾客
    LGMessageFromTypeAgent                   = 1,//来自 客服
    LGMessageFromTypeSystem                  = 2,//来自 系统
    LGMessageFromTypeBot                     = 3 //来自 机器人
} LGMessageFromType;

typedef enum : NSUInteger {
    LGMessageTypeMessage                     = 0,//普通消息
    LGMessageTypeWelcome                     = 1,//欢迎消息
    LGMessageTypeEnding                      = 2,//结束语
    LGMessageTypeRemark                      = 3,//评价
    LGMessageTypeReply                       = 4 //留言
} LGMessageType;

typedef enum : NSUInteger {
    LGMessageSendStatusSuccess               = 0,//发送成功
    LGMessageSendStatusFailed                = 1,//发送失败
    LGMessageSendStatusSending               = 2 //发送中
} LGMessageSendStatus;

@interface LGMessage : LGModel <NSCopying>

/** 消息id */
@property (nonatomic, copy  ) NSString             *messageId;

/** 消息内容 */
@property (nonatomic, copy  ) NSString             *content;

/** 消息的状态 */
@property (nonatomic, assign) LGMessageAction      action;

/** 内容类型 */
@property (nonatomic, assign) LGMessageContentType contentType;

/** 顾客id */
@property (nonatomic, copy  ) NSString             *trackId;

/** 客服id */
@property (nonatomic, copy  ) NSString             *agentId;

/** 客服 */
@property (nonatomic, strong) LGAgent              *agent;

/** 消息发送人头像 */
@property (nonatomic, copy  ) NSString             *messageAvatar;

/** 消息发送人名字 */
@property (nonatomic, copy  ) NSString             *messageUserName;

/** 消息创建时间, UTC格式 */
@property (nonatomic, copy  ) NSDate               *createdOn;

/** 来自顾客还是客服 */
@property (nonatomic, assign) LGMessageFromType    fromType;

/** 消息类型 */
@property (nonatomic, assign) LGMessageType        type;

/** 消息状态 */
@property (nonatomic, assign) LGMessageSendStatus  sendStatus;

/** 消息对应的对话id */
@property (nonatomic, copy  ) NSString             *conversationId;

/** 消息是否已读 */
@property (nonatomic, assign) bool                 isRead;

/** 标记消息是否是敏感消息 */
@property (nonatomic, assign) bool                 isSensitive;

/** 标记客服发送消息的状态 1 服务器已接收; 2 sdk已接收; 3 sdk已读 */
@property (nonatomic, strong) NSNumber             *readStatus;

/*
 该消息对应的 enterprise id, 不一定有值，也不存数据库，仅用来判断该消息属于哪个企业，用来切换数据库, 如果这个地方没有值，查看 agent 对象里面的 enterpriseId 字段
 */
@property (nonatomic, copy) NSString *enterpriseId;

///** 消息的 sub_type */
//@property (nonatomic, copy)   NSString             *subType;
//
///** 机器人消息 */
//@property (nonatomic, copy)   NSArray              *contentRobot;

/** 不同的 message 类型会携带不同数据，也可能为空, 以JSON格式保存到数据库 */
/**
 机器人的 accessorData
 {
    sub_type, content_robot, question_id, is_evaluate
 }
 **/
@property (nonatomic, copy) id accessoryData;

/** 线索卡片数据 */
@property (nonatomic, strong) NSArray *cardData;

/** 消息是否为撤回消息，默认不撤回 */
@property (nonatomic, assign) BOOL isMessageWithDraw;

+ (instancetype)createBlacklistMessageWithAction:(NSString *)action;

- (NSString *)stringFromContentType;

//- (id)initMessageWithData:(NSDictionary *)data;

@end
