//
//  LGVoiceMessage.m
//  LGChatViewControllerDemo
//
//  Created by zhangshunxing on 15/10/30.
//  Copyright © 2015年 zhangshunxing. All rights reserved.
//

#import "LGVoiceMessage.h"
#import "LGServiceToViewInterface.h"

@implementation LGVoiceMessage

- (instancetype)init{
    if (self = [super init]) {
        self.voicePath = @"";
    }
    return self;
}

- (instancetype)initWithVoicePath:(NSString *)voicePath {
    self = [self init];
    self.voicePath = voicePath;
    return self;
}

- (instancetype)initWithVoiceData:(NSData *)voiceDate {
    self = [self init];
    self.voiceData = voiceDate;
    return self;
}

+ (void)setVoiceHasPlayedToDBWithMessageId:(NSString *)messageId {
    [LGServiceToViewInterface updateMessageWithId:messageId forAccessoryData:@{@"isPlayed":@(YES)}];
}

- (void)handleAccessoryData:(NSDictionary *)accessoryData {
    NSNumber *isPlayed = [accessoryData objectForKey:@"isPlayed"];
    if (isPlayed) {
        self.isPlayed = isPlayed.boolValue;
    }
}

@end
