//
//  OneDeviceViewController+ARSKViewDelegate.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 15/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import ARKit
import UIKit


extension OneDeviceViewController: ARSKViewDelegate {
    
    // Reseting sceneview session
    func resetSceneViewSession() {
        Log.info(log: "SceneView session reset")
        
        self.ARconfiguration.planeDetection = .horizontal
        ARsceneView.session.run(self.ARconfiguration, options: [.removeExistingAnchors, .resetTracking])
        
        for node in self.ARsceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        
        self.planes = [:]
        self.selectedPlane = nil
        self.gameCells = [:]
        self.setStatus(status: "Scanning for planes - Move around to detect planes")
    }
    
    // Stop plane tracking
    func disableTracking () {
        Log.info(log: "tracking disabled")
        self.ARconfiguration.planeDetection = []
        
        ARsceneView.debugOptions = []
        self.ARsceneView.session.run(self.ARconfiguration, options: [])
    }
    
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let thisAnchor = anchor as? ARPlaneAnchor else{
            return
        }
        
        let plane = Plane(anchor: thisAnchor)
        node.addChildNode(plane)
        self.planes.setValue(plane, forKey: thisAnchor.identifier.uuidString)
        Log.info(log: "Found new plane")
        
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
