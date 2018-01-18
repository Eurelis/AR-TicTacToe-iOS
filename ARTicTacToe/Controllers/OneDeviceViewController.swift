//
//  ViewController.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 05/12/2017.
//  Copyright © 2017 Eurelis. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class OneDeviceViewController: UIViewController  {

    let ARCompatible = ARConfiguration.isSupported
    
    let gameManager = GameManager()
    var skManager: SKManager?
    var arManager: ARManager?
    
    // MARK: - UIView Elements
    @IBOutlet weak var sceneKitView: SCNView!
    
    @IBOutlet var ARsceneView: ARSCNView!
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
   
    @IBOutlet weak var playerCrossButton: UIButton!
    @IBOutlet weak var playerCrossHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerCircleButton: UIButton!
    @IBOutlet weak var playerCircleHeightConstraint: NSLayoutConstraint!

    
    // For AR text Position
    var currentARCameraPosition: SCNVector3?
    
    // MARK: - UIView Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameManager.delegate = self

        if ARCompatible {
            setStatus(status: "Initializing... move around to scan for planes")
            Log.info(log: "Initializing AR Scene")
            
            sceneKitView.isHidden = true
            ARsceneView.isHidden = false
            
            ARsceneView.scene.physicsWorld.contactDelegate = self
            ARsceneView.delegate = self
            
            arManager = ARManager(ARSceneView: ARsceneView)
            arManager!.startARTracking()
        }
        else {
            Log.info(log: "Initializing SceneKit Scene")
            ARsceneView.isHidden = true
            sceneKitView.isHidden = false
            statusView.isHidden = true
            
            skManager = SKManager(skView: sceneKitView)
            skManager!.setSceneKitPlane()
            setGame()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ARCompatible && arManager != nil {
            arManager!.runARSession()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseSession()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    
    // Detecting when sceneview is tapped
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: ARsceneView)
        if ARCompatible && arManager!.selectedPlane == nil { // If the game is not set, trying to prepare board
            setStatus(status: "Setting game board...")
            arManager!.setARGameAtLocation(location: location, completion: {() -> Void in
                setGame() //insert base game element
            })
        } else {
            if !gameManager.isGameOver() {
                if gameManager.getCurrentlyPlaying() == "human" {
                    getTappedCell(location: location)
                }
            }
            else {
                gameManager.resetGame()
            }
        }
    }

    
    
    // MARK: - UIView IBActions
    
    @IBAction func backToHome(_ sender: Any) {
        stopSession()
        dismiss(animated: true, completion: nil)
    }
    
    // SWITCHING PLAYERS
    @IBAction func switchModePlayerCross(_ sender: Any) {
        switchConfirmDialog() {
            self.gameManager.switchPlayerMode(button: "cross") { newMode in
                Log.debug(log: "switchModePlayerCross to \(newMode)")
                self.playerCrossButton.setImage(UIImage(named: newMode), for: .normal)
            }
        }
    }
    @IBAction func switchModePlayerCircle(_ sender: Any) {
        switchConfirmDialog() {
            self.gameManager.switchPlayerMode(button: "circle") { newMode in
                Log.debug(log: "switchModePlayerCircle to \(newMode)")
                self.playerCircleButton.setImage(UIImage(named: newMode), for: .normal)
           }
        }
    }
    
    // On tap on the refresh button
    @IBAction func refreshScene(_ sender: Any) {
       refreshAll()
    }
    
    
    // MARK: - Private methods
    private func refreshAll() {
        if ARCompatible {
            gameManager.resetGame()
            gameManager.resetGameCells()
            ARsceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
            arManager!.startARTracking()
        }
    }
    
    private func stopSession() {
        if ARCompatible {
            gameManager.resetGame()
            gameManager.resetGameCells()
            pauseSession()
        }
    }
    private func setStatus(status: String) {
        statusLabel.text = status
    }
    
    private func pauseSession() {
        if ARCompatible && arManager != nil {
            arManager!.pauseARSession()
        }
    }
    
    private func switchConfirmDialog(completion: @escaping () -> Void) {
        if !ARCompatible || arManager!.selectedPlane != nil { // show confirm dialog only if a game is already set
            let alert = UIAlertController(title: "Restart game ?", message: "Confirm player mode switch ? This will restart the current game.", preferredStyle: .alert)
            let clearAction = UIAlertAction(title: "Restart", style: .default) { (alert: UIAlertAction!) -> Void in
                completion()
                self.gameManager.resetGame()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) -> Void in
                Log.debug(log: "You pressed Cancel")
            }
            
            alert.addAction(clearAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion:nil)
        }
        else {
            completion()
        }
    }

    
    // Find which GameCell has beep tapped from hittest result on scene
    private func getTappedCell(location: CGPoint) {
        Log.info(log: "getTappedCell")
       
        var hitTestResults: [SCNHitTestResult]
        if ARCompatible {
           hitTestResults  = arManager!.currentARSceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true])
        } else {
            hitTestResults = skManager!.currentSKView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true])
        }
        gameManager.cellForHitResult(hitTestResults: hitTestResults)
    }
    
    private func setGame() {
        Log.info(log: "setGame")
        
        var parentPlane: SCNNode
        var sceneHeight: CGFloat
        var sceneWidth: CGFloat
        var sceneLength: CGFloat?
        
        if ARCompatible && arManager!.selectedPlane != nil {
            parentPlane = arManager!.selectedPlane!
            sceneHeight = arManager!.selectedPlane!.planeGeometry!.height
            sceneWidth = arManager!.selectedPlane!.planeGeometry!.width
            sceneLength = arManager!.selectedPlane!.planeGeometry!.length
        } else {
            parentPlane = skManager!.ground
            sceneHeight = skManager!.currentSKView.bounds.height
            sceneWidth = skManager!.currentSKView.bounds.width
        }
        
        gameManager.prepareGame(onPlane: parentPlane, sceneWidth: sceneWidth, sceneHeight: sceneHeight, sceneLength: sceneLength)
    }
    
}



