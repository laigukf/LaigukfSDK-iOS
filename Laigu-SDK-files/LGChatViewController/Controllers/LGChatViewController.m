//
//  LGChatViewController.m
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/28.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LGChatViewController.h"
#import "LGChatViewTableDataSource.h"
#import "LGChatViewService.h"
#import "LGCellModelProtocol.h"
#import "LGChatDeviceUtil.h"
#import "LGBottomBar.h"
#import "LGTabInputContentView.h"
#import "LGKeyboardController.h"
#import "LGToast.h"
#import "LGRecordView.h"
#import "LGBundleUtil.h"
#import "LGImageUtil.h"
#import <LaiGuSDK/LGDefinition.h>
#import "LGEvaluationView.h"
#import "LGAssetUtil.h"
#import "LGStringSizeUtil.h"
#import "LGTransitioningAnimation.h"
#import "UIView+LGLayout.h"
#import "LGCustomizedUIText.h"
#import "LGImageUtil.h"
#import "LGRecorderView.h"
#import "LGMessageFormViewManager.h"
#import "LGPreChatFormListViewController.h"
#import "LGRefresh.h"
#import "LGTextCellModel.h"
#import "LGTipsCellModel.h"
#import "LGRichTextViewModel.h"
#import "LGWebViewBubbleCellModel.h"
#import "LGToolUtil.h"
#import "LGChatViewManager.h"
#import <LaiGuSDK/LGManager.h>
#import "LG_InputView.h"
#import "LGCellModelProtocol.h"
static CGFloat const kLGChatViewInputBarHeight = 80.0;

@interface LGChatViewController () <UITableViewDelegate, LGChatViewServiceDelegate, LGBottomBarDelegate, UIImagePickerControllerDelegate, LGChatTableViewDelegate, LGChatCellDelegate, LGServiceToViewInterfaceErrorDelegate,UINavigationControllerDelegate, LGEvaluationViewDelegate, LGInputContentViewDelegate, LGKeyboardControllerDelegate, LGRecordViewDelegate, LGRecorderViewDelegate,LG_InputViewDelegate>

@property(nonatomic, strong)LGChatViewService *chatViewService;

@end

@interface LGChatViewController()

@property (nonatomic, strong) id evaluateBarButtonItem;//保存隐藏的barButtonItem
@property (nonatomic, strong) LGBottomBar *bottomBar;
@property (nonatomic, strong) NSLayoutConstraint *constaintInputBarHeight;
@property (nonatomic, strong) NSLayoutConstraint *constraintInputBarBottom;
@property (nonatomic, strong) LGEvaluationView *evaluationView;
@property (nonatomic, strong) LGKeyboardController *keyboardView;
@property (nonatomic, strong) LGRecordView *recordView;
@property (nonatomic, strong) LGRecorderView *displayRecordView;//只用来显示

@end

@implementation LGChatViewController {
    LGChatViewConfig *chatViewConfig;
    LGChatViewTableDataSource *tableDataSource;
    BOOL isLGCommunicationFailed;  //判断是否通信没有连接上
    UIStatusBarStyle previousStatusBarStyle;//当前statusBar样式
    BOOL previousStatusBarHidden;   //调出聊天视图界面前是否隐藏 statusBar
    NSTimeInterval sendTime;        //发送时间，用于限制发送频率
    UIView *translucentView;        //loading 的半透明层
    UIActivityIndicatorView *activityIndicatorView; //loading
    
    //xlp  是否开启访客无消息过滤的标志
    BOOL openVisitorNoMessageBool; // 默认值 在presentUI里分2种情况初始化 在发送各种消息前检测 若为真 打开 则需手动上线  若为假 则不做操作
    
    BOOL shouldSendInputtingMessageToServer;
    BOOL willDisapper; // 页面即将消失
}

- (void)dealloc {
    [self removeDelegateAndObserver];
    [chatViewConfig setConfigToDefault];
    [self.chatViewService setCurrentInputtingText:[(LGTabInputContentView *)self.bottomBar.contentView textField].text];
    [self closeLaiguChatView];
    [LGCustomizedUIText reset];
    [LGServiceToViewInterface completeChat];
}

- (instancetype)initWithChatViewManager:(LGChatViewConfig *)config {
    if (self = [super init]) {
        chatViewConfig = config;
    }
    return  self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [LGServiceToViewInterface prepareForChat];
    
    // Do any additional setup after loading the view.
    previousStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;
    previousStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:[LGChatViewConfig sharedConfig].chatViewStyle.statusBarStyle];
    [self setNeedsStatusBarAppearanceUpdate];
    
    sendTime = [NSDate timeIntervalSinceReferenceDate];
    self.view.backgroundColor = [LGChatViewConfig sharedConfig].chatViewStyle.backgroundColor ?: [UIColor colorWithWhite:0.95 alpha:1];
    [self initChatTableView];
    [self initInputBar];
    [self layoutViews];
    [self initchatViewService];
    [self initTableViewDataSource];
    
    
    self.chatViewService.chatViewWidth = self.chatTableView.frame.size.width;
    
#ifdef INCLUDE_LAIGU_SDK
    //[self updateNavBarTitle:[LGBundleUtil localizedStringForKey:@"wait_agent"]];
    isLGCommunicationFailed = NO;
    [self addObserver];
#endif
    
    if ([LGChatViewConfig sharedConfig].presentingAnimation == LGTransiteAnimationTypePush) {
        UIScreenEdgePanGestureRecognizer *popRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePopRecognizer:)];
        popRecognizer.edges = UIRectEdgeLeft;
        [self.view addGestureRecognizer:popRecognizer];
    }
    
    [self presentUI];
    
    shouldSendInputtingMessageToServer = YES;
    
    
}

