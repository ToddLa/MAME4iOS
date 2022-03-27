//
//  GameInfo.swift
//  MAME4iOS
//
//  Class to hold info about a Game
//
//  Created by Todd Laney on 3/21/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation

/// there are a few types of Games
///
///  * Arcade
///  * Console
///  * Computer
///  * File
///  * Snapshot
///
@objc
enum GameInfoType : Int {
    case Arcade
    case Console
    case Computer
    case BIOS
    case Snapshot
    case Software
}

@objcMembers
class XGameInfo : NSObject {
    let type: GameInfoType
    let name: String
    let system: String
    let _description: String
    let year: String
    let manufacturer: String
    
    override init() {
        type = .Arcade
        name = ""
        system = ""
        _description = ""
        year = ""
        manufacturer = ""
    }
}

@objc
extension XGameInfo {
    // keys used in a NSUserDefaults
    static let xFAVORITE_GAMES_KEY   = "FavoriteGames"
    static let xFAVORITE_GAMES_TITLE = "Favorite Games"
    static let xRECENT_GAMES_KEY     = "RecentGames"
    static let xRECENT_GAMES_TITLE   = "Recently Played"
}

