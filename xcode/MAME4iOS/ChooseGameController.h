//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GameInfo.h"

#ifndef ChooseGameController_h
#define ChooseGameController_h

NS_ASSUME_NONNULL_BEGIN

@interface ChooseGameController : UICollectionViewController

@property(nonatomic, strong) void (^selectGameCallback)(GameInfoDictionary* info);
@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) BOOL hideConsoles;

- (void)setGameList:(NSArray<GameInfoDictionary*>*)games;
- (void)reload;

+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfoDictionary*)game;
#endif

+(NSAttributedString*)getGameText:(GameInfoDictionary*)game;

@end

NS_ASSUME_NONNULL_END

#endif /* ChooseGameController_h */
