//
//  LGRichTextViewCell.m
//  Laigu-SDK-Demo
//
//  Created by zhangshunxing on 16/6/14.
//  Copyright © 2016年 Laigu. All rights reserved.
//

#import "LGRichTextViewCell.h"
#import "UIView+LGLayout.h"
#import "LGChatViewConfig.h"
#import "LGImageUtil.h"
#import "LGCellModelProtocol.h"
#import "LGRichTextViewModel.h"
#import "LGWindowUtil.h"
#import "LGAssetUtil.h"

CGFloat internalSpace = 10;
CGFloat internalImageToTextSpace = kLGCellBubbleToTextHorizontalLargerSpacing;
CGFloat internalImageWidth = 80;

@interface LGRichTextViewCell()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UIView *itemsView;
@property (nonatomic, strong) UIImageView *indicatorImageView;

@property (nonatomic, strong) LGRichTextViewModel *viewModel;

@end


@implementation LGRichTextViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
        [self makeConstraints];
        [self setupAction];
    }
    return self;
}

- (void)updateCellWithCellModel:(id<LGCellModelProtocol>)model {
    self.viewModel = model;
    [self bind:model];
}

//通过将 UI 于 viewModel 的响应方法绑定，使得 UI 可以响应数据的变化
- (void)bind:(LGRichTextViewModel *)viewModel {
    
    __weak typeof(self) wself = self;
    [self.viewModel setModelChanges:^(NSString *summary, NSString *iconPath, NSString *content) {
        __strong typeof (wself) sself = wself;
        
        sself.contentLabel.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width - kLGCellAvatarToBubbleSpacing - kLGCellBubbleToTextHorizontalSmallerSpacing - kLGCellBubbleMaxWidthToEdgeSpacing - kLGCellAvatarDiameter - kLGCellAvatarToHorizontalEdgeSpacing - internalSpace - internalImageToTextSpace - internalImageWidth;
        
        if (summary.length > 0) {
            sself.contentLabel.text = summary;
        } else {
            sself.contentLabel.text = [sself stripTags:content];
        }
    }];
    
    self.iconImageView.image = [LGAssetUtil imageFromBundleWithName:@"default_image"];
    [self.viewModel setIconLoaded:^(UIImage *iconImage) {
        __strong typeof (wself) sself = wself;
        if (iconImage) {
            sself.iconImageView.image = iconImage;
        }
    }];
    
    [self.viewModel setCellHeight:^CGFloat{
        return internalImageWidth + kLGCellAvatarToVerticalEdgeSpacing * 2;
    }];
    
    [self.viewModel setBotEvaluateDidTapUseful:^(NSString *messageId){
        __strong typeof (wself) sself = wself;
        [sself botEvaluateDidTapUsefulWithMessageId:messageId];
    }];
    
    [self.viewModel setBotEvaluateDidTapUseless:^(NSString *messageId) {
        __strong typeof (wself) sself = wself;
        [sself botEvaluateDidTapUselessWithMessageId:messageId];
    }];
    
    // 绑定完成，通知 viewModel 进行数据加载和加工
    [self.viewModel load];
}


- (NSString *)stripTags:(NSString *)str
{
    NSMutableString *html = [NSMutableString stringWithCapacity:[str length]];
    
    NSScanner *scanner = [NSScanner scannerWithString:str];
    scanner.charactersToBeSkipped = NULL;
    NSString *tempText = nil;
    
    while (![scanner isAtEnd]) {
        [scanner scanUpToString:@"<" intoString:&tempText];
        
        if (tempText != nil)
            [html appendString:[NSString stringWithFormat:@"%@",tempText]];
        
        [scanner scanUpToString:@">" intoString:NULL];
        
        if (![scanner isAtEnd])
            [scanner setScanLocation:[scanner scanLocation] + 1];
        
        tempText = nil;
    }
    
    return html;
}

- (void)setupUI {
    [self.contentView addSubview:self.itemsView];
    self.iconImageView = [[UIImageView alloc] initWithImage:[LGChatViewConfig sharedConfig].incomingDefaultAvatarImage];
    self.indicatorImageView = [[UIImageView alloc] initWithImage:[LGAssetUtil imageFromBundleWithName:@"arrowRight"]];
    [self.itemsView addSubview:self.iconImageView];
    [self.itemsView addSubview:self.contentLabel];
    [self.itemsView addSubview:self.indicatorImageView];
}

- (void)makeConstraints {
    
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.itemsView.translatesAutoresizingMaskIntoConstraints = NO;
    self.indicatorImageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *d = @{@"icon":self.iconImageView, @"label":self.contentLabel, @"indicator":self.indicatorImageView};
    NSDictionary *m = @{@"av":@(kLGCellAvatarToVerticalEdgeSpacing), @"bv":@(kLGCellBubbleToTextVerticalSpacing), @"al":@(kLGCellAvatarToBubbleSpacing), @"br":@(kLGCellBubbleMaxWidthToEdgeSpacing), @"ad":@(kLGCellAvatarDiameter), @"id":@(internalImageWidth), @"is":@(internalSpace), @"iis":@(internalImageToTextSpace), @"bts":@(kLGCellBubbleToTextHorizontalLargerSpacing), @"btvs":@(kLGCellBubbleToTextVerticalSpacing)};
    
    [self.itemsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[icon(id)]-is-[label]-10-[indicator(13)]-10-|" options:0 metrics:m views:d]];
    [self.itemsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[icon(id)]-0-|" options:0 metrics:m views:d]];
    [self.itemsView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[label]-|" options:0 metrics:m views:d]];
    [self.itemsView addConstraint:[NSLayoutConstraint constraintWithItem:self.indicatorImageView attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.itemsView attribute:(NSLayoutAttributeCenterY) multiplier:1 constant:0]];
    
    d = @{@"items":self.itemsView};
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-av-[items]-br-|" options:0 metrics:m views:d]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-av-[items]-av-|" options:0 metrics:m views:d]];
}

- (void)setupAction {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openURL)];
    [self.itemsView addGestureRecognizer:tap];
}

- (void)openURL {
    [self.viewModel openFrom:[LGWindowUtil topController]];
}

- (void)botEvaluateDidTapUsefulWithMessageId:(NSString *)messageId {
    if ([self.chatCellDelegate respondsToSelector:@selector(evaluateBotAnswer:messageId:)]) {
        [self.chatCellDelegate evaluateBotAnswer:YES messageId:messageId];
    }
}

- (void)botEvaluateDidTapUselessWithMessageId:(NSString *)messageId {
    if ([self.chatCellDelegate respondsToSelector:@selector(evaluateBotAnswer:messageId:)]) {
        [self.chatCellDelegate evaluateBotAnswer:NO messageId:messageId];
    }
}

#pragma mark -

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc]init];
        _contentLabel.numberOfLines = 0;
        _contentLabel.textAlignment = NSTextAlignmentNatural;
        _contentLabel.textColor = [LGChatViewConfig sharedConfig].incomingMsgTextColor;
        _contentLabel.font = [UIFont systemFontOfSize:15];

    }
    return _contentLabel;
}

- (UIView *)itemsView {
    if (!_itemsView) {
        _itemsView = [UIView new];
        _itemsView.backgroundColor = [LGChatViewConfig sharedConfig].incomingBubbleColor;
        _itemsView.layer.cornerRadius = 4;
        _itemsView.layer.masksToBounds = YES;
        _itemsView.layer.borderColor = [UIColor colorWithHexString:silver].CGColor;
        _itemsView.layer.borderWidth = 0.5;
    }
    return _itemsView;
}

@end
