//
//  SKManager.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 16/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import SceneKit

class SKManager {
    
    let currentSKView: SCNView
    
    init(skView: SCNView) {
        self.currentSKView = skView
    }
    
    var camera: SCNNode!
    var ground: SCNNode!
    var light: SCNNode!
    
    func setSceneKitPlane() {
    
        let groundGeometry = SCNFloor()
        groundGeometry.reflectivity = 0
        let groundMaterial = SCNMaterial()
        groundMaterial.diffuse.contents = UIImage(named: "wood_texture")
        groundGeometry.materials = [groundMaterial]
        ground = SCNNode(geometry: groundGeometry)
        
        let camera = SCNCamera()
        camera.zFar = 10000
        self.camera = SCNNode()
        self.camera.camera = camera
        self.camera.position = SCNVector3(x: 5, y: 25, z: 25)
        let constraint = SCNLookAtConstraint(target: ground)
        constraint.isGimbalLockEnabled = true
        self.camera.constraints = [constraint]
        
//        let ambientLight = SCNLight()
//        ambientLight.color = UIColor.darkGray
//        ambientLight.type = .ambient
//        self.camera.light = ambientLight
//
//        light = SKManager.getSKLight(lookAt: ground)
        
        let groundShape = SCNPhysicsShape(geometry: groundGeometry, options: nil)
        let groundBody = SCNPhysicsBody(type: .kinematic, shape: groundShape)
        groundBody.friction = 1.0
        groundBody.categoryBitMask = CollisionTypes.plane.rawValue
        groundBody.contactTestBitMask = CollisionTypes.shape.rawValue
        ground.physicsBody = groundBody
        
        currentSKView.scene = SCNScene()
        if let scene = currentSKView.scene {
            scene.rootNode.addChildNode(self.camera)
            scene.rootNode.addChildNode(ground)
           // scene.rootNode.addChildNode(light)
        }
    }
    
    static func getSKLight(lookAt: SCNNode) -> SCNNode {
        let constraint = SCNLookAtConstraint(target: lookAt)
        constraint.isGimbalLockEnabled = true
        
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.castsShadow = true
        spotLight.spotInnerAngle = 70.0
        spotLight.spotOuterAngle = 90.0
        spotLight.zFar = 500
        
        let light = SCNNode()
        light.light = spotLight
        light.position = SCNVector3(x: 0, y: 25, z: 25)
        light.constraints = [constraint]
        
        return light
    }
    
}
