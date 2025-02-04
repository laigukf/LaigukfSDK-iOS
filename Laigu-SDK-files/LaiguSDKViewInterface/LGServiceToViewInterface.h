//
//  LGServiceToViewInterface.h
//  LGChatViewControllerDemo
//
//  Created by zhangshunxing on 15/11/5.
//  Copyright © 2015年 zhangshunxing. All rights reserved.
//
/**
 *  该文件的作用是：开源聊天界面调用来鼓 SDK 接口的中间层，目的是剥离开源界面中的来鼓业务逻辑。这样就能让该聊天界面用于非来鼓项目中，开发者只需要实现 `LGServiceToViewInterface` 中的方法，即可将自己项目的业务逻辑和该聊天界面对接。
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LGImageMessage.h"
#import "LGVoiceMessage.h"
#import "LGTextMessage.h"
#import "LGEventMessage.h"
#import "LGBotAnswerMessage.h"
#import "LGBotMenuMessage.h"
#import "LGChatViewConfig.h"
#import <LaiGuSDK/LaiguSDK.h>
#import "LGFileDownloadMessage.h"
#import "LGRichTextMessage.h"
#import "LGBotRichTextMessage.h"
#import "LGPhotoCardMessage.h"

/**
 *  该协议是UI层获取数据的委托方法
 */
@protocol LGServiceToViewInterfaceDelegate <NSObject>

/**
 * 获取到多个消息
 * @param messages 消息数组，元素为LGBaseMessage类型
 * @warning 该数组是按时间从旧到新排序
 */
- (void)didReceiveHistoryMessages:(NSArray *)messages;

/**
 * 获取到了新消息
 * @param messages 消息数组，元素为LGBaseMessage类型
 * @warning 该数组是按时间从旧到新排序
 */
- (void)didReceiveNewMessages:(NSArray *)messages;

/**
 *  收到了一条辅助信息（目前只有“客服不在线”、“被转接的消息”）
 *
 *  @param tipsContent 辅助信息
 */
- (void)didReceiveTipsContent:(NSString *)tipsContent;

- (void)didReceiveTipsContent:(NSString *)tipsContent showLines:(BOOL)show;

/**
 * 发送文字消息结果
 * @param newMessageId 发送成功以后返回的messageid
 * @param oldMessageId 发送之前messageid
 * @param newMessageDate 更新的发送时间
 * @param replacedContent 需要替换的messag.content的内容(处理敏感词汇，替换原来词汇)
 * @param sendStatus 发送状态
 */
- (void)didSendMessageWithNewMessageId:(NSString *)newMessageId
                          oldMessageId:(NSString *)oldMessageId
                        newMessageDate:(NSDate *)newMessageDate
                       replacedContent:(NSString *)replacedContent
                            sendStatus:(LGChatMessageSendStatus)sendStatus;

/**
 *  顾客已被转接
 *
 *  @param agentName 被转接的客服名字
 */
- (void)didRedirectWithAgentName:(NSString *)agentName;

// 客服分配完成
- (void)didScheduleResult:(LGClientOnlineResult)onLineResult withResultMessages:(NSArray<LGMessage *> *)message;

@end

/**
 *  界面发送的请求出错的委托方法
 */
@protocol LGServiceToViewInterfaceErrorDelegate <NSObject>

/**
 *  收到获取历史消息的错误
 */
- (void)getLoadHistoryMessageError;

@end

/**
 *  LGServiceToViewInterface是来鼓开源UI层和来鼓数据逻辑层的接口
 */
@interface LGServiceToViewInterface : NSObject

@property (nonatomic, weak) id<LGServiceToViewInterfaceDelegate> serviceToViewDelegate;

