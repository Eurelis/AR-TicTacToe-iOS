//
//  Plane.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 05/12/2017.
//  Copyright © 2017 Eurelis. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class Plane: SCNNode {

    var planeGeometry: SCNBox?
    var isSelected: Bool = false
    
    // Init custom plane during scan
    init(anchor: ARPlaneAnchor) {
        super.init()
        
        self.planeGeometry = SCNBox(width: CGFloat(anchor.extent.x),
                                    height: 0.01,
                                    length: CGFloat(anchor.extent.z),
                                    chamferRadius: 0)

        self.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
        self.geometry = self.planeGeometry

        let materialParent = SCNMaterial()
        materialParent.diffuse.contents = UIImage(named: "grid2")
        self.geometry!.materials = [materialParent]


        // PHYSICS
        let planePhysics = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry!, options: nil))
        planePhysics.friction = 1.0
        planePhysics.categoryBitMask = CollisionTypes.plane.rawValue
        planePhysics.contactTestBitMask = CollisionTypes.shape.rawValue
        self.physicsBody = planePhysics
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Defines plane as selected to insert the game's board
    func setSelected() {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)
        self.planeGeometry!.materials = [material]
        self.isSelected = true
    }
    
    // Remove plane from sceneview
    func remove() {
        self.removeFromParentNode()
    }
    
    // Update plane, when more surface is detected during scan
    func update(anchor: ARPlaneAnchor) {
        self.planeGeometry!.width = CGFloat(anchor.extent.x)
        self.planeGeometry!.length = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes transform contains the translation parameters.
        // As the plane is updated the planes translation remains the same but it's center is updated so we need to update the 3D geometry position
        self.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
    }
    
    
}
