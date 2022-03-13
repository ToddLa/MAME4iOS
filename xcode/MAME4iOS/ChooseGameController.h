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

@property(nonatomic, strong) void (^selectGameCallback)(GameInfo* info);
@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) BOOL hideConsoles;

- (void)setGameList:(NSArray<GameInfo*>*)games;

// update a value in a game, and save in sidecar too.
-(GameInfo*)setGame:(GameInfo*)game value:(nullable NSString*)value forKey:(NSString*)key;

+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfo*)game;
#endif

+(NSAttributedString*)getGameText:(GameInfo*)game;

@end

NS_ASSUME_NONNULL_END

#endif /* ChooseGameController_h */
