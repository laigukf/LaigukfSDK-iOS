//
//  AGEmojiKeyboardView.h
//  AGEmojiKeyboard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//
// Set as inputView to textfields, this view class gives an
// interface to the user to enter emoji characters.

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LGAGEmojiKeyboardViewCategoryImage) {
//  LGAGEmojiKeyboardViewCategoryImageRecent,
  LGAGEmojiKeyboardViewCategoryImageFace,
  LGAGEmojiKeyboardViewCategoryImageBell,
  LGAGEmojiKeyboardViewCategoryImageFlower,
  LGAGEmojiKeyboardViewCategoryImageCar,
  LGAGEmojiKeyboardViewCategoryImageCharacters
};

@protocol LGAGEmojiKeyboardViewDelegate;
@protocol LGAGEmojiKeyboardViewDataSource;

/**
 Keyboard class to present as an alternate.
 This keyboard presents the emojis supported by iOS.

 @note To modify appearance, use @p segmentsBar @p pageControl
 @p emojiPagesScrollView properties.
 */
@interface LGAGEmojiKeyboardView : UIView

/**
 Segment control displays the categories.
 */
@property (nonatomic, readonly) UISegmentedControl *segmentsBar;

/**
 Pagecontrol displays the current page and number of pages on an emoji page.
 */
@property (nonatomic, readonly) UIPageControl *pageControl;

/**
 Scroll view displays all the emoji pages.
 */
@property (nonatomic, readonly) UIScrollView *emojiPagesScrollView;

@property (nonatomic, weak) id<LGAGEmojiKeyboardViewDelegate> delegate;
@property (nonatomic, weak) id<LGAGEmojiKeyboardViewDataSource> dataSource;

/**
 @param frame Frame of the view to be initialised with.

 @param dataSource dataSource is required during the initialization to
 get all the relevent images to present in the view.
 */
- (instancetype)initWithFrame:(CGRect)frame
                   dataSource:(id<LGAGEmojiKeyboardViewDataSource>)dataSource;

@end


/**
 Protocol to be followed by the dataSource of `AGEmojiKeyboardView`.
 */
@protocol LGAGEmojiKeyboardViewDataSource <NSObject>

@optional
/**
 Method called on dataSource to get the category image when selected.

 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.

 @param category category to get the image for. @see AGEmojiKeyboardViewCategoryImage
 */
- (UIImage *)emojiKeyboardView:(LGAGEmojiKeyboardView *)emojiKeyboardView
      imageForSelectedCategory:(LGAGEmojiKeyboardViewCategoryImage)category;

/**
 Method called on dataSource to get the category image when not-selected.

 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.

 @param category category to get the image for. @see AGEmojiKeyboardViewCategoryImage
 */
- (UIImage *)emojiKeyboardView:(LGAGEmojiKeyboardView *)emojiKeyboardView
   imageForNonSelectedCategory:(LGAGEmojiKeyboardViewCategoryImage)category;

/**
 Method called on dataSource to get the back button image to be shown in the view.

 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.
 */
- (UIImage *)backSpaceButtonImageForEmojiKeyboardView:(LGAGEmojiKeyboardView *)emojiKeyboardView;

@optional

/**
 Method called on dataSource to get category that should be shown by
 default i.e. when the keyboard is just presented.

 @note By default `AGEmojiKeyboardViewCategoryImageRecent` is shown.

 @param emojiKeyBoardView EmojiKeyBoardView object shown.
 */
- (LGAGEmojiKeyboardViewCategoryImage)defaultCategoryForEmojiKeyboardView:(LGAGEmojiKeyboardView *)emojiKeyboardView;

/**
 Method called on dataSource to get number of emojis to be maintained in
 recent category.

 @note By default `50` is used.

 @param emojiKeyBoardView EmojiKeyBoardView object shown.
 */
- (NSUInteger)recentEmojisMaintainedCountForEmojiKeyboardView:(LGAGEmojiKeyboardView *)emojiKeyboardView;

@end


/**
 Protocol to be followed by the delegate of `AGEmojiKeyboardView`.
 */
@protocol LGAGEmojiKeyboardViewDelegate <NSObject>

/**
 Delegate method called when user taps an emoji button

 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.

 @param emoji Emoji used by user
 */
- (void)emojiKeyBoardView:(LGAGEmojiKeyboardView *)emojiKeyBoardView
              didUseEmoji:(NSString *)emoji;

/**
 Delegate method called when user taps on the backspace button

 @param emojiKeyBoardView EmojiKeyBoardView object on which user has tapped.
 */
- (void)emojiKeyBoardViewDidPressBackSpace:(LGAGEmojiKeyboardView *)emojiKeyBoardView;

@end
