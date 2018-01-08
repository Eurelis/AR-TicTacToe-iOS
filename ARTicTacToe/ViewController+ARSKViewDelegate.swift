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
        self.ARconfiguration.planeDetection = .horizontal
        
        sceneView.session.run(self.ARconfiguration, options: [.removeExistingAnchors, .resetTracking])
        
        for node in self.sceneView.scene.rootNode.childNodes {
            node.removeFromParentNode()
        }
        
        self.planes = [:]
        self.selectedPlane = nil
        self.gameCells = [:]
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
        
            
        let plane = Plane(anchor: thisAnchor)
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