// MARK: - SCNPhysicsContactDelegate
extension OneDeviceViewController: SCNPhysicsContactDelegate {
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
extension OneDeviceViewController: GameManagerDelegate {
    func currentPlayerChanged(manager : GameManager) {
        let activePlayerAlpha: CGFloat = 0.9
        let activePlayerHeight: CGFloat = 40
        let inactivePlayerAlpha: CGFloat = 0.2
        let inactivePlayerHeight: CGFloat = 30
        
        playerCrossButton.alpha = inactivePlayerAlpha
        playerCrossHeightConstraint.constant = inactivePlayerHeight
        playerCircleButton.alpha = inactivePlayerAlpha
        playerCircleHeightConstraint.constant = inactivePlayerHeight
        
        var player = ""
        if gameManager.playing == "cross" {
            player = "X"
            playerCrossButton.alpha = activePlayerAlpha
            playerCrossHeightConstraint.constant = activePlayerHeight
        }
        else {
            player = "O"
            playerCircleButton.alpha = activePlayerAlpha
            playerCircleHeightConstraint.constant = activePlayerHeight
        }
        
        setStatus(status: "Waiting for \(player) to play")
        Log.info(log: "Waiting for \(player) to play")
    }
    
    func getCurrentCameraPosition(manager: GameManager) -> SCNVector3? {
        guard let arManager = arManager else {
            return nil
        }
        guard let pointOfView = arManager.currentARSceneView.pointOfView else {
            return nil
        }
        
        Log.debug(log: "pointOfView position: \(pointOfView.position)")
        Log.debug(log: "pointOfView worldPosition: \(pointOfView.worldPosition)")
        return pointOfView.worldPosition
    }
}


// MARK: - ARSCNViewDelegate
extension OneDeviceViewController: ARSCNViewDelegate {
    
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
//    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
//        guard let pointOfView = arManager?.currentARSceneView.pointOfView else { return }
////        let transform = pointOfView.transform
////        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
////        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
//        currentARCameraPosition = pointOfView.position
//
//        //arManager?.currentARSceneView
//    }
    
//    private func addVector3(lhv:SCNVector3, rhv:SCNVector3) -> SCNVector3 {
//        return SCNVector3(lhv.x + rhv.x, lhv.y + rhv.y, lhv.z + rhv.z)
//    }
}

