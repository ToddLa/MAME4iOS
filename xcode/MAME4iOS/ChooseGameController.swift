//
//  ChooseGameController.swift
//  MAME4iOS
//
//  Created by Todd Laney on 2/14/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

// MARK: Edit Metadata for Game

extension ChooseGameController {
    
    @objc func edit(_ game:GameInfo) {
        
        let alert = UIAlertController(title: "Edit", message: "Edit all the things", preferredStyle: .actionSheet)
        
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
            field.placeholder = "Custom Commandline"
            field.text = ""
        }
        
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            
        }))
        
        self.present(alert, animated: true)
    }
    
}
