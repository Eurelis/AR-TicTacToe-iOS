//
//  GameCell.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 08/12/2017.
//  Copyright © 2017 Eurelis. All rights reserved.
//

import Foundation
import SceneKit

class GameCell {
    
    var key: String // Defines cell number
    var detector: SCNNode // Cell node detector, to detect tap inside the cell
    
    var containsElement: SCNNode? // Element contained in the cell, for later manipulation
    var containsElementType: String? // Element type (circle/cross), for result calculation
    
    init(key: String, detector: SCNNode) {
        self.key = key
        self.detector = detector
    }
    
    // Inserting element in the cell
    func setContains(node: SCNNode?, type: String?) {
        containsElement = node
        containsElementType = type
    }
    
    // Remove all element from the cell
    func emptyCell() {
        if containsElement != nil {
            containsElement!.removeFromParentNode()
        }
        setContains(node: nil, type: nil)
    }
    
}
