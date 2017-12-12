//
//  ViewController+ARSKViewDelegate.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 06/12/2017.
//  Copyright © 2017 Eurelis. All rights reserved.
//

import ARKit

extension ViewController: ARSKViewDelegate {
    
    // Reseting sceneview session
    func resetSceneViewSession() {
        self.setStatus(status: "Initializing...")
        self.ARconfiguration.planeDetection = ARWorldTrackingConfiguration.PlaneDetection.horizontal
        
        sceneView.session.run(self.ARconfiguration, options: [ARSession.RunOptions.removeExistingAnchors,
                                                              ARSession.RunOptions.resetTracking])
        
        if self.baseGameObject != nil {
            self.baseGameObject!.removeFromParentNode()
            self.baseGameObject = nil
        }
        
        if (self.planes.count > 0) {
            for key in self.planes.allKeys {
                let thisKey = key as! String
                if let existingPlane = self.planes.value(forKey: thisKey) as? Plane {
                    existingPlane.remove()
                    self.planes.removeObject(forKey: thisKey)
                }
            }
        }
        self.setStatus(status: "Scanning for planes - Move around to detect planes")
    }
    
    // Stop plane tracking 
    func disableTracking () {
        self.ARconfiguration.planeDetection = []
        self.sceneView.session.run(self.ARconfiguration, options: [])
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let thisAnchor = anchor as? ARPlaneAnchor else{
            return
        }
        
        let plane = Plane(anchor: thisAnchor, hidden: false)
        node.addChildNode(plane)
        self.planes.setValue(plane, forKey: thisAnchor.identifier.uuidString)
        
        // Updating status on main thread
        DispatchQueue.main.async {
            self.setStatus(status: "\(self.planes.count) planes detected - Tap on it to play")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let thisAnchor = anchor as? ARPlaneAnchor else{
            return
        }
        
        // See if this is a plane we are currently rendering
        guard let plane: Plane = self.planes.value(forKey: thisAnchor.identifier.uuidString) as? Plane else {
            return
        }
        
        if !plane.isSelected {
            plane.update(anchor: thisAnchor)
        }
        
    }
    
    
}