/**
 * 从服务端获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)getServerHistoryMessagesWithMsgDate:(NSDate *)msgDate
                             messagesNumber:(NSInteger)messagesNumber
                            successDelegate:(id<LGServiceToViewInterfaceDelegate>)successDelegate
                              errorDelegate:(id<LGServiceToViewInterfaceErrorDelegate>)errorDelegate;

/**
 * 从本地获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)getDatabaseHistoryMessagesWithMsgDate:(NSDate *)msgDate
                               messagesNumber:(NSInteger)messagesNumber
                                     delegate:(id<LGServiceToViewInterfaceDelegate>)delegate;

/**
 * 从服务端获取留言消息和一般的消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
+ (void)getServerHistoryMessagesAndTicketsWithMsgDate:(NSDate *)msgDate
                             messagesNumber:(NSInteger)messagesNumber
                            successDelegate:(id<LGServiceToViewInterfaceDelegate>)successDelegate
                              errorDelegate:(id<LGServiceToViewInterfaceErrorDelegate>)errorDelegate;

/**
 * 从服务端获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
/*
+ (void)getServerHistoryMessagesWithLastMsgDate:(NSDate *)msgDate
                             messagesNumber:(NSInteger)messagesNumber
                            successDelegate:(id<LGServiceToViewInterfaceDelegate>)successDelegate
                              errorDelegate:(id<LGServiceToViewInterfaceErrorDelegate>)errorDelegate;
*/
/**
 * 从本地获取更多消息
 *
 * @param msgDate 获取该日期之前的历史消息;
 * @param messagesNum 获取消息的数量
 */
/*
+ (void)getDatabaseHistoryMessagesWithLastMsgDate:(NSDate *)msgDate
                               messagesNumber:(NSInteger)messagesNumber
                                     delegate:(id<LGServiceToViewInterfaceDelegate>)delegate;
*/
/**
 * 发送文字消息
 * @param content 消息内容。会做前后去空格处理，处理后的消息长度不能为0，否则不执行发送操作
 * @param localMessageId 本地消息id
 * @param delegate 发送消息的代理，如果发送成功，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendTextMessageWithContent:(NSString *)content
                         messageId:(NSString *)localMessageId
                          delegate:(id<LGServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送图片消息。该函数会做图片压缩操作，尺寸将会限制在最大1280px
 *
 * @param image 图片
 * @param localMessageId 本地消息id
 * @param delegate 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendImageMessageWithImage:(UIImage *)image
                        messageId:(NSString *)localMessageId
                         delegate:(id<LGServiceToViewInterfaceDelegate>)delegate;

/**
 * 发送语音消息。使用该接口，需要开发者提供一条amr格式的语音.
 *
 * @param audio 需要发送的语音消息，格式为amr。
 * @param localMessageId 本地消息id
 * @param delegate 发送消息的代理，会返回完整的消息对象，代理函数：-(void)didSendMessage:expcetion:
 */
+ (void)sendAudioMessage:(NSData *)audio
               messageId:(NSString *)localMessageId
                delegate:(id<LGServiceToViewInterfaceDelegate>)delegate;

/**
 * 将用户正在输入的内容，提供给客服查看。该接口没有调用限制，但每1秒内只会向服务器发送一次数据
 * @param content 提供给客服看到的内容
 */
+ (void)sendClientInputtingWithContent:(NSString *)content;

/**
 * 根据开发者自定义的id，登陆来鼓客服系统
 * @param ;
 */
- (void)setClientOnlineWithCustomizedId:(NSString *)customizedId
                                success:(void (^)(BOOL completion, NSString *agentName, NSString *agentType, NSArray *receivedMessages, NSError *error))success
                 receiveMessageDelegate:(id<LGServiceToViewInterfaceDelegate>)receiveMessageDelegate;

/**
 * 根据来鼓的顾客id，登陆来鼓客服系统
 * @param ;
 */
- (void)setClientOnlineWithClientId:(NSString *)clientId
                            success:(void (^)(BOOL completion, NSString *agentName, NSString *agentType, NSArray *receivedMessages, NSError *error))success
             receiveMessageDelegate:(id<LGServiceToViewInterfaceDelegate>)receiveMessageDelegate;

/**
 *  设置指定分配的客服或客服组
 *
 */
+ (void)setScheduledAgentWithAgentId:(NSString *)agentId
                        agentGroupId:(NSString *)agentGroupId
                        scheduleRule:(LGChatScheduleRules)scheduleRule;

