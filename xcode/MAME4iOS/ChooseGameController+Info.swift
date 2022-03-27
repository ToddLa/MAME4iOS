//
//  ChooseGameController+Info.swift
//  MAME4iOS
//
//  Created by Todd Laney on 3/23/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import Foundation
import UIKit

extension ChooseGameController {
    
    func showInfo(_ game:GameInfo) {
        let info = UINavigationController(rootViewController: GameInfoViewController(game))
        present(info, animated:true)
    }
    
}

class GameInfoViewController : UIViewController {

    private var game = GameInfo()

    convenience init(_ game:GameInfo) {
        self.init(nibName:nil, bundle: nil)
        self.game = game
    }

    private let infoText = UITextView()
    
    private func update() {
        let text = NSMutableAttributedString(string:"")
        infoText.attributedText = text
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(infoText)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        infoText.frame = view.bounds
    }
}
