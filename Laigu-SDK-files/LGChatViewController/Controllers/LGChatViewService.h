//
//  LGChatViewService.h
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/28.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGBaseMessage.h"
#import <UIKit/UIKit.h>
#import "LGChatViewConfig.h"
#import "LGCellModelProtocol.h"
#ifdef INCLUDE_LAIGU_SDK
#import "LGServiceToViewInterface.h"
#endif

@protocol LGChatViewServiceDelegate <NSObject>


/**
 *  获取到了更多历史消息
 *
 *  @param cellNumber 需要显示的cell数量
 *  @param isLoadOver 是否已经获取完了历史消息
 */
- (void)didGetHistoryMessagesWithCommitTableAdjustment:(void(^)(void))commit;

/**
 *  已经更新了这条消息的数据，通知tableView刷新界面
 */
- (void)didUpdateCellModelWithIndexPath:(NSIndexPath *)indexPath needToBottom:(BOOL)toBottom;

/**
 *  通知viewController更新tableView；
 */
- (void)reloadChatTableView;



/*
 call after add model
 */
- (void)insertCellAtBottomForModelCount:(NSInteger)count;

- (void)insertCellAtTopForModelCount:(NSInteger)count;

- (void)removeCellAtIndex:(NSInteger)index;

- (void)insertCellAtCurrentIndex:(NSInteger)currentRow modelCount:(NSInteger)count;

/**
 *  通知viewController将tableView滚动到底部
 */
- (void)scrollTableViewToBottomAnimated:(BOOL)animated;

/**
 *  通知viewController收到了消息
 */
- (void)didReceiveMessage;

/**
 *  通知viewController显示toast
 *
 *  @param content 显示的文字
 */
- (void)showToastViewWithContent:(NSString *)content;

/**
 *  通知 viewController 显示评价的 AlertView
 */
- (void)showEvaluationAlertView;

/**
 *  判断当前是否正在录音
 */
- (BOOL)isChatRecording;

#ifdef INCLUDE_LAIGU_SDK
/**
 *  通知viewController已经为顾客分配了一个客服，更新title
 *
 *  @param viewTitle 客服名字
 */
- (void)didScheduleClientWithViewTitle:(NSString *)viewTitle agentStatus:(LGChatAgentStatus)agentStatus;

/**
 *  根据 agentType 改变导航栏右键
 */
- (void)changeNavReightBtnWithAgentType:(NSString *)agentType hidden:(BOOL)hidden;

#endif

@end

/**
 * @brief 聊天界面的ViewModel
 *
 * LGChatViewService管理者LGChatViewController中的数据
 */
@interface LGChatViewService : NSObject

#ifdef INCLUDE_LAIGU_SDK
/**
 *  后端返回的数据的错误委托方法
 */
@property (nonatomic, weak) id<LGServiceToViewInterfaceErrorDelegate> errorDelegate;
#endif

/** LGChatViewService的委托 */
@property (nonatomic, weak) id<LGChatViewServiceDelegate> delegate;

/** cellModel的缓存 */
@property (nonatomic, strong) NSMutableArray *cellModels;

/** 聊天界面的宽度 */
@property (nonatomic, assign) CGFloat chatViewWidth;

/** 顾客当前的状态 */
@property (nonatomic, assign) LGState clientStatus;

- (instancetype)initWithDelegate:(id<LGChatViewServiceDelegate>)delegate errorDelegate:(id<LGServiceToViewInterfaceErrorDelegate>)errorDelegate;

/**
 增加cellModel并刷新tableView
 */
- (void)addCellModelAndReloadTableViewWithModel:(id<LGCellModelProtocol>)cellModel;

/**
 * 获取更多历史聊天消息
 */
- (void)startGettingHistoryMessages;
- (void)startGettingDateBaseHistoryMessages;
- (void)startGettingHistoryMessagesFromLastMessage;

/**
 * 在开启无消息访客过滤的条件下获取历史聊天信息
 */
- (void)getMessagesWithScheduleAfterClientSendMessage;

/**
 * 发送文字消息
 */
- (void)sendTextMessageWithContent:(NSString *)content;

/**
 * 发送图片消息
 */
- (void)sendImageMessageWithImage:(UIImage *)image;

/**
 * 以AMR格式语音文件的形式，发送语音消息
 * @param filePath AMR格式的语音文件
 */
- (void)sendVoiceMessageWithAMRFilePath:(NSString *)filePath;

/**
 * 发送“用户正在输入”的消息
 */
- (void)sendUserInputtingWithContent:(NSString *)content;


/**
  删除消息
 */
- (void)deleteMessageAtIndex:(NSInteger)index withTipMsg:(NSString *)tipMsg enableLinesDisplay:(BOOL)enable;

/**
 * 重新发送消息
 * @param index 需要重新发送的index
 * @param resendData 重新发送的字典 [text/image/voice : data]
 */
- (void)resendMessageAtIndex:(NSInteger)index resendData:(NSDictionary *)resendData;

/**
 *  更新cellModel中的frame，针对转屏的场景
 */
- (void)updateCellModelsFrame;

/**
 *  发送本地欢迎语消息
 *  @warnning 该消息不需要发送给后端
 */
- (void)sendLocalWelcomeChatMessage;

/**
 *  点击了某个消息
 *
 *  @param index 点击的消息index
 */
- (void)didTapMessageCellAtIndex:(NSInteger)index;

/**
 *  刷新所有的本机用户的头像
 */
- (void)refreshOutgoingAvatarWithImage:(UIImage *)avatarImage;

/**
 *  发送用户评价
 */
- (void)sendEvaluationLevel:(NSInteger)level comment:(NSString *)comment;

/**
 * dismiss View Controller
 */
- (void)dismissingChatViewController;

/**
 *  获取之前的输入文字
 */
- (NSString *)getPreviousInputtingText;

/**
 *  设置当前输入的文字
 */
- (void)setCurrentInputtingText:(NSString *)inputtingText;

/**
 *  评价机器人消息
 */
- (void)evaluateBotAnswer:(BOOL)isUseful messageId:(NSString *)messageId;

/**
 *  强制转接人工客服
 */
- (void)forceRedirectToHumanAgent;

/**
 保存用户输入的文字为草稿
 */
- (void)saveTextDraftIfNeeded:(UITextField *)tf;

/**
 恢复用户保存的草稿
 */
- (void)fillTextDraftToFiledIfExists:(UITextField *)tf;

/**
 手动上线当前顾客
 */
- (void)setClientOnline;

/**
初始化历史消息
*/
- (void)onceLoadHistoryAndRefreshWithSendMsg:(NSString *)message;

/**
 顾客没上线前缓存需要发送的Text
 */
- (void)cacheSendText:(NSString *)text;

/**
 顾客没上线前缓存需要发送的Image
 */
- (void)cacheSendImage:(UIImage *)image;

/**
 顾客没上线前缓存需要发送的语音
 */
- (void)cacheSendAMRFilePath:(NSString *)filePath;

#ifndef INCLUDE_LAIGU_SDK
/**
 * 使用LGChatViewControllerDemo的时候，调试用的方法，用于收取和上一个message一样的消息
 */
- (void)loadLastMessage;


#else


#endif

@end