- (void)presentUI {
    
    [LGPreChatFormListViewController usePreChatFormIfNeededOnViewController:self compeletion:^(NSDictionary *userInfo){
        
        // 询前表单界面返回的数据，如果未进入表单，则为空,如果进入表单则userInfo为表单提交信息
        /**
         {
         menu = "价格";
         target = dbd2e3a951bb7563873e9223073c5149;
         targetType = agent;
         }
         */
        NSString *targetType = userInfo[@"targetType"];
        NSString *target = userInfo[@"target"];
        NSString *menu = userInfo[@"menu"];
        if ([targetType isEqualToString:@"agent"]) {
            [LGChatViewConfig sharedConfig].scheduledAgentId = target;
        } else if ([targetType isEqualToString:@"group"]) {
            [LGChatViewConfig sharedConfig].scheduledGroupId = target;
        }
        if ([menu length] > 0) {
            NSMutableArray *m = [[LGChatViewConfig sharedConfig].preSendMessages mutableCopy] ?: [NSMutableArray new];
            [m addObject:menu];
            [LGChatViewConfig sharedConfig].preSendMessages = m;
        }
        // TODO: [LGServiceToViewInterface prepareForChat]也会初始化企业配置，这里会导致获取企业配置的接口调用两次,APP第一次初始化时会调3次
        [LGServiceToViewInterface getEnterpriseConfigInfoWithCache:YES complete:^(LGEnterprise *enterprise, NSError *e) {
            
            // warning:用之前的绑定的clientId上线,防止出现排队现象
            // 企业配置字段scheduler_after_client_send_msg：客户（访客）是否开启无响应时消息
            if (enterprise.configInfo.isScheduleAfterClientSendMessage && ![LGServiceToViewInterface haveConversation]) {
                
                // 设置head title
                [self updateNavTitleWithAgentName:enterprise.configInfo.public_nickname ?: @"官方客服" agentStatus:LGChatAgentStatusNone];
                
                // 设置欢迎语 设置企业头像
                NSString *welcomeStr = enterprise.configInfo.enterpriseIntro;
                NSString *str = [welcomeStr stringByReplacingOccurrencesOfString:@" " withString:@""];
                if (enterprise.configInfo.enterpriseIntro && str.length > 0) {
                    
                    NSDictionary *accessory = @{
                        @"summary":@"",
                        @"thumbnail":@"",
                        @"content":enterprise.configInfo.enterpriseIntro ?: @"【系统消息】您好，请问您有什么问题?"
                    };
                    LGRichTextMessage *message = [[LGRichTextMessage alloc] initWithDictionary:accessory];
                    message.fromType = LGChatMessageIncoming;
                    message.date = [NSDate new];
                    message.userName = enterprise.configInfo.public_nickname;
                    message.userAvatarPath = enterprise.configInfo.avatar;
                    message.sendStatus = LGChatMessageSendStatusSuccess;
                    message.content = enterprise.configInfo.enterpriseIntro;
                    LGWebViewBubbleCellModel *cellModel = [[LGWebViewBubbleCellModel alloc] initCellModelWithMessage:message cellWidth:self.chatViewService.chatViewWidth delegate:(id <LGCellModelDelegate>)self.chatViewService];
                    
                    [self.chatViewService addCellModelAndReloadTableViewWithModel:cellModel];
                }
                
                
                // 加载历史消息
                [self.chatViewService getMessagesWithScheduleAfterClientSendMessage];
                
                // 注册通知
                // TODO: 这个通知什么时候回调（客服离开、隐身、结束对话都不会触发）
                [LGManager addStateObserverWithBlock:^(LGState oldState, LGState newState, NSDictionary *value, NSError *error) {
                    if (newState == LGStateUnallocatedAgent) { // 离线
//                        [LGManager setClientOffline];
                    }
                } withKey:@"LGChatViewController"];
                
                self->openVisitorNoMessageBool = YES;
                
            } else { // 如果未开启，直接让用户上线
                self->openVisitorNoMessageBool = NO;
                [self.chatViewService setClientOnline];
            }
        }];
    } cancle:^{
        //讯前表单 左返回按钮
        [self dismissViewControllerAnimated:NO completion:^{
            [self dismissChatViewController];
        }];
    }];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] postNotificationName:LGAudioPlayerDidInterruptNotification object:nil];
    
    //恢复原来的导航栏时间条
    [UIApplication sharedApplication].statusBarStyle = previousStatusBarStyle;
    
    [[UIApplication sharedApplication] setStatusBarHidden:previousStatusBarHidden];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.keyboardView beginListeningForKeyboard];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    
    willDisapper = YES;
    [self.keyboardView endListeningForKeyboard];
    
    if ([LGServiceToViewInterface waitingInQueuePosition] > 0) {
        [self.chatViewService saveTextDraftIfNeeded:(UITextField *)[(LGTabInputContentView *)self.bottomBar.contentView textField]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    willDisapper = NO;
    [UIView setAnimationsEnabled:YES];
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    [self.chatViewService fillTextDraftToFiledIfExists:(UITextField *)[(LGTabInputContentView *)self.bottomBar.contentView textField]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissChatViewController {
    if ([LGChatViewConfig sharedConfig].presentingAnimation == LGTransiteAnimationTypePush) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.view.window.layer addAnimation:[LGTransitioningAnimation createDismissingTransiteAnimation:[LGChatViewConfig sharedConfig].presentingAnimation] forKey:nil];
            [self dismissViewControllerAnimated:NO completion:nil];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)addObserver {
#ifdef INCLUDE_LAIGU_SDK
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRefreshOutgoingAvatarNotification:) name:LGChatTableViewShouldRefresh object:nil];
#endif
}

- (void)removeDelegateAndObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma 初始化viewModel
- (void)initchatViewService {
    self.chatViewService = [[LGChatViewService alloc] initWithDelegate:self errorDelegate:self];
}

#pragma 初始化tableView dataSource
- (void)initTableViewDataSource {
    tableDataSource = [[LGChatViewTableDataSource alloc] initWithChatViewService: self.chatViewService];
    tableDataSource.chatCellDelegate = self;
    self.chatTableView.dataSource = tableDataSource;
}

#pragma mark - 初始化所有Views
/**
 * 初始化聊天的tableView
 */
