//
//  LGPhotoCardMessageCell.m
//  LGEcoboostSDK-test
//
//  Created by shunxingzhang on 2020/7/9.
//  Copyright © 2020 zhangshunxing. All rights reserved.
//

#import "LGPhotoCardMessageCell.h"
#import "LGPhotoCardCellModel.h"
#import "LGChatViewConfig.h"
#import "LGImageUtil.h"

@implementation LGPhotoCardMessageCell {
    UIImageView *avatarImageView;
    UIView *bubbleView;
    UIImageView *bubbleContentImageView;
    UIActivityIndicatorView *loadingIndicator;
    LGPhotoCardCellModel *cellModel;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        //初始化头像
        avatarImageView = [[UIImageView alloc] init];
        avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:avatarImageView];
        //初始化气泡
        bubbleView = [[UIView alloc] init];
        bubbleView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:247/255.0 alpha:1];
        bubbleView.layer.masksToBounds = true;
        bubbleView.layer.cornerRadius = 6.0;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bubbleTapped)];
        [bubbleView addGestureRecognizer:tapGesture];
        
        [self.contentView addSubview:bubbleView];
        
        //初始化contentImageView
        bubbleContentImageView = [[UIImageView alloc] init];
        [bubbleView addSubview:bubbleContentImageView];
        //初始化加载数据的indicator
        loadingIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        loadingIndicator.hidden = YES;
        [bubbleView addSubview:loadingIndicator];
    }
    return self;
}

#pragma LGChatCellProtocol
- (void)updateCellWithCellModel:(id<LGCellModelProtocol>)model {
    if (![model isKindOfClass:[LGPhotoCardCellModel class]]) {
        NSAssert(NO, @"传给LGPhotoCardMessageCell的Model类型不正确");
        return ;
    }
    cellModel = (LGPhotoCardCellModel *)model;

    //刷新头像
    if (cellModel.avatarImage) {
        avatarImageView.image = cellModel.avatarImage;
    }
    avatarImageView.frame = cellModel.avatarFrame;
    if ([LGChatViewConfig sharedConfig].enableRoundAvatar) {
        avatarImageView.layer.masksToBounds = YES;
        avatarImageView.layer.cornerRadius = cellModel.avatarFrame.size.width / 2;
    }
    
    //刷新气泡
    bubbleView.frame = cellModel.bubbleFrame;
    bubbleContentImageView.frame = cellModel.contentImageViewFrame;
    
    //消息图片
    loadingIndicator.frame = cellModel.loadingIndicatorFrame;
    if (cellModel.image) {
        bubbleContentImageView.image = cellModel.image;
        loadingIndicator.hidden = true;
        [loadingIndicator stopAnimating];
    } else {
        loadingIndicator.hidden = false;
        [loadingIndicator startAnimating];
    }
}

#pragma 单击气泡
- (void)bubbleTapped {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cellModel.targetUrl]];
}

@end