/**
 *  设置不指定分配的客服或客服组
 *
 */
+ (void)setNotScheduledAgentWithAgentId:(NSString *)agentId;

/**
 * 删除指定分配的客服或客服组。
 *
*/
+ (void)deleteScheduledAgent;

/**
 * 设置顾客离线
 * @param ;
 */
+ (void)setClientOffline;

/**
 *  点击了某消息
 *
 *  @param messageId 消息id
 #pragma mark xlp - .m文件已经注释 17/7/25

 */
//+ (void)didTapMessageWithMessageId:(NSString *)messageId;

/**
 *  获取当前客服名字
 */
+ (NSString *)getCurrentAgentName;

/**
 *  获取当前客服对象
 */
+ (LGAgent *)getCurrentAgent;

/**
 *  获取当前客服状态
 *
 *  @return onDuty - 在线  offDuty - 隐身  offLine - 离线
 */
+ (LGChatAgentStatus)getCurrentAgentStatus;

/**
 *  当前是否有客服
 *
 */
+ (BOOL)isThereAgent;


/**
 *  当前是否有分配对话
 *
 */
+ (BOOL)haveConversation;

/**
 *  获取当前分配对话的会话id，，没有分配则为nil
 */
+ (NSString *)getCurrentConversationID;

/**
 *  下载多媒体消息的多媒体内容
 *
 *  @param messageId     消息id
 *  @param progressBlock 下载进度
 *  @param completion    完成回调
 */
+ (void)downloadMediaWithUrlString:(NSString *)urlString
                          progress:(void (^)(float progress))progressBlock
                        completion:(void (^)(NSData *mediaData, NSError *error))completion;


/**
 *  将数据库中某个message删除
 *
 *  @param messageId 消息id
 */
+ (void)removeMessageInDatabaseWithId:(NSString *)messageId
                           completion:(void (^)(BOOL success, NSError *error))completion;


/**
 *  获取当前顾客的顾客信息
 *
 *  @return 当前的顾客的信息
 *
 */
+ (NSDictionary *)getCurrentClientInfo;

/**
 *  上传顾客的头像
 *
 *  @param avatarImage 头像image
 *  @param completion  上传的回调
 */
+ (void)uploadClientAvatar:(UIImage *)avatarImage
                completion:(void (^)(NSString *avatarUrl, NSError *error))completion;

/**
 *  对当前的对话做出评价
 *
 *  @param level 服务评级
 *  @param comment    评价留言
 */
+ (void)setEvaluationLevel:(NSInteger)level
                   comment:(NSString *)comment;

/**
 *  上传顾客信息
 *
 *  @param clientInfo 顾客信息
 */
+ (void)setClientInfoWithDictionary:(NSDictionary *)clientInfo
                         completion:(void (^)(BOOL success, NSError *error))completion;

/**
 *  更新顾客信息
 *
 *  @param clientInfo 顾客信息
 */
+ (void)updateClientInfoWithDictionary:(NSDictionary *)clientInfo
                         completion:(void (^)(BOOL success, NSError *error))completion;

/**
 *  缓存当前的输入文字
 *
 *  @param inputtingText 输入文字
 */
+ (void)setCurrentInputtingText:(NSString *)inputtingText;

/**
 *  获取缓存的输入文字
 *
 *  @return 输入文字
 */
+ (NSString *)getPreviousInputtingText;

/**
 * 获得服务端未读消息
 
 * @return 输入文字
 */
+ (void)getUnreadMessagesWithCompletion:(void (^)(NSArray *messages, NSError *error))completion;

/**
 * 获得本地未读消息
 
 * @return 输入文字
 */
+ (NSArray *)getLocalUnreadMessages;

/**
 * 判断是否被加入了黑名单
 */
+ (BOOL)isBlacklisted;

/**
 * 清除已下载的文件
 */
+ (void)clearReceivedFiles;

/**
 修改或增加已保存的消息中的 accessory data 中的数据
 
 @param accessoryData 字典中的数据必须是基本数据和字符串
 */