- (void)initChatTableView {
    self.chatTableView = [[LGChatTableView alloc] initWithFrame:chatViewConfig.chatViewFrame style:UITableViewStylePlain];
    self.chatTableView.chatTableViewDelegate = self;
    
    //xlp 修复 发送消息 或者受到消息 会弹一下
    self.chatTableView.estimatedRowHeight = 0;
    self.chatTableView.estimatedSectionFooterHeight = 0;
    self.chatTableView.estimatedSectionHeaderHeight = 0;
    
    if (@available(iOS 11.0, *)) {
        self.chatTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
    self.chatTableView.delegate = self;
    [self.view addSubview:self.chatTableView];
    
    __weak typeof(self) wself = self;
    [self.chatTableView setupPullRefreshWithAction:^{
        __strong typeof (wself) sself = wself;
        [sself.chatViewService startGettingHistoryMessages];
    }];
    
    [self.chatTableView.refreshView setText:[LGBundleUtil localizedStringForKey:@"pull_refresh_normal"] forStatus: LGRefreshStatusDraging];
    [self.chatTableView.refreshView setText:[LGBundleUtil localizedStringForKey:@"pull_refresh_triggered"] forStatus: LGRefreshStatusTriggered];
    [self.chatTableView.refreshView setText:[LGBundleUtil localizedStringForKey:@"no_more_messages"] forStatus: LGRefreshStatusEnd];
}

/**
 * 初始化聊天的inpur bar
 */
- (void)initInputBar {
    [self.view addSubview:self.bottomBar];
}

- (void)layoutViews {
    self.chatTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bottomBar.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSMutableArray *constrains = [NSMutableArray new];
    
    [constrains addObjectsFromArray:[self addFitWidthConstraintsToView:self.chatTableView onTo:self.view]];
    [constrains addObjectsFromArray:[self addFitWidthConstraintsToView:self.bottomBar onTo:self.view]];
    
    [constrains addObject:[NSLayoutConstraint constraintWithItem:self.chatTableView attribute:(NSLayoutAttributeTop) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:(NSLayoutAttributeTop) multiplier:1 constant:0]];
    [constrains addObject:[NSLayoutConstraint constraintWithItem:self.chatTableView attribute:(NSLayoutAttributeLeft) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:(NSLayoutAttributeLeft) multiplier:1 constant:0]];
    [constrains addObject:[NSLayoutConstraint constraintWithItem:self.chatTableView attribute:(NSLayoutAttributeRight) relatedBy:(NSLayoutRelationEqual) toItem:self.view attribute:(NSLayoutAttributeRight) multiplier:1 constant:0]];
    [constrains addObject:[NSLayoutConstraint constraintWithItem:self.chatTableView attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomBar attribute:(NSLayoutAttributeTop) multiplier:1 constant:0]];
    
    
    
    self.constraintInputBarBottom = [NSLayoutConstraint constraintWithItem:self.view attribute:(NSLayoutAttributeBottom) relatedBy:(NSLayoutRelationEqual) toItem:self.bottomBar attribute:(NSLayoutAttributeBottom) multiplier:1 constant: (LGToolUtil.kXlpObtainDeviceVersionIsIphoneX > 0 ? 34 : 0)];
    
    [constrains addObject:self.constraintInputBarBottom];
    [self.view addConstraints:constrains];
    
    self.constaintInputBarHeight = [NSLayoutConstraint constraintWithItem:self.bottomBar attribute:(NSLayoutAttributeHeight) relatedBy:(NSLayoutRelationEqual) toItem:nil attribute:(NSLayoutAttributeNotAnAttribute) multiplier:1 constant:kLGChatViewInputBarHeight];
    
    [self.bottomBar addConstraint:self.constaintInputBarHeight];
    
}

- (NSArray *)addFitWidthConstraintsToView:(UIView *)innerView onTo:(UIView *)outterView {
    return @[[NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeWidth relatedBy:(NSLayoutRelationEqual) toItem:outterView attribute:(NSLayoutAttributeWidth) multiplier:1 constant:0],
             [NSLayoutConstraint constraintWithItem:innerView attribute:NSLayoutAttributeCenterX relatedBy:(NSLayoutRelationEqual) toItem:outterView attribute:(NSLayoutAttributeCenterX) multiplier:1 constant:0]];
}

#pragma 添加消息通知的observer
- (void)setNotificationObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignKeyboardFirstResponder:) name:LGChatViewKeyboardResignFirstResponderNotification object:nil];
}

#pragma 消息通知observer的处理函数
- (void)resignKeyboardFirstResponder:(NSNotification *)notification {
    [self.view endEditing:true];
}

#pragma mark - LGChatTableViewDelegate

- (void)didTapChatTableView:(UITableView *)tableView {
    [self.view endEditing:true];
}

- (void)tapNavigationRightBtn:(id)sender {
    [self showEvaluationAlertView];
}

- (void)tapNavigationRedirectBtn:(id)sender {
    [self.chatViewService forceRedirectToHumanAgent];
    [self showActivityIndicatorView];
}

- (void)didSelectNavigationRightButton {
    NSLog(@"点击了自定义导航栏右键，开发者可在这里增加功能。");
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<LGCellModelProtocol> cellModel = [self.chatViewService.cellModels objectAtIndex:indexPath.row];
    return [cellModel getCellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0000001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.000001;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.chatTableView.refreshView.status == LGRefreshStatusTriggered) {
        [self.chatTableView startAnimation];
    }
}

- (void)didGetHistoryMessagesWithCommitTableAdjustment:(void(^)(void))commitTableAdjustment {
    __weak typeof(self) wself = self;
    [self.chatTableView stopAnimationCompletion:^{
        __strong typeof (wself) sself = wself;
        CGFloat oldHeight = sself.chatTableView.contentSize.height;
        commitTableAdjustment();
        CGFloat heightIncreatment = sself.chatTableView.contentSize.height - oldHeight;
        if (heightIncreatment > 0) {
            heightIncreatment -= sself.chatTableView.refreshView.bounds.size.height;
            sself.chatTableView.contentOffset = CGPointMake(0, heightIncreatment);
            [sself.chatTableView flashScrollIndicators];
        } else {
            [sself.chatTableView setLoadEnded];
        }
    }];
}

- (void)didUpdateCellModelWithIndexPath:(NSIndexPath *)indexPath needToBottom:(BOOL)toBottom {
    [self.chatTableView updateTableViewAtIndexPath:indexPath];
    toBottom ? [self chatTableViewScrollToBottomWithAnimated:false] : nil;
}

- (void)insertCellAtBottomForModelCount:(NSInteger)count {
    NSMutableArray *indexToAdd = [NSMutableArray new];
    NSInteger currentCellCount = [self.chatTableView numberOfRowsInSection: 0];
    for (int i = 0; i < count; i ++) {
        [indexToAdd addObject:[NSIndexPath indexPathForRow:currentCellCount + i inSection:0]];
    }
    [self.chatTableView insertRowsAtIndexPaths:indexToAdd withRowAnimation:(UITableViewRowAnimationBottom)];
}

- (void)insertCellAtTopForModelCount:(NSInteger)count {
    NSMutableArray *indexToAdd = [NSMutableArray new];
    for (int i = 0; i < count; i ++) {
        [indexToAdd insertObject:[NSIndexPath indexPathForRow:i inSection:0] atIndex: 0];
    }
    [self.chatTableView insertRowsAtIndexPaths:indexToAdd withRowAnimation:(UITableViewRowAnimationTop)];
}

- (void)insertCellAtCurrentIndex:(NSInteger)currentRow modelCount:(NSInteger)count {
    NSMutableArray *indexToAdd = [NSMutableArray new];
    for (int i = 0; i < count; i ++) {
        [indexToAdd addObject:[NSIndexPath indexPathForRow:currentRow + i inSection:0]];
    }
    
    [self.chatTableView insertRowsAtIndexPaths:indexToAdd withRowAnimation:UITableViewRowAnimationBottom];
}

- (void)removeCellAtIndex:(NSInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow: index inSection: 0];
    [self.chatTableView deleteRowsAtIndexPaths: @[indexPath] withRowAnimation: UITableViewRowAnimationFade];
}

