//
//  LGEnterprise.h
//  LaiGuSDK
//
//  Created by zhangshunxing on 15/10/27.
//  Copyright © 2015年 LaiGu Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGPreChatData.h"

typedef enum : NSUInteger {
    LGTicketConfigContactFieldTypeText               = 0, //文字
    LGTicketConfigContactFieldTypeNumber             = 1, //数字
    LGTicketConfigContactFieldTypeTime               = 2, //日期
    LGTicketConfigContactFieldTypeSingleChoice       = 3, //单选
    LGTicketConfigContactFieldTypeMultipleChoice     = 4, //多选
} LGTicketConfigContactFieldType;

/**留言工单字段模型*/
@interface LGTicketConfigContactField : LGModel

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *placeholder;

@property (nonatomic, assign) bool required;

@property (nonatomic, assign) LGTicketConfigContactFieldType type;

@property (nonatomic, strong) NSArray<NSString *> *metainfo; // 多选，单选类型中的选项内容

@end

/**企业工作台 工单配置信息*/

@interface LGTicketConfigInfo : LGModel

@property (nonatomic, copy) NSString *contactRule;

@property (nonatomic, copy) NSString *intro;

@property (nonatomic, copy) NSString *category; // 工单分类询问开关

// 留言输入框的内容类型：1、“content”，输入框的text直接显示为defaultTemplateContent，让用户自己修改； 2、“placeholder”，输入框的placeholder显示为content_placeholder，内容用户自己输入
@property (nonatomic, copy) NSString *content_fill_type;

@property (nonatomic, copy) NSString *defaultTemplateContent;

@property (nonatomic, copy) NSString *content_title; // 留言输入框的title，

@property (nonatomic, copy) NSString *content_placeholder; // 留言输入框的placeholder，

@property (nonatomic, strong) NSArray<LGTicketConfigContactField *> *custom_fields;

@end

@interface LGEnterpriseConfig : NSObject

/**企业工作台 配置信息*/

@property (nonatomic, copy) NSString *evaluationPromtText;///客服邀请评价显示的文案

@property (nonatomic, assign) bool showSwitch; //

@property (nonatomic, assign) BOOL isScheduleAfterClientSendMessage; //就字面意思是 访客发送消息后才分配客服,即无消息访客过滤开关

@property (nonatomic, copy) NSString *avatar; //企业客服头像

@property (nonatomic, copy) NSString *public_nickname; //

@property (nonatomic, copy) NSString *enterpriseIntro; //

@property (nonatomic, assign) bool  queueStatus; //排队是否开启,true为开启

@property (nonatomic, copy) NSString *queueIntro; //排队文案

@property (nonatomic, copy) NSString *queueTicketIntro; //排队引导留言的文案

@property (nonatomic, strong) LGPreChatData *preChatData; //讯前表单数据模型

@property (nonatomic, strong) LGTicketConfigInfo *ticketConfigInfo; //工单留言数据模型

@end


@interface LGEnterprise : NSObject

/** 企业id */
@property (nonatomic, copy) NSString *enterpriseId;

/** 企业简称 */
@property (nonatomic, copy) NSString *name;

/** 企业全名 */
@property (nonatomic, copy) NSString *fullname;

/** 企业负责人的邮箱 */
@property (nonatomic, copy) NSString *contactEmail;

/** 企业负责人的电话 */
@property (nonatomic, copy) NSString *contactTelephone;

/** 企业负责人的姓名 */
@property (nonatomic, copy) NSString *contactName;

/** 企业联系电话 */
@property (nonatomic, copy) NSString *telephone;

/** 网址 */
@property (nonatomic, copy) NSString *website;

/** 行业 */
@property (nonatomic, copy) NSString *industry;

/** 企业地址 */
@property (nonatomic, copy) NSString *location;

/** 邮寄地址 */
@property (nonatomic, copy) NSString *mailingAddress;
/**企业工作台 配置信息*/
@property (nonatomic, strong) LGEnterpriseConfig *configInfo;

- (void)parseEnterpriseConfigData:(NSDictionary *)json;

- (NSString *)toEnterpriseConfigJsonString;

@end
