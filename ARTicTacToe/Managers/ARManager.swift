//
//  ARManager.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 16/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import ARKit

class ARManager {
    
    var currentARSceneView: ARSCNView
    
    // Used for plane detection
    var ARconfiguration = ARWorldTrackingConfiguration()
    var planes: NSMutableDictionary = [:]
    var selectedPlane: Plane?
    
    
    init(ARSceneView: ARSCNView) {
        currentARSceneView = ARSceneView
        
        currentARSceneView.debugOptions = [/*.showBoundingBoxes,*/ ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        currentARSceneView.autoenablesDefaultLighting = true
        currentARSceneView.automaticallyUpdatesLighting = true
    }
    
    func pauseARSession() {
       currentARSceneView.session.pause()
    }
    func runARSession() {
       currentARSceneView.session.run(ARconfiguration)
    }
    
    func startARTracking() {
        Log.info(log: "startARTracking")
        
        ARconfiguration.planeDetection = .horizontal
        currentARSceneView.session.run(ARconfiguration, options: [.removeExistingAnchors, .resetTracking])
        
        for node in currentARSceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        
        selectedPlane = nil
        planes = [:]
        setWorldBottom()
    }
    
    func disableARTracking () {
        Log.info(log: "disableARTracking")
        ARconfiguration.planeDetection = []
        
        currentARSceneView.debugOptions = []
        currentARSceneView.session.run(ARconfiguration, options: [])
    }
    
    
    
    // SETTING SCENES
    
    func setWorldBottom() {
        
        // Use a huge size to cover the entire world
        let bottomPlane = SCNBox(width: 1000, height: 0.005, length: 1000, chamferRadius: 0)
        
        // Use a clear material so the body is not visible
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [material]
        
        // Position 10 meters below the floor
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: -10, z: 0)
        
        // Apply kinematic physics, and collide with shape categories
        let physicsBody = SCNPhysicsBody.static()
        physicsBody.categoryBitMask = CollisionTypes.bottom.rawValue
        physicsBody.contactTestBitMask = CollisionTypes.shape.rawValue
        bottomNode.physicsBody = physicsBody
        
        currentARSceneView.scene.rootNode.addChildNode(bottomNode)
    }
    
    
    // selects the anchor at the specified location and removes all other unused anchors
    func setARGameAtLocation(location: CGPoint, completion: () -> Void) {
        // Hit test result from intersecting with an existing plane anchor, taking into account the plane’s extent.
        let hitResults = currentARSceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                
                if let plane = planes.value(forKey: planeAnchor.identifier.uuidString) as? Plane {
                    plane.setSelected()
                    selectedPlane = plane
                    
                    // Remove all other detected planes
                    for key in planes.allKeys {
                        let thisKey = key as! String
                        if thisKey != planeAnchor.identifier.uuidString {
                            if let existingPlane = planes.value(forKey: thisKey) as? Plane {
                                existingPlane.remove()
                                planes.removeObject(forKey: thisKey)
                            }
                        }
                    }
                    
                    disableARTracking() //disable plane tracking
                    completion()
                }
            }
        }
    }

}