- (void)reloadChatTableView {
    [self.chatTableView reloadData];
}

- (void)scrollTableViewToBottomAnimated:(BOOL)animated {
    [self chatTableViewScrollToBottomWithAnimated: animated];
}

- (void)showEvaluationAlertView {
    if (!willDisapper) {
        [self.view.window endEditing:YES];
        [self.evaluationView showEvaluationAlertView];
    }
}

- (BOOL)isChatRecording {
    return [self.recordView isRecording];
}

- (void)didScheduleClientWithViewTitle:(NSString *)viewTitle agentStatus:(LGChatAgentStatus)agentStatus{
    
    [self updateNavTitleWithAgentName:viewTitle agentStatus:agentStatus];
}

- (void)changeNavReightBtnWithAgentType:(NSString *)agentType hidden:(BOOL)hidden {
    // 隐藏 loading
    [self dismissActivityIndicatorView];
    __block UIBarButtonItem *item = nil;
    if ([agentType isEqualToString:@"bot"]) {
        [LGServiceToViewInterface getIsShowRedirectHumanButtonComplete:^(BOOL isShow, NSError *error) {
            if (isShow) {
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:[LGBundleUtil localizedStringForKey:@"laigu_redirect_sheet"] style:(UIBarButtonItemStylePlain) target:self action:@selector(tapNavigationRedirectBtn:)];
            }
        }];
        return;
    } else if ([LGChatViewConfig sharedConfig].navBarRightButton) {
        item = [[UIBarButtonItem alloc]initWithCustomView:[LGChatViewConfig sharedConfig].navBarRightButton];
    } else {
        if (![LGChatViewConfig sharedConfig].navBarRightButton && !hidden && [LGChatViewConfig sharedConfig].enableEvaluationButton) {
            item =  [[UIBarButtonItem alloc]initWithTitle:[LGBundleUtil localizedStringForKey:@"laigu_evaluation_sheet"] style:(UIBarButtonItemStylePlain) target:self action:@selector(tapNavigationRightBtn:)];
        }
    }
    
    self.navigationItem.rightBarButtonItem = item;
}

- (void)didReceiveMessage {
    //判断是否显示新消息提示  旧版本 是根据此时 是否已经滚动到底部,不在底部 则toast 提示新消息 否则直接显示最新消息
    if ([self.chatTableView isTableViewScrolledToBottom]) {
        [self chatTableViewScrollToBottomWithAnimated: YES];
    } else {
        if ([LGChatViewConfig sharedConfig].enableShowNewMessageAlert) {
            [LGToast showToast:[LGBundleUtil localizedStringForKey:@"display_new_message"] duration:1.5 window:[[UIApplication sharedApplication].windows lastObject]];
        }
    }
}

- (void)showToastViewWithContent:(NSString *)content {
    [LGToast showToast:content duration:1.0 window:self.view];
}




#pragma mark - LGInputBarDelegate

- (BOOL)sendMessagePrepareWithText:(NSString *)text image:(UIImage *)image andAMRFilePath:(NSString *)filePath {
    // 判断当前顾客是否正在登陆，如果正在登陆，显示禁止发送的提示
    if (self.chatViewService.clientStatus == LGStateAllocatingAgent || [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
        NSString *alertText = self.chatViewService.clientStatus == LGStateAllocatingAgent ? @"cannot_text_client_is_onlining" : @"send_to_fast";
        [LGToast showToast:[LGBundleUtil localizedStringForKey:alertText] duration:2 window:self.view.window];
        [[(LGTabInputContentView *)self.bottomBar.contentView textField] setText:text];
        return NO;
    }
    
    
    if (openVisitorNoMessageBool || self.chatViewService.clientStatus == LGStateUnallocatedAgent) {
        [self.view endEditing:YES];
        [self.chatViewService setClientOnline];
        
        if (text) {
            [self.chatViewService cacheSendText:text];
        } else if (image) {
            [self.chatViewService cacheSendImage:image];
        } else if (filePath) {
            [self.chatViewService cacheSendAMRFilePath:filePath];
        }
        
        openVisitorNoMessageBool = NO;
    }else{
        if (text) {
            [self.chatViewService sendTextMessageWithContent:text];
        } else if (image) {
            [self.chatViewService sendImageMessageWithImage:image];
        } else if (filePath) {
            [self.chatViewService sendVoiceMessageWithAMRFilePath:filePath];
        }
        sendTime = [NSDate timeIntervalSinceReferenceDate];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self chatTableViewScrollToBottomWithAnimated:YES];
        });
    }
    return YES;
}

// 发送文本消息
-(BOOL)sendTextMessage:(NSString*)text {
    // 判断当前顾客是否正在登陆，如果正在登陆，显示禁止发送的提示
    return [self sendMessagePrepareWithText:text image:nil andAMRFilePath:nil];
}

-(void)sendImageWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    NSString *mediaPermission = [LGChatDeviceUtil isDeviceSupportImageSourceType:(int)sourceType];
    if (!mediaPermission) {
        return;
    }
    if (![mediaPermission isEqualToString:@"ok"]) {
        [LGToast showToast:[LGBundleUtil localizedStringForKey:mediaPermission] duration:2 window:self.view];
        return;
    }
    
    // 判断当前顾客是否正在登陆，如果正在登陆，显示禁止发送的提示
    if (self.chatViewService.clientStatus == LGStateAllocatingAgent || [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
        NSString *alertText = self.chatViewService.clientStatus == LGStateAllocatingAgent ? @"cannot_text_client_is_onlining" : @"send_to_fast";
        [LGToast showToast:[LGBundleUtil localizedStringForKey:alertText] duration:2 window:self.view];
        return ;
    }
    sendTime = [NSDate timeIntervalSinceReferenceDate];
    self.navigationController.delegate = self;
    //兼容ipad打不开相册问题，使用队列延迟
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType               = (int)sourceType;
        picker.delegate                 = (id)self;
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:picker animated:YES completion:nil];
    }];
}

- (void)inputContentTextDidChange:(NSString *)newString {
    if ([LGManager getCurrentState] == LGStateAllocatedAgent){
        
        if (shouldSendInputtingMessageToServer && newString.length > 0) {
            shouldSendInputtingMessageToServer = NO;
            [self.chatViewService sendUserInputtingWithContent:newString];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self->shouldSendInputtingMessageToServer = YES;
                
            });
        }
    }
}

