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
    init(anchor: ARPlaneAnchor, hidden: Bool) {
        super.init()

        let width = CGFloat(anchor.extent.x)
        let length = CGFloat(anchor.extent.z)
        let planeHeight: CGFloat = 0.001
        
        self.planeGeometry = SCNBox(width: width, height: length, length: planeHeight, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "grid2")
        self.planeGeometry!.materials = [material]
        
        let planeNode = SCNNode(geometry: self.planeGeometry!)
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        
        // Planes in SceneKit are vertical by default so we need to rotate 90 degrees to match planes in ARKit
        let angleRotation = Float(-Double.pi / 2.0)
        planeNode.transform = SCNMatrix4MakeRotation(angleRotation, 1.0, 0.0, 0.0)
        
        // We add the new node to ourself since we inherited from SCNNode
        self.addChildNode(planeNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Defines plane as selected to insert the game's board
    func setSelected() {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0) // the plane will be invisible
        self.planeGeometry!.materials = [material]
        self.isSelected = true
        
        // Defines physics body to be able to drop elements on the plane
        self.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: self.planeGeometry!, options: nil))
    }
    
    // Remove plane from sceneview
    func remove() {
        self.removeFromParentNode()
    }
    
    // Update plane, when more surface is detected during scan
    func update(anchor: ARPlaneAnchor) {
        self.planeGeometry!.width = CGFloat(anchor.extent.x)
        self.planeGeometry!.height = CGFloat(anchor.extent.z)
        
        // When the plane is first created it's center is 0,0,0 and the nodes transform contains the translation parameters.
        // As the plane is updated the planes translation remains the same but it's center is updated so we need to update the 3D geometry position
        self.position = SCNVector3(anchor.center.x, 0, anchor.center.z)
    }
    
    
}
