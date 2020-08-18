//
//  LGChatViewManager.m
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/27.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import "LGChatViewManager.h"
#import "LGImageUtil.h"
#import "LGServiceToViewInterface.h"
#import "LGTransitioningAnimation.h"
#import "LGAssetUtil.h"

@interface LGChatViewManager()

@property(nonatomic, strong) LGChatViewController *chatViewController;

@end

@implementation LGChatViewManager  {
    LGChatViewConfig *chatViewConfig;
}

//以下属性将直接转发给 LGChatViewConfig 来管理
@dynamic keepAudioSessionActive;
@dynamic playMode;
@dynamic recordMode;
@dynamic chatViewStyle;
@dynamic preSendMessages;

- (id)forwardingTargetForSelector:(SEL)aSelector {
    return chatViewConfig;
}

- (instancetype)init {
    if (self = [super init]) {
        chatViewConfig = [LGChatViewConfig sharedConfig];
    }
    return self;
}

- (LGChatViewController *)pushLGChatViewControllerInViewController:(UIViewController *)viewController {
    [self presentOnViewController:viewController transiteAnimation:LGTransiteAnimationTypePush];
    return self.chatViewController;
}

- (LGChatViewController *)presentLGChatViewControllerInViewController:(UIViewController *)viewController {
    chatViewConfig.isPushChatView = false;
    
    [self presentOnViewController:viewController transiteAnimation:LGTransiteAnimationTypeDefault];
    return self.chatViewController;
}

- (LGChatViewController *)createLGChatViewController {
    UINavigationController *viewController = [[UINavigationController alloc] initWithRootViewController:self.chatViewController];
    [self updateNavAttributesWithViewController:self.chatViewController navigationController:(UINavigationController *)viewController defaultNavigationController:nil isPresentModalView:false];
    return (LGChatViewController *)viewController.topViewController;
}

- (void)presentOnViewController:(UIViewController *)rootViewController transiteAnimation:(LGTransiteAnimationType)animation {
    chatViewConfig.presentingAnimation = animation;
    
    UIViewController *viewController = nil;
    if (animation == LGTransiteAnimationTypePush) {
        viewController = [self createNavigationControllerWithWithAnimationSupport:self.chatViewController presentedViewController:rootViewController];
        BOOL shouldUseUIKitAnimation = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7;
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [rootViewController presentViewController:viewController animated:shouldUseUIKitAnimation completion:nil];
    } else {
        viewController = [[UINavigationController alloc] initWithRootViewController:self.chatViewController];
        viewController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self updateNavAttributesWithViewController:self.chatViewController navigationController:(UINavigationController *)viewController defaultNavigationController:rootViewController.navigationController isPresentModalView:true];
        [rootViewController presentViewController:viewController animated:YES completion:nil];
    }
}

- (UINavigationController *)createNavigationControllerWithWithAnimationSupport:(LGChatViewController *)rootViewController presentedViewController:(UIViewController *)presentedViewController{
    UINavigationController *navigationController = [[UINavigationController alloc]initWithRootViewController:rootViewController];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        [self updateNavAttributesWithViewController:rootViewController navigationController:(UINavigationController *)navigationController defaultNavigationController:rootViewController.navigationController isPresentModalView:true];
        [navigationController setTransitioningDelegate:[LGTransitioningAnimation transitioningDelegateImpl]];
//        [navigationController setModalPresentationStyle:UIModalPresentationCustom];
    } else {
        [self updateNavAttributesWithViewController:self.chatViewController navigationController:(UINavigationController *)navigationController defaultNavigationController:rootViewController.navigationController isPresentModalView:true];
        [rootViewController.view.window.layer addAnimation:[LGTransitioningAnimation createPresentingTransiteAnimation:[LGChatViewConfig sharedConfig].presentingAnimation] forKey:nil];
    }
    return navigationController;
}

