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
        
        // Set width and length from anchors : this is overwritten by update function
        let width = CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)
               
        planeGeometry = SCNBox(width: width,
                                    height: 0.001, // custom height, only for display, overwritten when plane is selected
                                    length: length,
                                    chamferRadius: 0)
        position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)

        // Show grid to display detected plane
        let materialGrid = SCNMaterial()
        materialGrid.diffuse.contents = UIImage(named: "grid2")
        planeGeometry!.materials = [materialGrid]

        geometry = planeGeometry
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Defines plane as selected to insert the game's board
    func setSelected() {
        guard let planeGeometry = planeGeometry else {
            Log.error(log: "planeGeometry is not set")
            return
        }
        isSelected = true
        
        // Make plane invisible
        let materialTransparent = SCNMaterial()
        materialTransparent.diffuse.contents = UIColor.white.withAlphaComponent(0)
        planeGeometry.materials = [materialTransparent]
        
        // Set proportional height to be sure elements can collide and don't go through
        var height = planeGeometry.width < planeGeometry.length ? planeGeometry.width : planeGeometry.length
        height = height / 5
        planeGeometry.height = height
        
        // Set position so the top of the SCNBox is the plane
        position.y = -Float(height)

        
        // Set physics for current plane size to be sure elements collide
        let planePhysics = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
        planePhysics.friction = 1.0
        planePhysics.categoryBitMask = CollisionTypes.plane.rawValue
        planePhysics.contactTestBitMask = CollisionTypes.shape.rawValue
        physicsBody = planePhysics
    }
    
    // Remove plane from sceneview
    func remove() {
        removeFromParentNode()
    }
    
    // Update plane, when more surface is detected during scan
    // Overwrites width, length and position with new anchors
    func update(anchor: ARPlaneAnchor) {
        guard let planeGeometry = planeGeometry else {
            Log.error(log: "planeGeometry is not set")
            return
        }
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.length = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes transform contains the translation parameters.
        // As the plane is updated the planes translation remains the same but it's center is updated so we need to update the 3D geometry position
        position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
    }
    
    
}
