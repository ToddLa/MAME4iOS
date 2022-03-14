//
//  ChooseGameController+EditGame.swift
//  MAME4iOS
//
//  Created by Todd Laney on 2/14/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

// MARK: Edit Metadata for Game

extension ChooseGameController {
    
    @objc func canEdit(_ game:GameInfo) -> Bool {
        // for now we only edit custom software, not MESS SoftwareList based games, or Machines, or Consoles
        return game.gameMetadataFile != ""
    }
    
    @objc func edit(_ game:GameInfo) {
        
        let alert = UIAlertController(title:"Edit", message:nil, preferredStyle:.alert)
        
        alert.addTextField { field in
            field.placeholder = "Description"
            field.text = game.gameDescription
        }
        
        alert.addTextField { field in
            field.placeholder = "Manufacturer"
            field.text = game.gameManufacturer
        }
        
        alert.addTextField { field in
            field.placeholder = "Year"
            field.text = game.gameYear
        }
        
        alert.addTextField { field in
            field.placeholder = "Custom Options"
            field.text = game.gameCustomCmdline
        }
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            game.gameSetValue(alert.textFields?[0].text ?? "", forKey: kGameInfoDescription)
            game.gameSetValue(alert.textFields?[1].text ?? "", forKey: kGameInfoManufacturer)
            game.gameSetValue(alert.textFields?[2].text ?? "", forKey: kGameInfoYear)
            game.gameSetValue(alert.textFields?[3].text ?? "", forKey: kGameInfoCustomCmdline)
            self.reload()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }
    
}
