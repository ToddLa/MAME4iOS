//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//
#import <UIKit/UIKit.h>
#import "GameInfo.h"

#ifndef ChooseGameController_h
#define ChooseGameController_h

NS_ASSUME_NONNULL_BEGIN

@interface ChooseGameController : UICollectionViewController

- (void)setGameList:(NSArray<GameInfoDictionary*>*)games;
+ (void)reset;
- (void)reload;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfoDictionary*)game;
#endif

@property(nonatomic, strong) void (^selectGameCallback)(GameInfoDictionary* info);
@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) BOOL hideConsoles;

+(NSAttributedString*)getGameText:(GameInfoDictionary*)game;

@end

NS_ASSUME_NONNULL_END

#endif /* ChooseGameController_h */
