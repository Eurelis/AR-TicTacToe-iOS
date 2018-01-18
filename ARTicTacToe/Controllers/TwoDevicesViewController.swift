//
//  TwoDevicesViewController.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 11/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import MultipeerConnectivity

class TwoDevicesViewController: UIViewController {
    
    var isHost = false
    
    let ARCompatible = ARConfiguration.isSupported
    
    let gameManager = GameManager()
    var skManager: SKManager?
    var arManager: ARManager?
    
    @IBOutlet weak var sceneKitView: SCNView!
    @IBOutlet weak var ARsceneView: ARSCNView!
    
    @IBOutlet weak var prepareGameView: UIView!
    @IBOutlet weak var prepareInfoLabel: UILabel!
    @IBOutlet weak var prepareReadyButton: UIButton!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!


    var isConnectedTo: MCPeerID?
    @IBOutlet weak var statusLabel: UILabel!
    
    var currentARCameraPosition: SCNVector3?
    
    // MARK: - UIView methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        self.prepareGameView.isHidden = true
        
        let status = isHost ? "Waiting for connection" : "Waiting for host"
        setStatus(status: status)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isConnectedTo == nil {
            Log.info(log: "Device is not yet connected")
            
            if (isHost) {
                Log.info(log: "Hosting new session")
                mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "eurelis-tictac", discoveryInfo: nil, session: mcSession)
                mcAdvertiserAssistant.start()
            }
            else {
                Log.info(log: "Scanning for host")
                let mcBrowser = MCBrowserViewController(serviceType: "eurelis-tictac", session: mcSession)
                mcBrowser.maximumNumberOfPeers = 1
                mcBrowser.delegate = self
                present(mcBrowser, animated: true)
            }
        }
    }
    
    // MARK: - UIView Actions
    @IBAction func backToHome(_ sender: Any) {
        Log.info(log: "Session disconnected")
        mcSession.disconnect()
        isConnectedTo = nil
        setStatus(status: "Disconnected")
        dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: - Private methods
    private func setStatus(status:String) {
        DispatchQueue.main.async {
            self.statusLabel.text = status
        }
    }
    
    private func displayPrepareInfo() {
        // send info to other device : ARCompatible
        Log.info(log:"displayPrepareInfo")
        
        guard let isConnectedTo = isConnectedTo else {
            Log.error(log: "Can't send data to disconnected peer")
            return
        }
        
        let dictionary = ["isARCompatible": ARCompatible]
        
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: PropertyListSerialization.PropertyListFormat.binary, options: 0)
            try mcSession.send(data, toPeers: [isConnectedTo], with: .reliable)
        } catch {
            Log.error(log:"error sending data")
        }

        
//        if ARCompatible {
//            Log.info(log: "displayPrepareInfo ARCompatible")
//            prepareGameView.isHidden = false
//            prepareInfoLabel.text = "Place both devices next to each other on a plane, then tap READY"
//        } else {
//            Log.info(log: "displayPrepareInfo no AR")
//            prepareGameView.isHidden = false
//            prepareInfoLabel.text = "Waiting for other device to be ready"
//            prepareReadyButton.isHidden = true
//        }
    }
    
    
    private func prepareScene() {
        
        Log.info(log: "Devices are connected and waiting for game set ")
        
        // TODO GAME SET
       
        gameManager.delegate = self
        
        if ARCompatible {

            Log.info(log: "Initializing AR Scene")
            
            sceneKitView.isHidden = true
            ARsceneView.isHidden = false
            
            ARsceneView.scene.physicsWorld.contactDelegate = self
            ARsceneView.delegate = self
            
            arManager = ARManager(ARSceneView: ARsceneView)
            
            
        }
        else {
            Log.info(log: "Initializing SceneKit Scene")
            ARsceneView.isHidden = true
            sceneKitView.isHidden = false
            
            skManager = SKManager(skView: sceneKitView)
           // skManager!.setSceneKitPlane()
           // setGame()
        }
        
        /*
         5. When device selected : popup "Please put both devices next to each other" and tap Ready
         
         6. When both devices "ready" : on device 1 "please scan your surrounding to find a plane" / "tap to select and set game"
         7. When game is set :
         - device 1 : "waiting for device 2" ---> READY
         - device 2 : "receiving data" / "game is set" ---> READY
         
         8. When both ready, start game, send data to other device when player played
         
         */
    }

}


