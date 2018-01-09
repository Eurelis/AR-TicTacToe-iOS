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

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    // Used for plane detection
    var ARconfiguration = ARWorldTrackingConfiguration()
    var planes: NSMutableDictionary = [:]
    
    // Setting game on selected plane
    var selectedPlane: Plane?
    var gameCells: NSMutableDictionary = [:]
    
    // During game
    // possible winning sequences
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
    
    var playing: String = "cross" // Defines which player is playing
    
    var playerCross: String = "human"
    @IBOutlet weak var playerCrossButton: UIButton!
    @IBOutlet weak var playerCrossHeightConstraint: NSLayoutConstraint!
    
    var playerCircle: String = "human"
    @IBOutlet weak var playerCircleButton: UIButton!
    @IBOutlet weak var playerCircleHeightConstraint: NSLayoutConstraint!
    
    var winner: String?
    var crossCells: NSMutableArray = []
    var circleCells: NSMutableArray = []
    
    // Winning
    var winTextNode: SCNNode?
    var winningTextTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.debugOptions = [/*.showBoundingBoxes,*/ ARSCNDebugOptions.showFeaturePoints /*ARSCNDebugOptions.showWorldOrigin*/]
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        self.setStatus(status: "Initializing...")
        self.resetSceneViewSession()
        self.setWorldBottom()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(self.ARconfiguration)
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
    
    @IBAction func switchModePlayerCross(_ sender: Any) {
        self.switchConfirmDialog(completion: {() -> Void in
            let newMode = self.playerCross == "human" ? "robot":"human"
            self.playerCross = newMode
            
            print ("switchModePlayerCross to ", newMode)
            self.playerCrossButton.setImage(UIImage(named: newMode), for: .normal)
        })
    }
    
    @IBAction func switchModePlayerCircle(_ sender: Any) {
        self.switchConfirmDialog(completion: {() -> Void in
            let newMode = self.playerCircle == "human" ? "robot":"human"
            self.playerCircle = newMode
            
            print ("switchModePlayerCircle to ", newMode)
            self.playerCircleButton.setImage(UIImage(named: newMode), for: .normal)
        })
    }
    
    private func switchConfirmDialog(completion: @escaping () -> Void) {
        
        if selectedPlane != nil { // show confirm dialog only if a game is already set
            let alert = UIAlertController(title: "Restart game ?", message: "Confirm player mode switch ? This will restart the current game.", preferredStyle: .alert)
            let clearAction = UIAlertAction(title: "Restart", style: .default) { (alert: UIAlertAction!) -> Void in
                completion()
                self.resetGame()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) -> Void in
                //print("You pressed Cancel")
            }
            
            alert.addAction(clearAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion:nil)
        }
        else {
            completion()
        }
    }
    
    func setStatus(status: String) {
        self.statusLabel.text = status
    }
    
    
    
    // Detecting when sceneview is tapped
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: sceneView)
        if self.selectedPlane == nil { // If the game is not set, trying to prepare board
            self.setStatus(status: "Setting game board...")
            setGameAtLocation(location: location)
        } else {
            let nbPlays = self.crossCells.count + self.circleCells.count
            if (nbPlays == 9 || self.winner != nil) { // we only need to calculate if game is not finished
                self.resetGame() // restarting game
            }
            else {
                // If the game is already set, calculating tapped cell
                let typePlayer = self.playing == "cross" ? self.playerCross : self.playerCircle
                if typePlayer == "human" {
                    getTappedCell(location: location)
                } else {
                    print ("cannot play! waiting for AI to play")
                }
            }
           
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
       
        // Retrieving hit location from scene
        let hitTestResults: [SCNHitTestResult] = self.sceneView.hitTest(location, options: [SCNHitTestOption.firstFoundOnly: true])
        if let result = hitTestResults.first { // If there is a result
        
            let nodeForResult = result.node //returns the detected tap
            
            // Finding tapped cell from our detectors array
            for cell in self.gameCells {
                let thisCell = cell.value as! GameCell
                
                // Comparing found tapped node and registered gamecells' nodes
                if thisCell.detector == nodeForResult {
                    print ("Hit result : Cell ", thisCell.key)
                    if thisCell.containsElement == nil {
                        // If cell is empty, inserting element
                        
                        self.insertCube(cell: thisCell)
                    }
                    break
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
        print ("resetting game")
        
        for cell in self.gameCells {
            let thisCell = cell.value as! GameCell
            thisCell.detector.removeAllParticleSystems()
            thisCell.emptyCell()
        }
        
        self.circleCells = []
        self.crossCells = []
        self.winner = nil
        
        if (self.winningTextTimer != nil) {
            self.winningTextTimer!.invalidate()
            self.winningTextTimer = nil
        }
        
        if (self.winTextNode != nil) {
            self.winTextNode!.removeFromParentNode()
            self.winTextNode = nil
        }
        
        self.setNextPlayer(nextPlayer: "cross")
    }
    
    private func setNextPlayer(nextPlayer: String?) {
        print ("setNextPlayer to : ", nextPlayer)
        
        let activePlayerAlpha: CGFloat = 0.9
        let activePlayerHeight: CGFloat = 40
        let inactivePlayerAlpha: CGFloat = 0.2
        let inactivePlayerHeight: CGFloat = 30
        
        if nextPlayer == nil {
            self.playing = self.playing == "cross" ? "circle":"cross"
        } else {
            self.playing = nextPlayer!
        }
        
        self.playerCrossButton.alpha = inactivePlayerAlpha
        self.playerCrossHeightConstraint.constant = inactivePlayerHeight
        self.playerCircleButton.alpha = inactivePlayerAlpha
        self.playerCircleHeightConstraint.constant = inactivePlayerHeight
        
        var typeCurrentPlayer = ""
        if self.playing == "cross" {
            typeCurrentPlayer = self.playerCross
            self.playerCrossButton.alpha = activePlayerAlpha
            self.playerCrossHeightConstraint.constant = activePlayerHeight
        }
        else {
            typeCurrentPlayer = self.playerCircle
            self.playerCircleButton.alpha = activePlayerAlpha
            self.playerCircleHeightConstraint.constant = activePlayerHeight
        }
    
        let player: String = self.playing == "circle" ? "O":"X"
        self.setStatus(status: "Waiting for \(player) to play")
        
        if typeCurrentPlayer == "robot" {
            // function AI plays
            
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
               self.AIMove()
            }
        }
        
    }
    
    
    private func AIMove() {
        
        print ("Currently playing : ", self.playing)
        let currentPlayerMoves = self.playing == "cross" ? self.crossCells : self.circleCells
        let opponentMoves = self.playing == "cross" ? self.circleCells : self.crossCells
        
        // If AI is cross:
        // -> 1. find which cells have circles
        //      -> if two, then put cross in third
        //      -> if one, go to 2.
        // -> 2. find which cells have cross
        //      -> if two, put in third
        //      -> if one, put next to it
        // -> 3. if no cross yet
        //      -> put in middle case
        //      -> if middle not free: random cell
        
        print ("_______")
        
        let winningCells: NSMutableArray = []
        let blockingCells: NSMutableArray = []
        
        // CHECK IF THERE IS A WINNING MOVE
        for winningCellSequence in self.winningSequences {
            let thisSequence = NSMutableArray(array: winningCellSequence)
            
            for selectedKey in currentPlayerMoves {
                let key = Int(selectedKey as! String)!
                if thisSequence.contains(key) {
                    thisSequence.remove(key)
                }
            }
            
            // If there is only one missing to win, add it and win
            if thisSequence.count == 1 {
                let winningMove = thisSequence[0] as! Int
                
                let thisCell = self.gameCells.object(forKey: String(winningMove)) as! GameCell
                if thisCell.containsElement == nil {
                    winningCells.add(winningMove)
                }
            }
        }
        
        print ("winning moves: ", winningCells)
        if winningCells.count > 0 {
            let randomWinningIndex = Int(arc4random_uniform(UInt32(winningCells.count)))
            let randomWinningMove = winningCells[randomWinningIndex]  as! Int
            let randomWinningCell = self.gameCells.object(forKey: String(randomWinningMove)) as! GameCell
            self.insertCube(cell: randomWinningCell)
        }
       
        // IF THERE IS NO WINNING MOVE, CHECKING FOR BLOCKING MOVE
        if winningCells.count == 0 {
            for winningCellSequence in self.winningSequences {
                let thisSequence = NSMutableArray(array: winningCellSequence)
                
                for selectedKey in opponentMoves {
                    let key = Int(selectedKey as! String)!
                    if thisSequence.contains(key) {
                        thisSequence.remove(key)
                    }
                }
                
                // If there is only one missing to win, block
                if thisSequence.count == 1 {
                    let blockingMove = thisSequence[0] as! Int
                    let thisCell = self.gameCells.object(forKey: String(blockingMove)) as! GameCell
                    if thisCell.containsElement == nil {
                        blockingCells.add(blockingMove)
                    }
                }
            }
            print ("blocking moves: ", blockingCells)
            
            if blockingCells.count > 0 {
                let randomBlockingIndex = Int(arc4random_uniform(UInt32(blockingCells.count)))
                let randomBlockingMove = blockingCells[randomBlockingIndex] as! Int
                let randomBlockingCell = self.gameCells.object(forKey: String(randomBlockingMove)) as! GameCell
                self.insertCube(cell: randomBlockingCell)
            }
            
        }
        
        // IF THERE IS NO WINNING OR BLOCKING MOVES, RANDOM MOVE
        if winningCells.count == 0 && blockingCells.count == 0 {


            // CALCULATING AVAILABLE WINNING SEQUENCES
            
             // for each winning sequence
            let possibleKeys: NSMutableArray = []
            for winningCellSequence in self.winningSequences {
                var possibleSequence = false
               let thisSequence = NSMutableArray(array: winningCellSequence)
                
                // for each currentplayermoves
                for playermove in currentPlayerMoves {
                    let key = Int(playermove as! String)!
                    if thisSequence.contains(key) {
                        possibleSequence = true
                        thisSequence.remove(key)
                    }
                }
                
                if possibleSequence {
                    for oppmove in opponentMoves {
                        let key = Int(oppmove as! String)!
                        if thisSequence.contains(key) {
                            possibleSequence = false
                        }
                    }
                }
                
                if (possibleSequence) {
                    possibleKeys.addObjects(from: thisSequence as! [Any])
                    print ("possible winning sequence : ", thisSequence)
                }
            }
           
            
            if possibleKeys.count != 0 {
                 print ("possiblekeys: ", possibleKeys)
                let randomPossibleIndex = Int(arc4random_uniform(UInt32(possibleKeys.count)))
                let randomPossibleMove = possibleKeys[randomPossibleIndex]  as! Int
                let randomPossibleCell = self.gameCells.object(forKey: String(randomPossibleMove)) as! GameCell
                self.insertCube(cell: randomPossibleCell)
            }
            else {
                let emptyCells: NSMutableArray = []
                for cell in self.gameCells {
                    let thisCell = cell.value as! GameCell
                    if thisCell.containsElement == nil {
                        emptyCells.add(thisCell.key)
                    }
                }
                print ("possible moves: ", emptyCells)
                if emptyCells.count > 0 {
                    let randomIndex = Int(arc4random_uniform(UInt32(emptyCells.count)))
                    let randomMove = emptyCells[randomIndex]
                    let randomCell = self.gameCells.object(forKey: randomMove) as! GameCell
                    self.insertCube(cell: randomCell)
                }
            }
            
        }
        
    }
    
    // Setting board game
    func prepareGame() {
        guard let currentPlane = self.selectedPlane else {
            return
        }
        
        // Create grille
        let length = currentPlane.planeGeometry!.width / 2
        let cellSize = length / 3
        let onethird = Float(cellSize) / 2
        
        let width = cellSize / 10
        let zPosition = Float(currentPlane.planeGeometry!.height + (width / 2))

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red

        let bar = SCNBox(width: width, height: width, length: length, chamferRadius: 0)
        let nodeBar1 = SCNNode(geometry: bar)
        nodeBar1.geometry!.materials = [material]
        nodeBar1.position = SCNVector3Make(-onethird, zPosition, 0)

        let bar2 = SCNBox(width: width, height: width, length: length, chamferRadius: 0)
        let nodeBar2 = SCNNode(geometry: bar2)
        nodeBar2.geometry!.materials = [material]
        nodeBar2.position = SCNVector3Make(onethird, zPosition, 0)


        let bar3 = SCNBox(width: length, height: width, length: width, chamferRadius: 0)
        let nodeBar3 = SCNNode(geometry: bar3)
        nodeBar3.geometry!.materials = [material]
        nodeBar3.position = SCNVector3Make(0, zPosition, -onethird)


        let bar4 = SCNBox(width: length, height: width, length: width, chamferRadius: 0)
        let nodeBar4 = SCNNode(geometry: bar4)
        nodeBar4.geometry!.materials = [material]
        nodeBar4.position = SCNVector3Make(0, zPosition, onethird)

        currentPlane.addChildNode(nodeBar1)
        currentPlane.addChildNode(nodeBar2)
        currentPlane.addChildNode(nodeBar3)
        currentPlane.addChildNode(nodeBar4)

        self.setGameCells(cellSize: cellSize)
    }
    
    // Calculating and setting cell "detectors"
    func setGameCells(cellSize: CGFloat) {
        print ("settingGameCells")
        // TOP LEFT
        self.addPlaneDetector(key: "1", cellSize: cellSize, centerX: cellSize, centerY: cellSize)

        // TOP MIDDLE
        self.addPlaneDetector(key: "2", cellSize: cellSize, centerX: cellSize, centerY: 0)

        // TOP RIGHT
        self.addPlaneDetector(key: "3", cellSize: cellSize, centerX: cellSize, centerY: -cellSize)

        // MIDDLE LEFT
        self.addPlaneDetector(key: "4", cellSize: cellSize, centerX: 0, centerY: cellSize)

        // MIDDLE
        self.addPlaneDetector(key: "5", cellSize: cellSize, centerX: 0, centerY: 0)

        // MIDDLE RIGHT
        self.addPlaneDetector(key: "6", cellSize: cellSize, centerX: 0, centerY: -cellSize)

        // BOTTOM LEFT
        self.addPlaneDetector(key: "7", cellSize: cellSize, centerX: -cellSize, centerY: cellSize)

        // BOTTOM MIDDLE
        self.addPlaneDetector(key: "8", cellSize: cellSize, centerX: -cellSize, centerY: 0)

        // BOTTOM RIGHT
        self.addPlaneDetector(key: "9", cellSize: cellSize, centerX: -cellSize, centerY: -cellSize)

        // TODO remove status bar ?
        self.setStatus(status: "Waiting for X to play")
        self.setNextPlayer(nextPlayer: "cross")
    }
    
    // Adding detectors in cells
    func addPlaneDetector(key: String, cellSize: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        guard let currentPlane = self.selectedPlane else {
            return
        }
        
        let formattedCellSize = cellSize / 1.5

        // Creating a detector plane in a node
        let detectorBox = SCNBox(width: formattedCellSize, height: formattedCellSize, length: formattedCellSize, chamferRadius: 0)
        let detector = SCNNode(geometry: detectorBox)
       
        // Transparent color for detector planes
        let materialDetector = SCNMaterial()
        materialDetector.diffuse.contents = UIColor.purple.withAlphaComponent(0)
        detector.geometry!.materials = [materialDetector]
        
        // We need to set the detector planes slightly higher than the board object so that it can detect touch
        let zPosition = formattedCellSize / 2

        detector.position = SCNVector3Make(
            Float(centerX),
            Float(zPosition),
            Float(centerY))
    
        
        // Adding detector to scene
        currentPlane.addChildNode(detector)

        // Saving cell for later use
        self.gameCells.setValue(GameCell(key: key, detector: detector), forKey: key) // Adding gamecell to local array
    }
    
    
    
    
    func insertCube(cell: GameCell) {
        guard let currentPlane = self.selectedPlane else {
            return
        }
        
        let cellWidth = cell.detector.boundingBox.max.x - cell.detector.boundingBox.min.x
        let cellHeight = cell.detector.boundingBox.max.y - cell.detector.boundingBox.min.y
        
       // let size = CGFloat(cell.detector.boundingBox.max.x)
        let size = CGFloat(cellWidth)
        let cube = SCNBox(width: size, height: CGFloat(cellHeight), length: size, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0)
        cube.materials = [material]
        
        let cubeNode = SCNNode(geometry: cube)
        
        //let yPosition = Float(currentPlane.planeGeometry!.height + cube.height)
        let yDropPosition: Float = 0.1
        cubeNode.position = SCNVector3Make(cell.detector.position.x,
                                           cell.detector.position.y + yDropPosition,
                                           cell.detector.position.z)
        
        
        let shape = SCNPhysicsShape(geometry: cube, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody.mass = 1.0
        physicsBody.restitution = 0.5
        physicsBody.friction = 1.0
        physicsBody.categoryBitMask = CollisionTypes.shape.rawValue
        
        cubeNode.physicsBody = physicsBody
        
        let player = self.playing // circle playing on pair numbers
        if let playerElement = self.getPlayerObject(player: player, container: cubeNode) {
            
            cubeNode.addChildNode(playerElement)
            cell.setContains(node: cubeNode, type: player)
            
            if player == "cross" {
                self.crossCells.add(cell.key)
            } else {
                self.circleCells.add(cell.key)
            }
            
            self.updateGameStatus()
            currentPlane.addChildNode(cubeNode)
        }
        
    }
    
    
    // Insert game element in selected cell
    func getPlayerObject(player: String, container: SCNNode) -> SCNNode? {
        
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
                
                // Calculate scale for elements
                let elementSize = tictactoeElement.boundingBox.max.x - tictactoeElement.boundingBox.min.x
                let containerSize = container.boundingBox.max.x - container.boundingBox.min.x
                
                let scale = containerSize / elementSize
                tictactoeElement.scale = SCNVector3Make(scale, scale, scale)
                
                let elementHeight = tictactoeElement.boundingBox.max.z - tictactoeElement.boundingBox.min.z
                let elementHeightScaled = elementHeight * scale
                tictactoeElement.position.y = container.boundingBox.min.y + elementHeightScaled
                
               return tictactoeElement
            }
        }
        return nil
    }
    
    
    // Updating game status : checking if game is over or updating status text
    func updateGameStatus() {
        let nbPlays = self.circleCells.count + self.crossCells.count
        
        var gameIsOver: Bool = false
        if (nbPlays >= 5) { // After 5 pieces have been placed, there could be a winner
            self.checkGameResult()
            if (nbPlays == 9 && self.winner == nil) { // If 9 pieces have been placed and still no winner : it's a tie!
                gameIsOver = true
            }
        }
        
        if (gameIsOver || self.winner != nil) {
            self.endGame()
        } else {
            self.setNextPlayer(nextPlayer: nil)
        }
    }
    
    // Calculating game result
    func checkGameResult() {
       
        // Loop on winning sequences
        for winningCellSequence in self.winningSequences {
            
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
        self.draw3DText(text: text)
    }
    
    // Draw winning 3D Text
    func draw3DText(text: String) {
        guard let currentPlane = self.selectedPlane else {
            return
        }
        
        let baseGameSize = Float(currentPlane.planeGeometry!.width) / 2
        let maxLength = baseGameSize / 3.5
        
        // Creating a custom SCNText, extrusionDepth defines the text depth
        let scnTxt = SCNText(string: text, extrusionDepth: CGFloat(maxLength / 5))
        let textNode = SCNNode(geometry: scnTxt)
        
        // Calculating text scale
        let textLength = textNode.boundingBox.max.x - textNode.boundingBox.min.x
        let textScale = baseGameSize / textLength
        textNode.scale = SCNVector3Make(textScale, textScale, 1)

        let halfLength = textLength / 2
        let scaledHalfLength = halfLength * textScale
        textNode.position.x = -scaledHalfLength

        let textHeight = textNode.boundingBox.max.y - textNode.boundingBox.min.y
        let halfHeight = textHeight / 2
        let scaledHalfHeight = halfHeight * textScale
        textNode.position.y = scaledHalfHeight
        
        currentPlane.addChildNode(textNode)
        self.winTextNode = textNode
        let materialText = SCNMaterial()
        materialText.diffuse.contents = self.generateRandomColor()
        self.winTextNode!.geometry!.materials = [materialText]
        
        
        // Just for fun, changing text color every 0.2 seconds
        self.winningTextTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
            let material = SCNMaterial()
            material.diffuse.contents = self.generateRandomColor()
            self.winTextNode!.geometry!.materials = [material]
            
            self.explodePiece() // Explosion in random cell
        }
    }
    
    var cellExploded = 0
    func explodePiece() {
        
        self.cellExploded = self.cellExploded + 1

        if self.cellExploded == 10 {
            self.cellExploded = 1
        }
        
        let thisCell = self.gameCells.value(forKey: String(self.cellExploded)) as! GameCell
        if let particleSystem = SCNParticleSystem(named: "Explosion", inDirectory: "art.scnassets/Explosion") {
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem)
            thisCell.detector.addChildNode(systemNode)
            
            thisCell.emptyCell()
        }
    }
    
    
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
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let mask = contact.nodeA.physicsBody!.categoryBitMask | contact.nodeB.physicsBody!.categoryBitMask
        
        if CollisionTypes(rawValue: mask) == [CollisionTypes.bottom, CollisionTypes.shape] {
            // Contact avec le bottom
            if contact.nodeA.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeB.removeFromParentNode()
                print ("an object reached the bottom and was removed")
            } else if contact.nodeB.physicsBody!.categoryBitMask == CollisionTypes.bottom.rawValue {
                contact.nodeA.removeFromParentNode()
                print ("an object reached the bottom and was removed")
            }
        }
    }
    
}