//修改导航栏属性
- (void)updateNavAttributesWithViewController:(LGChatViewController *)viewController
                         navigationController:(UINavigationController *)navigationController
                  defaultNavigationController:(UINavigationController *)defaultNavigationController
                           isPresentModalView:(BOOL)isPresentModalView {
    if ([LGChatViewConfig sharedConfig].navBarTintColor) {
        navigationController.navigationBar.tintColor = [LGChatViewConfig sharedConfig].navBarTintColor;
    } else if (defaultNavigationController && defaultNavigationController.navigationBar.tintColor) {
        navigationController.navigationBar.tintColor = defaultNavigationController.navigationBar.tintColor;
    }
    
    if (defaultNavigationController.navigationBar.titleTextAttributes) {
        navigationController.navigationBar.titleTextAttributes = defaultNavigationController.navigationBar.titleTextAttributes;
    } else {
        UIColor *color = [LGChatViewConfig sharedConfig].navTitleColor ?: [[UINavigationBar appearance].titleTextAttributes objectForKey:NSForegroundColorAttributeName] ?: [UIColor blackColor];
        UIFont *font = [LGChatViewConfig sharedConfig].chatViewStyle.navTitleFont ?: [[UINavigationBar appearance].titleTextAttributes objectForKey:NSFontAttributeName] ?: [UIFont systemFontOfSize:16.0];
        NSDictionary *attr = @{NSForegroundColorAttributeName : color, NSFontAttributeName : font};
        navigationController.navigationBar.titleTextAttributes = attr;
    }
    
    if ([LGChatViewConfig sharedConfig].chatViewStyle.navBarBackgroundImage) {
        [navigationController.navigationBar setBackgroundImage:[LGChatViewConfig sharedConfig].chatViewStyle.navBarBackgroundImage forBarMetrics:UIBarMetricsDefault];
    } else if ([LGChatViewConfig sharedConfig].navBarColor) {
        navigationController.navigationBar.barTintColor = [LGChatViewConfig sharedConfig].navBarColor;
    } else if (defaultNavigationController && defaultNavigationController.navigationBar.barTintColor) {
        navigationController.navigationBar.barTintColor = defaultNavigationController.navigationBar.barTintColor;
    }
    
    if (isPresentModalView) {
        //导航栏左键
        UIBarButtonItem *customizedBackItem = nil;
        if ([LGChatViewConfig sharedConfig].chatViewStyle.navBackButtonImage) {
//            customizedBackItem = [[UIBarButtonItem alloc]initWithImage:[LGChatViewConfig sharedConfig].chatViewStyle.navBackButtonImage style:(UIBarButtonItemStylePlain) target:viewController action:@selector(dismissChatViewController)];
            //xlp
            customizedBackItem = [[UIBarButtonItem alloc] initWithImage:[[LGChatViewConfig sharedConfig].chatViewStyle.navBackButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] style:UIBarButtonItemStylePlain target:viewController action:@selector(dismissChatViewController)];
        }
        
        if ([LGChatViewConfig sharedConfig].presentingAnimation == LGTransiteAnimationTypeDefault) {
            viewController.navigationItem.leftBarButtonItem = customizedBackItem ?: [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:viewController action:@selector(dismissChatViewController)];
        } else {
            viewController.navigationItem.leftBarButtonItem = customizedBackItem ?: [[UIBarButtonItem alloc] initWithImage:[LGAssetUtil backArrow] style:UIBarButtonItemStylePlain target:viewController action:@selector(dismissChatViewController)];
            
        }
    }
    
    //导航栏右键
    if ([LGChatViewConfig sharedConfig].navBarRightButton) {
        [[LGChatViewConfig sharedConfig].navBarRightButton addTarget:viewController action:@selector(didSelectNavigationRightButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    //导航栏标题
    if ([LGChatViewConfig sharedConfig].navTitleText) {
        viewController.navigationItem.title = [LGChatViewConfig sharedConfig].navTitleText;
    }
}

- (void)disappearLGChatViewController {
    if (!_chatViewController) {
        return ;
    }
    [self.chatViewController dismissChatViewController];
}

- (void)hidesBottomBarWhenPushed:(BOOL)hide
{
    chatViewConfig.hidesBottomBarWhenPushed = hide;
}

//- (void)enableCustomChatViewFrame:(BOOL)enable {
//    chatViewConfig.isCustomizedChatViewFrame = enable;
//}

- (void)setChatViewFrame:(CGRect)viewFrame {
    chatViewConfig.chatViewFrame = viewFrame;
}

- (void)setViewControllerPoint:(CGPoint)viewPoint {
    chatViewConfig.chatViewControllerPoint = viewPoint;
}

- (void)setPlayMode:(LGPlayMode)playMode {
    chatViewConfig.playMode = playMode;
}

- (LGPlayMode)playMode {
    return chatViewConfig.playMode;
}

- (void)setMessageNumberRegex:(NSString *)numberRegex {
    if (!numberRegex) {
        return;
    }
    [chatViewConfig.numberRegexs addObject:numberRegex];
}

- (void)setMessageLinkRegex:(NSString *)linkRegex {
    if (!linkRegex) {
        return;
    }
    [chatViewConfig.linkRegexs addObject:linkRegex];
}

- (void)setMessageEmailRegex:(NSString *)emailRegex {
    if (!emailRegex) {
        return;
    }
    [chatViewConfig.emailRegexs addObject:emailRegex];
}

- (void)enableEventDispaly:(BOOL)enable {
    chatViewConfig.enableEventDispaly = enable;
}

- (void)enableSendVoiceMessage:(BOOL)enable {
    chatViewConfig.enableSendVoiceMessage = enable;
}

- (void)enableSendImageMessage:(BOOL)enable {
    chatViewConfig.enableSendImageMessage = enable;
}

- (void)enableSendEmoji:(BOOL)enable {
    chatViewConfig.enableSendEmoji = enable;
}

- (void)enableShowNewMessageAlert:(BOOL)enable {
    chatViewConfig.enableShowNewMessageAlert = enable;
}

- (void)setIncomingMessageTextColor:(UIColor *)textColor {
    if (!textColor) {
        return;
    }
    chatViewConfig.incomingMsgTextColor = [textColor copy];
}

- (void)setIncomingBubbleColor:(UIColor *)bubbleColor {
    if (!bubbleColor) {
        return;
    }
    chatViewConfig.incomingBubbleColor = bubbleColor;
}

- (void)setOutgoingMessageTextColor:(UIColor *)textColor {
    if (!textColor) {
        return;
    }
    chatViewConfig.outgoingMsgTextColor = [textColor copy];
}

- (void)setOutgoingBubbleColor:(UIColor *)bubbleColor {
    if (!bubbleColor) {
        return;
    }
    chatViewConfig.outgoingBubbleColor = bubbleColor;
}

- (void)enableMessageImageMask:(BOOL)enable
{
    chatViewConfig.enableMessageImageMask = enable;
}

- (void)setEventTextColor:(UIColor *)textColor {
    if (!textColor) {
        return;
    }
    chatViewConfig.eventTextColor = [textColor copy];
}

- (void)setNavigationBarTintColor:(UIColor *)tintColor {
    if (!tintColor) {
        return;
    }
    chatViewConfig.navBarTintColor = [tintColor copy];
}

- (void)setNavigationBarTitleColor:(UIColor *)tintColor {
    chatViewConfig.navTitleColor = tintColor;
}

- (void)setNavigationBarColor:(UIColor *)barColor {
    if (!barColor) {
        return;
    }
    chatViewConfig.navBarColor = [barColor copy];
}

- (void)setNavTitleColor:(UIColor *)titleColor {
    if (!titleColor) {
        return;
    }
    chatViewConfig.navTitleColor = titleColor;
}

- (void)setPullRefreshColor:(UIColor *)pullRefreshColor {
    if (!pullRefreshColor) {
        return;
    }
    chatViewConfig.pullRefreshColor = pullRefreshColor;
}

- (void)setChatWelcomeText:(NSString *)welcomText {

    if (!welcomText) {
        return;
    }
    NSString *str = [welcomText stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (str.length <= 0){
        return;
    }
    chatViewConfig.chatWelcomeText = [welcomText copy];
}

- (void)setAgentName:(NSString *)agentName {
    if (!agentName) {
        return;
    }
    chatViewConfig.agentName = [agentName copy];
}

- (void)enableIncomingAvatar:(BOOL)enable {
    chatViewConfig.enableIncomingAvatar = enable;
}

- (void)enableOutgoingAvatar:(BOOL)enable {
    chatViewConfig.enableOutgoingAvatar = enable;
}

- (void)setincomingDefaultAvatarImage:(UIImage *)image {
    if (!image) {
        return;
    }
    chatViewConfig.incomingDefaultAvatarImage = image;
}

- (void)setoutgoingDefaultAvatarImage:(UIImage *)image {
    if (!image) {
        return;
    }
    chatViewConfig.outgoingDefaultAvatarImage = image;
#ifdef INCLUDE_LAIGU_SDK
    [LGServiceToViewInterface uploadClientAvatar:image completion:^(NSString *avatarUrl, NSError *error) {
    }];
#endif
}

- (void)setPhotoSenderImage:(UIImage *)image
           highlightedImage:(UIImage *)highlightedImage
{
    if (image) {
        chatViewConfig.photoSenderImage = image;
    }
    if (highlightedImage) {
        chatViewConfig.photoSenderHighlightedImage = highlightedImage;
    }
}

- (void)setVoiceSenderImage:(UIImage *)image
           highlightedImage:(UIImage *)highlightedImage
{
    if (image) {
        chatViewConfig.voiceSenderImage = image;
    }
    if (highlightedImage) {
        chatViewConfig.voiceSenderHighlightedImage = highlightedImage;
    }
}

- (void)setTextSenderImage:(UIImage *)image
          highlightedImage:(UIImage *)highlightedImage
{
    if (image) {
        chatViewConfig.keyboardSenderImage = image;
    }
    if (highlightedImage) {
        chatViewConfig.keyboardSenderHighlightedImage = highlightedImage;
    }
}

- (void)setResignKeyboardImage:(UIImage *)image
              highlightedImage:(UIImage *)highlightedImage
{
    if (image) {
        chatViewConfig.resignKeyboardImage = image;
    }
    if (highlightedImage) {
        chatViewConfig.resignKeyboardHighlightedImage = highlightedImage;
    }
}

- (void)setIncomingBubbleImage:(UIImage *)bubbleImage {
    if (!bubbleImage) {
        return;
    }
    chatViewConfig.incomingBubbleImage = bubbleImage;
}

- (void)setOutgoingBubbleImage:(UIImage *)bubbleImage {
    if (!bubbleImage) {
        return;
    }
    chatViewConfig.outgoingBubbleImage = bubbleImage;
}

- (void)setBubbleImageStretchInsets:(UIEdgeInsets)stretchInsets {
    chatViewConfig.bubbleImageStretchInsets = stretchInsets;
}

- (void)setNavRightButton:(UIButton *)rightButton {
    if (!rightButton) {
        return;
    }
    chatViewConfig.navBarRightButton = rightButton;
}

- (void)setNavLeftButton:(UIButton *)leftButton {
    if (!leftButton) {
        return;
    }
    chatViewConfig.navBarLeftButton = leftButton;
}

- (void)setNavTitleText:(NSString *)titleText {
    if (!titleText) {
        return;
    }
    chatViewConfig.navTitleText = titleText;
}

- (void)enableMessageSound:(BOOL)enable {
    chatViewConfig.enableMessageSound = enable;
}

- (void)enableTopPullRefresh:(BOOL)enable {
    chatViewConfig.enableTopPullRefresh = enable;
}

- (void)enableRoundAvatar:(BOOL)enable {
    chatViewConfig.enableRoundAvatar = enable;
}

- (void)enableTopAutoRefresh:(BOOL)enable {
    chatViewConfig.enableTopAutoRefresh = enable;
}

- (void)enableBottomPullRefresh:(BOOL)enable {
    chatViewConfig.enableBottomPullRefresh = enable;
}

- (void)enableChatWelcome:(BOOL)enable {
    chatViewConfig.enableChatWelcome = enable;
}

- (void)enableVoiceRecordBlurView:(BOOL)enable {
    chatViewConfig.enableVoiceRecordBlurView = enable;
}

- (void)setIncomingMessageSoundFileName:(NSString *)soundFileName {
    if (!soundFileName) {
        return;
    }
    chatViewConfig.incomingMsgSoundFileName = soundFileName;
}

- (void)setOutgoingMessageSoundFileName:(NSString *)soundFileName {
    if (!soundFileName) {
        return;
    }
    chatViewConfig.outgoingMsgSoundFileName = soundFileName;
}

- (void)setMaxRecordDuration:(NSTimeInterval)recordDuration {
    chatViewConfig.maxVoiceDuration = recordDuration;
}

- (void)setStatusBarStyle:(UIStatusBarStyle)statusBarStyle {
    chatViewConfig.statusBarStyle = statusBarStyle;
    chatViewConfig.didSetStatusBarStyle = true;
}

#ifdef INCLUDE_LAIGU_SDK
- (void)enableSyncServerMessage:(BOOL)enable {
    chatViewConfig.enableSyncServerMessage = enable;
}

- (void)setScheduledAgentId:(NSString *)agentId {
    if (!agentId) {
        return;
    }
    chatViewConfig.scheduledAgentId = agentId;
}

- (void)setNotScheduledAgentId:(NSString *)agentId {
    if (!agentId) {
        return;
    }
    chatViewConfig.notScheduledAgentId = agentId;
}

- (void)setScheduledGroupId:(NSString *)groupId {
    if (!groupId) {
        return;
    }
    chatViewConfig.scheduledGroupId = groupId;
}

- (void)setScheduleLogicWithRule:(LGChatScheduleRules)scheduleRule {
    chatViewConfig.scheduleRule = scheduleRule;
}

- (void)setLoginCustomizedId:(NSString *)customizedId {
    if (!customizedId) {
        return;
    }
    chatViewConfig.customizedId = customizedId;
}

- (void)setLoginLGClientId:(NSString *)LGClientId {
    if (!LGClientId) {
        return;
    }
    chatViewConfig.LGClientId = LGClientId;
}

- (void)enableEvaluationButton:(BOOL)enable {
    chatViewConfig.enableEvaluationButton = enable;
}

- (void)setClientInfo:(NSDictionary *)clientInfo override:(BOOL)override {
    if (!clientInfo) {
        return;
    }
    chatViewConfig.updateClientInfoUseOverride = override;
    chatViewConfig.clientInfo = clientInfo;
}

- (void)setClientInfo:(NSDictionary *)clientInfo {
    if (!clientInfo) {
        return;
    }
    chatViewConfig.clientInfo = clientInfo;
}

#endif

- (LGChatViewController *)chatViewController {
    if (!_chatViewController) {
        _chatViewController = [[LGChatViewController alloc] initWithChatViewManager:chatViewConfig];
    }
    return _chatViewController;
}

@end