- (void)chatTableViewScrollToBottomWithAnimated:(BOOL)animated {
    NSInteger cellCount = [self.chatTableView numberOfRowsInSection:0];
    if (cellCount > 0) {
        [self.chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow: cellCount - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)beginRecord:(CGPoint)point {
    if (TARGET_IPHONE_SIMULATOR){
        [LGToast showToast:[LGBundleUtil localizedStringForKey:@"simulator_not_support_microphone"] duration:2 window:self.view];
        return;
    }
    
    // 判断当前顾客是否正在登陆，如果正在登陆，显示禁止发送的提示
    if (self.chatViewService.clientStatus == LGStateAllocatingAgent || [NSDate timeIntervalSinceReferenceDate] - sendTime < 1) {
        NSString *alertText = self.chatViewService.clientStatus == LGStateAllocatingAgent ? @"cannot_text_client_is_onlining" : @"send_to_fast";
        [LGToast showToast:[LGBundleUtil localizedStringForKey:alertText] duration:2 window:self.view];
        return ;
    }
    sendTime = [NSDate timeIntervalSinceReferenceDate];
    //停止播放的通知
    [[NSNotificationCenter defaultCenter] postNotificationName:LGAudioPlayerDidInterruptNotification object:nil];
    
    //判断是否开启了语音权限
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        //首先记录点击语音的时间，如果第一次授权，则确定授权的时间会较长，这时不应该初始化record view
        CGFloat tapVoiceTimeInMilliSeconds = [NSDate timeIntervalSinceReferenceDate] * 1000;
        [LGChatDeviceUtil isDeviceSupportMicrophoneWithPermission:^(BOOL permission) {
            CGFloat getPermissionTimeInMilliSeconds = [NSDate timeIntervalSinceReferenceDate] * 1000;
            if (getPermissionTimeInMilliSeconds - tapVoiceTimeInMilliSeconds > 100) {
                return ;
            }
            if (permission) {
                [self startRecord];
            } else {
                [LGToast showToast:[LGBundleUtil localizedStringForKey:@"microphone_denied"] duration:2 window:self.view];
            }
        }];
    } else {
        [self startRecord];
    }
}

- (void)startRecord {
    [self.recordView reDisplayRecordView];
    [self.recordView startRecording];
}

- (void)finishRecord:(CGPoint)point {
    [self.recordView stopRecord];
    [self didEndRecord];
}

- (void)cancelRecord:(CGPoint)point {
    [self.recordView cancelRecording];
    [self didEndRecord];
}

- (void)changedRecordViewToCancel:(CGPoint)point {
    self.recordView.revoke = true;
}

- (void)changedRecordViewToNormal:(CGPoint)point {
    self.recordView.revoke = false;
}

- (void)didEndRecord {
    
}

#pragma LGRecordViewDelegate
- (void)didFinishRecordingWithAMRFilePath:(NSString *)filePath {
//    [self.chatViewService sendVoiceMessageWithAMRFilePath:filePath];
//    [self chatTableViewScrollToBottomWithAnimated:true];
    [self sendMessagePrepareWithText:nil image:nil andAMRFilePath:filePath];
}

- (void)didUpdateVolumeInRecordView:(UIView *)recordView volume:(CGFloat)volume {
    [self.displayRecordView changeVolumeLayerDiameter:volume];
}

#pragma UIImagePickerControllerDelegate
-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    NSString *type          = [info objectForKey:UIImagePickerControllerMediaType];
    //当选择的类型是图片
    if (![type isEqualToString:@"public.image"]) {
        return;
    }
    UIImage *image          =  [LGImageUtil resizeImage:[LGImageUtil fixrotation:[info objectForKey:UIImagePickerControllerOriginalImage]]maxSize:CGSizeMake(1000, 1000)];
    [picker dismissViewControllerAnimated:YES completion:^{
//        [self.chatViewService sendImageMessageWithImage:image];
//        [self chatTableViewScrollToBottomWithAnimated:true];
        [self sendMessagePrepareWithText:nil image:image andAMRFilePath:nil];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma UINavigationControllerDelegate 设置当前 statusBarStyle
-(void)navigationController:(UINavigationController *)navigationController
     willShowViewController:(UIViewController *)viewController
                   animated:(BOOL)animated
{
    //修改status样式
    if ([navigationController isKindOfClass:[UIImagePickerController class]]) {
        [UIApplication sharedApplication].statusBarStyle = previousStatusBarStyle;
    }
    self.navigationController.delegate = nil;
}

#pragma LGChatCellDelegate
- (void)showToastViewInCell:(UITableViewCell *)cell toastText:(NSString *)toastText {
    [LGToast showToast:toastText duration:1.0 window:self.view];
}

- (void)resendMessageInCell:(UITableViewCell *)cell resendData:(NSDictionary *)resendData {
    //先删除之前的消息
    NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
    [self.chatViewService resendMessageAtIndex:indexPath.row resendData:resendData];
    [self chatTableViewScrollToBottomWithAnimated:true];
}

- (void)replaceTipCell:(UITableViewCell *)cell {
    
}

- (void)reloadCellAsContentUpdated:(UITableViewCell *)cell messageId:(NSString *)messageId {
    [self.chatTableView reloadData];
    id<LGCellModelProtocol> cellModel = [self.chatViewService.cellModels lastObject];
    if ([[cellModel getCellMessageId] isEqualToString: messageId]) {
        [self.chatTableView layoutIfNeeded];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow: ([weakSelf.chatTableView numberOfRowsInSection:([weakSelf.chatTableView numberOfSections]-1)]-1) inSection:([weakSelf.chatTableView numberOfSections]-1)];
            
            [weakSelf.chatTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:false];
        });
    }
}

- (void)deleteCell:(UITableViewCell *)cell withTipMsg:(NSString *)tipMsg enableLinesDisplay:(BOOL)enable{
    NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
    [self.chatViewService deleteMessageAtIndex:indexPath.row withTipMsg:tipMsg enableLinesDisplay:enable];
    [self chatTableViewScrollToBottomWithAnimated:true];
}


- (void)didSelectMessageInCell:(UITableViewCell *)cell messageContent:(NSString *)content selectedContent:(NSString *)selectedContent {
    
}

- (void)evaluateBotAnswer:(BOOL)isUseful messageId:(NSString *)messageId {
    [self.chatViewService evaluateBotAnswer:isUseful messageId:messageId];
}

- (void)didTapMenuWithText:(NSString *)menuText {
    //去掉 menu 的序号后，主动发送该 menu 消息
    NSRange orderRange = [menuText rangeOfString:@". "];
    if (orderRange.location == NSNotFound) {
        return ;
    }
    NSString *sendText = [menuText substringFromIndex:orderRange.location+2];
    [self.chatViewService sendTextMessageWithContent:sendText];
    [self chatTableViewScrollToBottomWithAnimated:YES];
}

- (void)didTapReplyBtn {
    [self showLGMessageForm];
}

- (void)didTapBotRedirectBtn {
    [self tapNavigationRedirectBtn:nil];
}