+ (void)updateMessageWithId:(NSString *)messageId forAccessoryData:(NSDictionary *)accessoryData;

+ (void)updateMessageIds:(NSArray *)messageIds toReadStatus:(BOOL)isRead;

/**
 * 将所有消息标记为已读
 */
+ (void)markAllMessagesAsRead;

/**
 * 汇报文件被下载
 */
+ (void)clientDownloadFileWithMessageId:(NSString *)messageId
                          conversatioId:(NSString *)conversationId
                          andCompletion:(void(^)(NSString *url, NSError *error))action;

/**
 *  取消下载
 *
 *  @param urlString     url
 */
+ (void)cancelDownloadForUrl:(NSString *)urlString;


/**
 对机器人的回答做评价
 @param messageId 消息 id
 */
+ (void)evaluateBotMessage:(NSString *)messageId
                  isUseful:(BOOL)isUseful
                completion:(void (^)(BOOL success, NSString *text, NSError *error))completion;

//强制转人工
- (void)forceRedirectHumanAgentWithSuccess:(void (^)(BOOL completion, NSString *agentName, NSArray *receivedMessages))success
                                   failure:(void (^)(NSError *error))failure
                    receiveMessageDelegate:(id<LGServiceToViewInterfaceDelegate>)receiveMessageDelegate;

//强制转人工
+ (NSString *)getCurrentAgentId;

/**
 获取当前的客服 type: agent | admin | robot
 */
+ (NSString *)getCurrentAgentType;

/**
 获取客服邀请评价显示的文案
 */
+ (void)getEvaluationPromtTextComplete:(void(^)(NSString *, NSError *))action;

/**
 获取是否显示强制转接人工按钮
 */
+ (void)getIsShowRedirectHumanButtonComplete:(void(^)(BOOL, NSError *))action;

/**
 获取留言表单引导文案
 */
+ (void)getMessageFormConfigComplete:(void (^)(LGEnterpriseConfig *config, NSError *))action;

/**
 获取配置的 ticket 类别
 */
+ (void)getTicketCategoryComplete:(void(^)(NSArray *categories))action;

/**
 *  提交留言表单
 *
 *  @param message 留言消息
 *  @param clientInfo 顾客的信息
 *  @param completion  提交留言表单的回调
 */
+ (void)submitMessageFormWithMessage:(NSString *)message
                          clientInfo:(NSDictionary<NSString *, NSString *>*)clientInfo
                          completion:(void (^)(BOOL success, NSError *error))completion;


/**
 获取当前企业的配置信息
 */
+ (void)getEnterpriseConfigInfoWithCache:(BOOL)isLoadCache complete:(void(^)(LGEnterprise *, NSError *))action;

/**
 在准备显示聊天界面是调用
 */
+ (void)prepareForChat;

/**
 在聊天界面消失是调用
 */
+ (void)completeChat;

/**
 切换本地用户为指定的自定义 id 用户, 回调的 clientId 如果为 nil 的话表示刷新失败，或者该用户不存在。
 */
+ (void)refreshLocalClientWithCustomizedId:(NSString *)customizedId complete:(void(^)(NSString *clientId))action;

/**
 判断用户是否在等待
 */
+ (int)waitingInQueuePosition;

/**
 获取当前用户在等待队列的位置
 */
+ (void)getClientQueuePositionComplete:(void (^)(NSInteger position, NSError *error))action;

/**
 
 */
+ (void)requestPreChatServeyDataIfNeedCompletion:(void(^)(LGPreChatData *data, NSError *error))block;

/**
 获取验证码
 */
+ (void)getCaptchaComplete:(void(^)(NSString *token, UIImage *image))block;

+ (void)getCaptchaWithURLComplete:(void (^)(NSString *token, NSString *url))block;

+ (void)submitPreChatForm:(NSDictionary *)formData completion:(void(^)(id,NSError *))block;


/**
 判断上一步操作是否失败
 */
+ (NSError *)checkGlobalError;

/**
 转换 emoji 别名为 Unicode
 */
+ (NSString *)convertToUnicodeWithEmojiAlias:(NSString *)text;


@end

