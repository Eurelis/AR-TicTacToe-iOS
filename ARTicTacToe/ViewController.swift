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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    // Used for plane detection
    var ARconfiguration = ARWorldTrackingConfiguration()
    var planes: NSMutableDictionary = [:]
    
    // Setting game on selected plane
    var selectedPlane: Plane?
    var gameCells: NSMutableDictionary = [:]
    var baseGameObject: SCNNode?
    var gameScale: Float = 1 // Scale will be calculated when setting the game depending on plane size
    
    // During game
    var winner: String?
    var playing: Int = 1 // Defines which player is playing
    var crossCells: NSMutableArray = []
    var circleCells: NSMutableArray = []
    
    // Winning
    var winTextNode: SCNNode?
    var winningTextTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [/*.showBoundingBoxes, ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints*/]
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        self.setStatus(status: "Initializing...")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.resetSceneViewSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func setStatus(status: String) {
        self.statusLabel.text = status
    }
    
    // Detecting when sceneview is tapped
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if self.baseGameObject == nil { // If the game is not set, trying to prepare board
            self.setStatus(status: "Setting game board...")
            setGameAtLocation(location: location)
        } else {
            // If the game is already set, calculating tapped cell
            getTappedCell(location: location)
        }
    }
    
    // selects the anchor at the specified location and removes all other unused anchors
    func setGameAtLocation(location: CGPoint) {
        // Hit test result from intersecting with an existing plane anchor, taking into account the plane’s extent.
        let hitResults = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if hitResults.count > 0 {
            let result: ARHitTestResult = hitResults.first!
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                
                if let selectedPlane = self.planes.value(forKey: planeAnchor.identifier.uuidString) as? Plane {
                    self.selectedPlane = selectedPlane
                    selectedPlane.setSelected() // hide selected plane
                    
                    // Remove all other detected planes
                    for key in self.planes.allKeys {
                        let thisKey = key as! String
                        if thisKey != planeAnchor.identifier.uuidString {
                            if let existingPlane = self.planes.value(forKey: thisKey) as? Plane {
                                existingPlane.remove()
                                self.planes.removeObject(forKey: thisKey)
                            }
                        }
                    }
                   
                    self.disableTracking() //disable plane tracking
                    self.prepareGame() //insert base game element
                }
            }
        }
    }
    
    // For testing and fun random uicolor generator
    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    // Find which GameCell has beep tapped from hittest result on scene
    func getTappedCell(location: CGPoint) {
        if (self.playing > 9 || self.winner != nil) { // we only need to calculate if game is not finished
            self.resetGame() // restarting game
        }
        else {
            // Retrieving hit location from scene
            let hitTestResults: [SCNHitTestResult] = self.sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true])
            if let result = hitTestResults.first { // If there is a result

                let nodeForResult = result.node //returns the detected tapped node on scene

                // Finding tapped cell from our detectors array
                for cell in self.gameCells {
                    let thisCell = cell.value as! GameCell
                    
                    // Comparing found tapped node and registered gamecells' nodes
                    if thisCell.detector == nodeForResult {
                        print ("Hit result : Cell ", thisCell.key)
                        if thisCell.containsElement == nil {
                            // If cell is empty, inserting element
                            self.insertObjectInCell(cell: thisCell)
                        }
                        break
                    }
                    
                }
            }
        }
    }
    
    // On tap on the refresh button
    @IBAction func refreshScene(_ sender: Any) {
        self.resetGame()
        self.resetSceneViewSession()
    }
    
    // Restarting game
    func resetGame() {
        self.circleCells = []
        self.crossCells = []
        self.playing = 1
        self.winner = nil
        
        if (self.winningTextTimer != nil) {
            self.winningTextTimer!.invalidate()
            self.winningTextTimer = nil
        }
        
        if (self.winTextNode != nil) {
            self.winTextNode!.removeFromParentNode()
            self.winTextNode = nil
        }
        
        for cell in self.gameCells {
            let thisCell = cell.value as! GameCell
            thisCell.emptyCell()
        }
        
        self.updateGameStatus()
        self.setGameColor(color: self.generateRandomColor())
    }
    
    
    // Setting board game
    func prepareGame() {
        guard let currentPlane = self.selectedPlane else {
            return
        }
        
        // retrieve base 3D scene element
        if let tictactoeScene = SCNScene(named: "art.scnassets/tictactoe.scn") {
            if let tictactoeBase = tictactoeScene.rootNode.childNode(withName: "base", recursively: false)  {
                
                // TODO: update this with real material later to make it look better
                let material = SCNMaterial()
                material.diffuse.contents = self.generateRandomColor()
                tictactoeBase.geometry!.materials = [material]
                
                // Retrieve real object width (which is the same as height as it is a square)
                let tictactoeSize = tictactoeBase.boundingBox.max.x - tictactoeBase.boundingBox.min.x
                
                // Retrieve plane width and height to calculate center and rescale element
                let planeWidth = Float(currentPlane.planeGeometry!.width)
                let planeHeight = Float(currentPlane.planeGeometry!.height)
                
                // Rescale 3D object to match plane sizes
                let gameSize = planeWidth < planeHeight ? planeWidth : planeHeight
                self.gameScale = (gameSize / tictactoeSize) / 1.5
                tictactoeBase.scale = SCNVector3Make(self.gameScale, self.gameScale, self.gameScale)
                
                // Add the object to the plane
                currentPlane.addChildNode(tictactoeBase)
                
                self.baseGameObject = tictactoeBase
                self.setGameCells()
            }
        }
    }
    
    // Calculating and setting cell "detectors"
    func setGameCells() {
        guard let baseGameElement = self.baseGameObject else {
            return
        }
        
        let baseGameSize = (baseGameElement.boundingBox.max.x - baseGameElement.boundingBox.min.x) * self.gameScale
        let borderWidth: Float = 2.0 * self.gameScale
        let cellSize: Float  = (baseGameSize - borderWidth) / 3
        
        let baseCenterX = self.baseGameObject!.position.x
        let baseCenterY = self.baseGameObject!.position.y
        
        // TOP LEFT
        self.addPlaneDetector(key: "1", cellSize: cellSize, centerX: baseCenterX - cellSize, centerY: baseCenterY + cellSize)
        
        // TOP MIDDLE
        self.addPlaneDetector(key: "2", cellSize: cellSize, centerX: baseCenterX - cellSize, centerY: baseCenterY)
        
        // TOP RIGHT
        self.addPlaneDetector(key: "3", cellSize: cellSize, centerX: baseCenterX - cellSize, centerY: baseCenterY - cellSize)
        
        // MIDDLE LEFT
        self.addPlaneDetector(key: "4", cellSize: cellSize, centerX: baseCenterX, centerY: baseCenterY + cellSize)
        
        // MIDDLE
        self.addPlaneDetector(key: "5", cellSize: cellSize, centerX: baseCenterX, centerY: baseCenterY)
        
        // MIDDLE RIGHT
        self.addPlaneDetector(key: "6", cellSize: cellSize, centerX: baseCenterX, centerY: baseCenterY - cellSize)
        
        // BOTTOM LEFT
        self.addPlaneDetector(key: "7", cellSize: cellSize, centerX: baseCenterX + cellSize, centerY: baseCenterY + cellSize)
        
        // BOTTOM MIDDLE
        self.addPlaneDetector(key: "8", cellSize: cellSize, centerX: baseCenterX + cellSize, centerY: baseCenterY)
        
        // BOTTOM RIGHT
        self.addPlaneDetector(key: "9", cellSize: cellSize, centerX: baseCenterX + cellSize, centerY: baseCenterY - cellSize)
        
        self.setStatus(status: "Waiting for X to play")
    }
    
    // Adding detectors in cells
    func addPlaneDetector(key: String, cellSize: Float, centerX: Float, centerY: Float) {
        let formattedCellSize = CGFloat(cellSize)
        
        // Creating a detector plane in a node
        let detectorPlane = SCNPlane(width: formattedCellSize / 2, height: formattedCellSize / 2)
        let detector = SCNNode(geometry: detectorPlane)
       
        // Transparent color for detector planes
        let materialDetector = SCNMaterial()
        materialDetector.diffuse.contents = UIColor.purple.withAlphaComponent(0)
        detector.geometry!.materials = [materialDetector]
        
        // We need to set the detector planes slightly higher than the board object so that it can detect touch
        let heightPosition = (self.baseGameObject!.boundingBox.max.z * self.gameScale) + 0.01
        
        detector.position = SCNVector3Make(
            centerX,
            heightPosition,
            centerY)
      
        // Default planes are vertical, rotating it to be horizontal
        let angleRotation = Float(-Double.pi / 2.0)
        detector.rotation = SCNVector4Make(1, 0, 0, angleRotation);
        
        // Adding detector to scene
        self.selectedPlane!.addChildNode(detector)
        
        // Saving cell for later use
        self.gameCells.setValue(GameCell(key: key, detector: detector), forKey: key) // Adding gamecell to local array
    }
    
    
    // Insert game element in selected cell
    func insertObjectInCell(cell: GameCell) {
        // Defining player (TODO: let player choose it's color and play against an AI)
        let player = self.playing % 2 == 0 ? "circle" : "cross" // circle playing on pair numbers
        
        // Retrieving 3D element (note that this could be done by simply inserting an SCNText node too)
        if let tictactoeScene = SCNScene(named: "art.scnassets/"+player+".scn") {
            if let tictactoeElement = tictactoeScene.rootNode.childNode(withName: player, recursively: false) {

                // TODO: set material to make the game look and feel better
                let material = SCNMaterial()
                switch player {
                case "cross":
                    material.diffuse.contents = UIColor.red
                    break
                default:
                    material.diffuse.contents = UIColor.green
                    break
                }
                tictactoeElement.geometry!.materials = [material]
                
                // TODO: add some physics to the game objects to make them "fall" on the board
                // Setting physics so the element will fall on the game - just for fun
                //tictactoeElement.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
                //tictactoeElement.physicsBody!.mass = 2.0
                //tictactoeElement.physicsBody!.categoryBitMask = 1 << 1
                
                // Rescale the element to match board size & position it in cell
                tictactoeElement.scale = SCNVector3Make(self.gameScale, self.gameScale, self.gameScale)
                tictactoeElement.position = SCNVector3Make(cell.detector.position.x, 0, cell.detector.position.z)
               
                self.selectedPlane!.addChildNode(tictactoeElement)
                
                // Update cell element with player color, and fill arrays for result calculation
                cell.setContains(node: tictactoeElement, type: player)
                if player == "cross" {
                    self.crossCells.add(cell.key)
                } else {
                    self.circleCells.add(cell.key)
                }
               
                self.playing = self.playing + 1
                self.updateGameStatus()
            }
        }
    }
    
    
    // Updating game status : checking if game is over or updating status text
    func updateGameStatus() {
        var gameIsOver: Bool = false
        if (self.playing >= 5) { // After 5 pieces have been placed, there could be a winner
            self.checkGameResult()
            
            if (self.playing > 9 && self.winner == nil) { // If 9 pieces have been placed and still no winner : it's a tie!
                gameIsOver = true
            }
        }
        
        
        if (!gameIsOver && self.winner == nil) {
            let player: String = self.playing % 2 == 0 ? "O":"X"
            self.setStatus(status: "Waiting for \(player) to play")
        } else {
            self.endGame()
        }
    }
    
    // Calculating game result
    func checkGameResult() {
        // There are only 8 possible winning sequences
        let winningSequences = [
            [1, 2, 3],
            [1, 4, 7],
            [1, 5, 9],
            [2, 5, 8],
            [3, 5, 7],
            [3, 6, 9],
            [4, 5, 6],
            [7, 8, 9]
        ]
        
    
        // Loop on winning sequences
        for winningCellSequence in winningSequences {
            
            // Checking circle cells
            if (self.circleCells.count >= 3) {
                var winning = 0
                for selectedKey in self.circleCells {
                    let key = Int(selectedKey as! String)!
                    if winningCellSequence.contains(key) {
                        winning = winning + 1
                    }
                    
                    if winning == 3 {
                        self.winner = "O"
                        break
                    }
                }
            }
            
            // If circle didnt win, checking cross cells
            if (self.winner == nil && self.crossCells.count >= 3) {
                var winning = 0
                for selectedKey in self.crossCells {
                    let key = Int(selectedKey as! String)!
                    if winningCellSequence.contains(key) {
                        winning = winning + 1
                    }
                    
                    if winning == 3 {
                        self.winner = "X"
                        break
                    }
                }
            }
        }
    }
    
    
    // Set End of game : show status & add 3D Text
    func endGame() {

        // Create text "-- WINS"
        var text = "Nobody wins!"
        if (self.winner != nil) {
            text = self.winner!+" wins!"
        }
        
         // Status : tap to restart
        setStatus(status: "Game is over : \(text) - Tap anywhere to restart")
        
        // Drop 3D text on game set
        self.setGameColor(color: UIColor.lightGray)
        self.draw3DText(text: text)
    }
    
    // Draw winning 3D Text
    func draw3DText(text: String) {
        let baseGameSize = (self.baseGameObject!.boundingBox.max.x - self.baseGameObject!.boundingBox.min.x) * self.gameScale
        let maxLength = baseGameSize / 3.5
        
        // Creating a custom SCNText, extrusionDepth defines the text depth
        let scnTxt = SCNText(string: text, extrusionDepth: CGFloat(maxLength / 5))
        let textNode = SCNNode(geometry: scnTxt)
        
        // Calculating text scale
        let textSize = textNode.boundingBox.max.x - textNode.boundingBox.min.x
        let textScale = (baseGameSize / textSize)
        textNode.scale = SCNVector3Make(textScale, textScale, 1)
        
        // Calculating position
        let centerX = self.baseGameObject!.position.x - ((textSize * textScale) / 2)
        let centerY = self.baseGameObject!.position.y + 0.05
        let centerZ = self.baseGameObject!.position.z
        
        textNode.position = SCNVector3Make(centerX, centerY, centerZ)
        
        self.selectedPlane!.addChildNode(textNode)
        self.winTextNode = textNode
        
        // Just for fun, changing text color every 0.2 seconds
        self.winningTextTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { (timer) in
            let material = SCNMaterial()
            material.diffuse.contents = self.generateRandomColor()
            self.winTextNode!.geometry!.materials = [material]
        }
    }
    
    // Setting game elements' color
    func setGameColor (color: UIColor) {
        let material = SCNMaterial()
        material.diffuse.contents = color
        
        if self.baseGameObject != nil && self.baseGameObject?.geometry != nil {
            self.baseGameObject!.geometry!.materials = [material]
        }
        
        for cell in self.gameCells {
            let thisCell = cell.value as! GameCell
            if thisCell.containsElement != nil {
                thisCell.containsElement!.geometry!.materials = [material]
            }
        }
    }
    
    
}