- (void)didTapMessageInCell:(UITableViewCell *)cell {
    NSIndexPath *indexPath = [self.chatTableView indexPathForCell:cell];
    [self.chatViewService didTapMessageCellAtIndex:indexPath.row];
}

#pragma LGEvaluationViewDelegate
- (void)didSelectLevel:(NSInteger)level comment:(NSString *)comment {
    [self.chatViewService sendEvaluationLevel:level comment:comment];
}

#ifdef INCLUDE_LAIGU_SDK
#pragma LGServiceToViewInterfaceErrorDelegate 后端返回的数据的错误委托方法
- (void)getLoadHistoryMessageError {
    //    [self.chatTableView finishLoadingTopRefreshViewWithCellNumber:0 isLoadOver:YES];
    [self.chatTableView stopAnimationCompletion:^{
        
        //        [LGToast showToast:[LGBundleUtil localizedStringForKey:@"load_history_message_error"] duration:1.0 window:self.view];
        
        //后端获取信息失败，取消错误信息提示，从数据库获取历史消息
        [self.chatViewService startGettingDateBaseHistoryMessages];
        
    }];
}

/**
 *  根据是否正在分配客服，更新导航栏title
 */
- (void)updateNavTitleWithAgentName:(NSString *)agentName agentStatus:(LGChatAgentStatus)agentStatus {
    //如果开发者设定了 title ，则不更新 title
    if ([LGChatViewConfig sharedConfig].navTitleText) {
        return;
    }
    UIView *titleView = [UIView new];
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = agentName;
    
    UIFont *font = [LGChatViewConfig sharedConfig].chatViewStyle.navTitleFont ?: [[UINavigationBar appearance].titleTextAttributes objectForKey:NSFontAttributeName] ?: [UIFont systemFontOfSize:16.0];
    UIColor *color = [LGChatViewConfig sharedConfig].navTitleColor ?: [[UINavigationBar appearance].titleTextAttributes objectForKey:NSForegroundColorAttributeName];
    titleLabel.font = font;
    titleLabel.textColor = color;
    CGFloat titleHeight = [LGStringSizeUtil getHeightForText:agentName withFont:titleLabel.font andWidth:self.view.frame.size.width];
    CGFloat titleWidth = [LGStringSizeUtil getWidthForText:agentName withFont:titleLabel.font andHeight:titleHeight];
    UIImageView *statusImageView = [UIImageView new];
    switch (agentStatus) {
        case LGChatAgentStatusOnDuty:
            statusImageView.image = [LGAssetUtil agentOnDutyImage];
            break;
        case LGChatAgentStatusOffDuty:
            statusImageView.image = [LGAssetUtil agentOffDutyImage];
            break;
        case LGChatAgentStatusOffLine:
            statusImageView.image = [LGAssetUtil agentOfflineImage];
            break;
        default:
            break;
    }
    
    if ([titleLabel.text isEqualToString:[LGBundleUtil localizedStringForKey:@"no_agent_title"]] || [LGServiceToViewInterface waitingInQueuePosition] > 0) {
        statusImageView.image = nil;
    }
    
    statusImageView.frame = CGRectMake(0, titleHeight/2 - statusImageView.image.size.height/2, statusImageView.image.size.width, statusImageView.image.size.height);
    titleLabel.frame = CGRectMake(statusImageView.frame.size.width + 8, 0, titleWidth, titleHeight);
    titleView.frame = CGRectMake(0, 0, titleLabel.frame.origin.x + titleLabel.frame.size.width, titleHeight);
    [titleView addSubview:statusImageView];
    [titleView addSubview:titleLabel];
    self.navigationItem.titleView = titleView;
}



- (void)didReceiveRefreshOutgoingAvatarNotification:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[UIImage class]]) {
        [self.chatViewService refreshOutgoingAvatarWithImage:notification.object];
    }
}

- (void)closeLaiguChatView {
    if ([self.navigationItem.title isEqualToString:[LGBundleUtil localizedStringForKey:@"no_agent_title"]]) {
        [self.chatViewService dismissingChatViewController];
    }
}

#pragma mark - rotation

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self updateTableCells];
    [self.view endEditing:YES];
    
}
#else
#endif

// ios8以上系统的横屏的事件
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self updateTableCells];
    }];
    [self.view endEditing:YES];
}


- (void)updateTableCells {
    self.chatViewService.chatViewWidth = self.chatTableView.frame.size.width;
    [self.chatViewService updateCellModelsFrame];
    [self.chatTableView reloadData];
}

#pragma mark - input content view deletate