// MARK: - MCBrowserViewControllerDelegate
extension TwoDevicesViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
}

// MARK: - MCSessionDelegate
extension TwoDevicesViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            isConnectedTo = peerID
            Log.info(log: "Connected to: \(peerID.displayName)")
            if !isHost {
                dismiss(animated: true) // Dismissing scan browser
            }

            // Updating scene on main thread
            DispatchQueue.main.async {
                self.setStatus(status: "Connected to: \(peerID.displayName)")
                self.displayPrepareInfo()
            }
        case MCSessionState.connecting:
            isConnectedTo = nil
            Log.info(log: "Connecting to: \(peerID.displayName)")
            setStatus(status: "Connecting to: \(peerID.displayName)")
        case MCSessionState.notConnected:
            isConnectedTo = nil
            Log.info(log: "Disconnected from: \(peerID.displayName)")
            setStatus(status: "Disconnected")
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        Log.info(log:"didReceive data from \(peerID.displayName)")
        
        if peerID == isConnectedTo {
            do {
                
                let dictionary = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as AnyObject
                if let peerIsAR = dictionary.value(forKey: "isARCompatible") as? Bool {
                    Log.info(log:"didReceive AR Info : \(peerIsAR)")
                    DispatchQueue.main.async {
                        let currentStatus = self.statusLabel.text!
                        let arStatus = peerIsAR ? "(AR)":"(Non AR)"
                        self.setStatus(status: currentStatus+" "+arStatus)
                    }
                }
            
            } catch {
                Log.error(log:"could not convert data")
            }
        }
        
        
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension TwoDevicesViewController: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Log.error(log: "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Log.info(log: "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, mcSession)
    }
}


// MARK: - SCNPhysicsContactDelegate
extension TwoDevicesViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.bottom, CollisionTypes.shape] {
            // Contact avec le bottom
            if contact.nodeA.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeB.removeFromParentNode()
                Log.info(log: "an object reached the bottom and was removed")
            } else if contact.nodeB.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeA.removeFromParentNode()
                Log.info(log: "an object reached the bottom and was removed")
            }
        }
    }
}


// MARK: - GameManagerDelegate
extension TwoDevicesViewController: GameManagerDelegate {
    func currentPlayerChanged(manager : GameManager) {
    }
    
    func getCurrentCameraPosition(manager: GameManager) -> SCNVector3? {
        guard arManager != nil else {
            Log.info(log: "Trying to get position of a scenekit view")
            return nil
        }
        return currentARCameraPosition
    }
}


// MARK: - ARSCNViewDelegate
extension TwoDevicesViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let thisAnchor = anchor as? ARPlaneAnchor else{
            return
        }
        Log.info(log: "Found new plane")
        
        let plane = Plane(anchor: thisAnchor)
        node.addChildNode(plane)
        arManager!.planes.setValue(plane, forKey: thisAnchor.identifier.uuidString)
        
        // Updating status on main thread
        DispatchQueue.main.async {
            self.setStatus(status: "\(self.arManager!.planes.count) planes detected - Tap on it to play")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let thisAnchor = anchor as? ARPlaneAnchor else{
            return
        }
        
        // See if this is a plane we are currently rendering
        guard let plane: Plane = arManager!.planes.value(forKey: thisAnchor.identifier.uuidString) as? Plane else {
            return
        }
        
        if !plane.isSelected {
            plane.update(anchor: thisAnchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = arManager?.currentARSceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        currentARCameraPosition = addVector3(lhv: orientation, rhv: location)
    }
    
    private func addVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
    }
}