- (void)inputContentView:(LGInputContentView *)inputContentView userObjectChange:(NSObject *)object {
    self.bottomBar.buttonGroupBar.buttons = [NSMutableArray new];
    CGRect rect = CGRectMake(0, 0, 40, 40);
    UIButton *recorderBtn  = [[UIButton alloc] initWithFrame:rect];
    [recorderBtn setImage:[LGAssetUtil imageFromBundleWithName:@"micIcon"] forState:(UIControlStateNormal)];
    [recorderBtn addTarget:self action:@selector(showRecorder) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *cameraBtn  = [[UIButton alloc] initWithFrame:rect];
    [cameraBtn setImage:[LGAssetUtil imageFromBundleWithName:@"cameraIcon"] forState:(UIControlStateNormal)];
    [cameraBtn addTarget:self action:@selector(camera) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *imageRoll  = [[UIButton alloc] initWithFrame:rect];
    [imageRoll setImage:[LGAssetUtil imageFromBundleWithName:@"imageIcon"] forState:(UIControlStateNormal)];
    [imageRoll addTarget:self action:@selector(imageRoll) forControlEvents:(UIControlEventTouchUpInside)];
    
    UIButton *emoji  = [[UIButton alloc] initWithFrame:rect];
    [emoji setImage:[LGAssetUtil imageFromBundleWithName:@"emoji"] forState:(UIControlStateNormal)];
    [emoji addTarget:self action:@selector(emoji) forControlEvents:(UIControlEventTouchUpInside)];
    
    //    UIButton *send  = [[UIButton alloc] initWithFrame:rect];
    //    [send setImage:[LGAssetUtil imageFromBundleWithName:@"emoji"] forState:(UIControlStateNormal)];
    //    [send addTarget:self action:@selector(send) forControlEvents:(UIControlEventTouchUpInside)];
    
    if ([LGChatViewConfig sharedConfig].enableSendVoiceMessage) {
        [self.bottomBar.buttonGroupBar addButton:recorderBtn];
    }
    
    if ([LGChatViewConfig sharedConfig].enableSendImageMessage) {
        [self.bottomBar.buttonGroupBar addButton:cameraBtn];
        [self.bottomBar.buttonGroupBar addButton:imageRoll];
    }
    
    if ([LGChatViewConfig sharedConfig].enableSendEmoji) {
        [self.bottomBar.buttonGroupBar addButton:emoji];
    }
    
    //            [self.bottomBar.buttonGroupBar addButton:send];
    
}

- (BOOL)handleSendMessageAbility {
    
    //xlp 检测网络 排除断网状态还能发送信息
    if (![LGManager obtainNetIsReachable]) {
        [LGToast showToast:[LGBundleUtil localizedStringForKey:@"laigu_communication_failed"] duration:2.0 window:self.view];
        return NO;
    }
    
    
    //xlp 旧的: waitingInQueuePosition>0 && getCurrentAgent].privilege != LGAgentPrivilegeBot  改为 waitingInQueuePosition>0
    if ([LGServiceToViewInterface waitingInQueuePosition] > 0 && [LGServiceToViewInterface getCurrentAgent].privilege != LGAgentPrivilegeBot) {
        [self.view.window endEditing:YES];
        [LGToast showToast:@"正在排队，请等待客服接入后发送消息" duration:2.5 window:self.view.window];
        
        [LGServiceToViewInterface getClientQueuePositionComplete:^(NSInteger position, NSError *error) {
            //从后台获取 position 然后保存到本地
        }];
        return NO;
    }
    
    // 判断当前顾客是否正在登陆，如果正在登陆，显示禁止发送的提示
    if (self.chatViewService.clientStatus == LGStateAllocatingAgent) {
        NSString *alertText = @"cannot_text_client_is_onlining";
        [LGToast showToast:[LGBundleUtil localizedStringForKey:alertText] duration:2 window:[[UIApplication sharedApplication].windows lastObject]];
        
        return NO;
    }
    return YES;
}

- (void)showRecorder {
    if ([self handleSendMessageAbility]) {
        if (self.bottomBar.isFirstResponder) {
            [self.bottomBar resignFirstResponder];
        }else{
            self.bottomBar.inputView = self.displayRecordView;
            [self.bottomBar becomeFirstResponder];
        }
    }
}

- (void)camera {
    if ([self handleSendMessageAbility]) {
        [self sendImageWithSourceType:(UIImagePickerControllerSourceTypeCamera)];
    }
}

- (void)imageRoll {
    if ([self handleSendMessageAbility]) {
        [self sendImageWithSourceType:(UIImagePickerControllerSourceTypePhotoLibrary)];
    }
}

- (void)emoji {
    if ([self handleSendMessageAbility]) {
        if (self.bottomBar.isFirstResponder) {
            [self.bottomBar resignFirstResponder];
        }else{
            
            CGFloat emojiViewHeight = LGToolUtil.kXlpObtainDeviceVersionIsIphoneX ? (emojikeyboardHeight + 34) : emojikeyboardHeight;
            
            LG_InputView * mmView = [[LG_InputView alloc]initWithFrame:CGRectMake(0,0, self.view.frame.size.width, emojiViewHeight)];
            mmView.inputViewDelegate = self;
            self.bottomBar.inputView = mmView;
            
            [self.bottomBar becomeFirstResponder];
        }
    }
}

- (BOOL)inputContentViewShouldReturn:(LGInputContentView *)inputContentView content:(NSString *)content userObject:(NSObject *)object {
    
    if ([content length] > 0) {
        if ([self handleSendMessageAbility]) {
            [self sendTextMessage:content];
            return YES;
        } else {
            return NO;
        }
    }
    return YES;
}

- (BOOL)inputContentViewShouldBeginEditing:(LGInputContentView *)inputContentView {
    
    //xlp 检测网络 排除断网状态还能发送信息
    if (![LGManager obtainNetIsReachable]) {
        [LGToast showToast:[LGBundleUtil localizedStringForKey:@"laigu_communication_failed"] duration:2.0 window:self.view];
        return NO;
    }
    return YES;
}

#pragma mark - inputbar delegate

- (void)inputBar:(LGBottomBar *)inputBar willChangeHeight:(CGFloat)height {
    if (height > kLGChatViewInputBarHeight) {
        CGFloat diff = height - self.constaintInputBarHeight.constant;
        if (diff < self.chatTableView.contentInset.top + self.self.chatTableView.contentSize.height) {
            self.chatTableView.contentOffset = CGPointMake(self.chatTableView.contentOffset.x, self.chatTableView.contentOffset.y + diff);
        }
        
        [self changeInputBarHeightConstraintConstant:height];
    }else{
        [self changeInputBarHeightConstraintConstant:kLGChatViewInputBarHeight];
    }
}

- (void)changeInputBarHeightConstraintConstant:(CGFloat)height {
    self.constaintInputBarHeight.constant = height;
    
    self.keyboardView.keyboardTriggerPoint = CGPointMake(0, height);
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)changeInputBarBottomLayoutGuideConstant:(CGFloat)height {
    //xlp 收回键盘 时 减去 34 todo
    if (LGToolUtil.kXlpObtainDeviceVersionIsIphoneX ) {
        if (height == 0) {
            height = 34;
            
        } else if(height == emojikeyboardHeight) {
            // 点击表情 弹出表情键盘时
            height += 34;
        }
    }
    
    self.constraintInputBarBottom.constant = height;
    
    [self.view setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

#pragma mark - keyboard controller delegate
- (void)keyboardController:(LGKeyboardController *)keyboardController keyboardChangeFrame:(CGRect)keyboardFrame isImpressionOfGesture:(BOOL)isImpressionOfGesture {
    
    CGFloat viewHeight = self.navigationController.navigationBar.translucent ? CGRectGetMaxY(self.view.frame) : CGRectGetMaxY(self.view.frame) - LGToolUtil.kXlpObtainNaviHeight;
    
    CGFloat heightFromBottom = MAX(0.0, viewHeight - CGRectGetMinY(keyboardFrame));
    
    if (!isImpressionOfGesture) {
        
        if (LGToolUtil.kXlpObtainDeviceVersionIsIphoneX ) {
            
            CGFloat diff = heightFromBottom - self.constraintInputBarBottom.constant + (heightFromBottom == 0 ? 34 : 0);
            if (diff < self.chatTableView.contentInset.top + self.chatTableView.contentSize.height) {
                self.chatTableView.contentOffset = CGPointMake(self.chatTableView.contentOffset.x, self.chatTableView.contentOffset.y + diff);
            }
            
        }else{
            
            CGFloat diff = heightFromBottom - self.constraintInputBarBottom.constant;
            if (diff < self.chatTableView.contentInset.top + self.chatTableView.contentSize.height) {
                self.chatTableView.contentOffset = CGPointMake(self.chatTableView.contentOffset.x, self.chatTableView.contentOffset.y + diff);
            }
        }
    }
    
    [self changeInputBarBottomLayoutGuideConstant:heightFromBottom];
}

#pragma mark - LGRecorderViewDelegate
- (void)recordEnd {
    [self finishRecord:CGPointZero];
}

- (void)recordStarted {
    [self beginRecord:CGPointZero];
}

- (void)recordCanceld {
    [self cancelRecord:CGPointZero];
}

#pragma mark - emoji delegate and datasource

- (void)LGInputViewObtainEmojiStr:(NSString *)emojiStr{
    LAIGU_HPGrowingTextView *textField = [(LGTabInputContentView *)self.bottomBar.contentView textField];
    textField.text = [textField.text stringByAppendingString:emojiStr];
}
- (void)LGInputViewDeleteEmoji{
    LAIGU_HPGrowingTextView *textField = [(LGTabInputContentView *)self.bottomBar.contentView textField];
    if (textField.text.length > 0) {
        NSRange lastRange = [textField.text rangeOfComposedCharacterSequenceAtIndex:([textField.text length] - 1)];
        textField.text = [textField.text stringByReplacingCharactersInRange:lastRange withString:@""];
    }
}
- (void)LGInputViewSendEmoji{
    LAIGU_HPGrowingTextView *textField = [(LGTabInputContentView *)self.bottomBar.contentView textField];
    if (textField.text.length > 0) {
        
        [self sendTextMessage:textField.text];
        [(LGTabInputContentView *)self.bottomBar.contentView textField].text = @"";
    }
}


#pragma mark -

- (void)handlePopRecognizer:(UIScreenEdgePanGestureRecognizer*)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    
    CGFloat xPercent = translation.x / CGRectGetWidth(self.view.bounds) * 0.5;
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [LGTransitioningAnimation setInteractive:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        case UIGestureRecognizerStateChanged:
            [LGTransitioningAnimation updateInteractiveTransition:xPercent];
            break;
        default:
            if (xPercent < .25) {
                [LGTransitioningAnimation cancelInteractiveTransition];
            } else {
                [LGTransitioningAnimation finishInteractiveTransition];
            }
            [LGTransitioningAnimation setInteractive:NO];
            break;
    }
}

#endif

#pragma mark - lazy

- (LGEvaluationView *)evaluationView {
    if (!_evaluationView) {
        _evaluationView = [[LGEvaluationView alloc] init];
        _evaluationView.delegate = self;
    }
    return _evaluationView;
}

- (LGBottomBar *)bottomBar {
    if (!_bottomBar) {
        LGTabInputContentView *contentView = [[LGTabInputContentView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, emojikeyboardHeight )];
        
        _bottomBar = [[LGBottomBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kLGChatViewInputBarHeight) contentView: contentView];
        _bottomBar.delegate = self;
        _bottomBar.contentViewDelegate = self;
        [contentView setupButtons];
        
    }
    return _bottomBar;
}

- (LGKeyboardController *)keyboardView {
    if (!_keyboardView) {
        _keyboardView = [[LGKeyboardController alloc] initWithResponders:@[self.bottomBar.contentView, self.bottomBar] contextView:self.view panGestureRecognizer:self.chatTableView.panGestureRecognizer delegate:self];
        _keyboardView.keyboardTriggerPoint = CGPointMake(0, self.constaintInputBarHeight.constant);
    }
    return _keyboardView;
}

- (LGRecorderView *)displayRecordView {
    if (!_displayRecordView) {
        _displayRecordView = [[LGRecorderView alloc] initWithFrame: CGRectMake(0, 0, self.view.frame.size.width, 258)];
        _displayRecordView.delegate = self;
        _displayRecordView.backgroundColor = [[UIColor alloc] initWithRed: 242/255.0 green: 242/255.0 blue: 247/255.0 alpha: 1];
    }
    return _displayRecordView;
}

- (LGRecordView *)recordView {
    //如果开发者不自定义录音界面，则将播放界面显示出来
    if (!_recordView) {
        _recordView = [[LGRecordView alloc] initWithFrame:CGRectMake(0,
                                                                     0,
                                                                     self.chatTableView.frame.size.width,
                                                                     /*viewSize.height*/[UIScreen mainScreen].bounds.size.height - self.bottomBar.frame.size.height)
                                        maxRecordDuration:[LGChatViewConfig sharedConfig].maxVoiceDuration];
        _recordView.recordMode = [LGChatViewConfig sharedConfig].recordMode;
        _recordView.keepSessionActive = [LGChatViewConfig sharedConfig].keepAudioSessionActive;
        _recordView.recordViewDelegate = self;
        //        [self.view addSubview:_recordView];
    }
    
    return _recordView;
}

#pragma 来鼓留言的界面
- (void)showLGMessageForm {
    LGMessageFormViewManager *formManager = [[LGMessageFormViewManager alloc] init];
    [formManager pushLGMessageFormViewControllerInViewController:self];
}

/**
 显示数据提交遮罩层
 */
- (void)showActivityIndicatorView {
    if (!translucentView) {
        translucentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.chatTableView.frame.size.width, self.chatTableView.frame.size.height)];
        translucentView.backgroundColor = [UIColor blackColor];
        translucentView.alpha = 0.5;
        translucentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [activityIndicatorView setCenter:CGPointMake(self.chatTableView.frame.size.width / 2.0, self.chatTableView.frame.size.height / 2.0)];
        [translucentView addSubview:activityIndicatorView];
        activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [self.view addSubview:translucentView];
    }
    
    translucentView.hidden = NO;
    translucentView.alpha = 0;
    [activityIndicatorView startAnimating];
    [UIView animateWithDuration:0.5 animations:^{
        self->translucentView.alpha = 0.5;
    }];
}

/**
 隐藏数据提交遮罩层
 */
- (void)dismissActivityIndicatorView {
    if (translucentView) {
        [activityIndicatorView stopAnimating];
        translucentView.hidden = YES;
    }
}



//xlp 测试可删除
- (void)closeSocketlalala{
    
    //断掉链接
    [[NSNotificationCenter defaultCenter]postNotificationName:@"xlpCloseSocketNoti" object:nil];
    
    [LGManager closeLaiguService];
}


////xlp 在对话规则 打开过滤无消息访客按钮后 刚开始对话 客户未能上线 状态为 初始化
//- (void)checkOpenVisitorNoMessageBool{
//
//    if (openVisitorNoMessageBool) {
//        [LGServiceToViewInterface prepareForChat]; //初始化
//        [self.view endEditing:YES];
//
//
//        [self.chatViewService setClientOnline];
//        //延时2秒 获取所有的历史记录
//        [self.chatViewService onceLoadHistoryAndRefresh:3];
//
//        openVisitorNoMessageBool = NO;
//
//    }
//}


@end
