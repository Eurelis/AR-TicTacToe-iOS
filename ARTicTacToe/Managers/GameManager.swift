//
//  GameManager.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 16/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import SceneKit

// MARK: - GameManagerDelegate
protocol GameManagerDelegate {
    func currentPlayerChanged(manager : GameManager)
    func getCurrentCameraPosition(manager: GameManager) -> float3?
}

// MARK: - GameManager
class GameManager {
    
    var delegate : GameManagerDelegate?
    
    var parentPlane: SCNNode?
    var baseGameSize: CGFloat?
    
    // Setting game on selected plane
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
    var playerCircle: String = "robot"
    
    var winner: String?
    var winningTextTimer: Timer?
    var winTextNode: SCNNode?
    
    var crossCells: NSMutableArray = []
    var circleCells: NSMutableArray = []
    
    
    // MARK: - Game set
    func resetGameCells() {
        gameCells = [:]
    }
    
    func switchPlayerMode(button: String, completion: (_: String) -> Void) {
        var newMode = "human"
        if button == "cross" {
            newMode = playerCross == "human" ? "robot":"human"
            playerCross = newMode
        } else {
            newMode = playerCircle == "human" ? "robot":"human"
            playerCircle = newMode
        }
        completion(newMode)
    }
    
    func isGameOver() -> Bool {
        let nbPlays = crossCells.count + circleCells.count
        if (nbPlays == 9 || winner != nil) { // we only need to calculate if game is not finished
            return true
        }
        return false
    }
   
    func getCurrentlyPlaying() -> String {
        return playing == "cross" ? playerCross : playerCircle
    }
    
    func resetGame() {
        Log.info(log: "resetGame")
        
        for cell in gameCells {
            let thisCell = cell.value as! GameCell
            thisCell.detector.removeAllParticleSystems()
            thisCell.emptyCell()
        }
        
        circleCells = []
        crossCells = []
        winner = nil
        
        if (winningTextTimer != nil) {
            winningTextTimer!.invalidate()
            winningTextTimer = nil
        }
        
        if (winTextNode != nil) {
            winTextNode!.removeFromParentNode()
            winTextNode = nil
        }
        
        setNextPlayer(nextPlayer: "cross")
    }
    
    func setNextPlayer(nextPlayer: String?) {
        Log.info(log: "setNextPlayer")
        if nextPlayer == nil {
            playing = playing == "cross" ? "circle":"cross"
        } else {
            playing = nextPlayer!
        }
        
        delegate?.currentPlayerChanged(manager: self)
        
        let typeCurrentPlayer = playing == "cross" ? playerCross : playerCircle
        if typeCurrentPlayer == "robot" {
            // function AI plays
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
                self.AIMove()
            }
        }
        
    }
    
    func cellForHitResult(hitTestResults: [SCNHitTestResult]) {
        if let firstResult = hitTestResults.first { // If there is a result
            let nodeForResult = firstResult.node //returns the detected tap
            
            Log.info(log: "nodeForResult : \(nodeForResult)")
            // Finding tapped cell from our detectors array
            for cell in gameCells {
                let thisCell = cell.value as! GameCell
                
                // Comparing found tapped node and registered gamecells' nodes
                if thisCell.detector == nodeForResult {
                    Log.info(log: "thisCell.detector is result")
                    
                    if thisCell.containsElement == nil {
                        Log.info(log: "Tapped cell : \(thisCell.key)")
                        insertCube(cell: thisCell) // cell is empty, inserting element
                        break
                    } else {
                        Log.info(log: "cell is not empty")
                    }
                }
                
            }
        }
    }
    
    
    
    private func AIMove() {
        
        Log.debug(log: "Currently playing : \(playing)")
        let currentPlayerMoves = playing == "cross" ? crossCells : circleCells
        let opponentMoves = playing == "cross" ? circleCells : crossCells
        
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
        
        let winningCells: NSMutableArray = []
        let blockingCells: NSMutableArray = []
        
        // CHECK IF THERE IS A WINNING MOVE
        for winningCellSequence in winningSequences {
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
                
                let thisCell = gameCells.object(forKey: String(winningMove)) as! GameCell
                if thisCell.containsElement == nil {
                    winningCells.add(winningMove)
                }
            }
        }
        
        if winningCells.count > 0 {
            Log.debug(log: "winning moves: \(winningCells)")
            
            let randomWinningIndex = Int(arc4random_uniform(UInt32(winningCells.count)))
            let randomWinningMove = winningCells[randomWinningIndex]  as! Int
            let randomWinningCell = gameCells.object(forKey: String(randomWinningMove)) as! GameCell
            insertCube(cell: randomWinningCell)
        }
        
        // IF THERE IS NO WINNING MOVE, CHECKING FOR BLOCKING MOVE
        if winningCells.count == 0 {
            for winningCellSequence in winningSequences {
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
                    let thisCell = gameCells.object(forKey: String(blockingMove)) as! GameCell
                    if thisCell.containsElement == nil {
                        blockingCells.add(blockingMove)
                    }
                }
            }
            
            if blockingCells.count > 0 {
                Log.debug(log: "blocking moves: \(blockingCells)")
                let randomBlockingIndex = Int(arc4random_uniform(UInt32(blockingCells.count)))
                let randomBlockingMove = blockingCells[randomBlockingIndex] as! Int
                let randomBlockingCell = gameCells.object(forKey: String(randomBlockingMove)) as! GameCell
                insertCube(cell: randomBlockingCell)
            }
            
        }
        
        // IF THERE IS NO WINNING OR BLOCKING MOVES, RANDOM MOVE
        if winningCells.count == 0 && blockingCells.count == 0 {
            
            
            // CALCULATING AVAILABLE WINNING SEQUENCES
            
            // for each winning sequence
            let possibleKeys: NSMutableArray = []
            for winningCellSequence in winningSequences {
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
                    Log.debug(log: "possible winning sequence: \(thisSequence)")
                }
            }
            
            
            if possibleKeys.count != 0 {
                Log.debug(log: "possiblekeys: \(possibleKeys)")
                let randomPossibleIndex = Int(arc4random_uniform(UInt32(possibleKeys.count)))
                let randomPossibleMove = possibleKeys[randomPossibleIndex]  as! Int
                let randomPossibleCell = gameCells.object(forKey: String(randomPossibleMove)) as! GameCell
                insertCube(cell: randomPossibleCell)
            }
            else {
                let emptyCells: NSMutableArray = []
                for cell in gameCells {
                    let thisCell = cell.value as! GameCell
                    if thisCell.containsElement == nil {
                        emptyCells.add(thisCell.key)
                    }
                }
                
                if emptyCells.count > 0 {
                    Log.debug(log: "empty cells: \(emptyCells)")
                    
                    let randomIndex = Int(arc4random_uniform(UInt32(emptyCells.count)))
                    let randomMove = emptyCells[randomIndex]
                    let randomCell = gameCells.object(forKey: randomMove) as! GameCell
                    insertCube(cell: randomCell)
                }
            }
        }
    }
    
    
    //------------------------------//
    //---------SETTING GAME---------//
    //------------------------------//
    
    
    // Setting board game
    func prepareGame(onPlane: SCNNode, sceneWidth: CGFloat, sceneHeight: CGFloat, sceneLength: CGFloat?) {
        parentPlane = onPlane
        baseGameSize = sceneLength
       
        var length: CGFloat
        if let sceneLength = sceneLength {
            // game elements should not be bigger than smaller size of plane
            let sizeToTake = sceneWidth < sceneLength ? sceneWidth : sceneLength
            length = sizeToTake / 1.5
        } else {
            length = sceneHeight / 10
        }
        
        let cellSize = length / 3
        let onethird = Float(cellSize) / 2
        let width = cellSize / 10
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.yellow
        
        let bar = SCNBox(width: width, height: width, length: length, chamferRadius: 0)
        let nodeBar1 = SCNNode(geometry: bar)
        nodeBar1.geometry!.materials = [material]
        
        let bar2 = SCNBox(width: width, height: width, length: length, chamferRadius: 0)
        let nodeBar2 = SCNNode(geometry: bar2)
        nodeBar2.geometry!.materials = [material]
        
        let bar3 = SCNBox(width: length, height: width, length: width, chamferRadius: 0)
        let nodeBar3 = SCNNode(geometry: bar3)
        nodeBar3.geometry!.materials = [material]
        
        let bar4 = SCNBox(width: length, height: width, length: width, chamferRadius: 0)
        let nodeBar4 = SCNNode(geometry: bar4)
        nodeBar4.geometry!.materials = [material]
        
        if let parentPlane = parentPlane as? Plane {
            let zPosition = parentPlane.boundingBox.max.y + (Float(width) / 2)
            
            nodeBar1.position = SCNVector3Make(-onethird, zPosition, 0)
            nodeBar2.position = SCNVector3Make(onethird, zPosition, 0)
            nodeBar3.position = SCNVector3Make(0, zPosition, -onethird)
            nodeBar4.position = SCNVector3Make(0, zPosition, onethird)
        } else {
            nodeBar1.position = SCNVector3Make(-onethird, 0, 0)
            nodeBar2.position = SCNVector3Make(onethird, 0, 0)
            nodeBar3.position = SCNVector3Make(0, 0, -onethird)
            nodeBar4.position = SCNVector3Make(0, 0, onethird)
        }
        
        onPlane.addChildNode(nodeBar1)
        onPlane.addChildNode(nodeBar2)
        onPlane.addChildNode(nodeBar3)
        onPlane.addChildNode(nodeBar4)
        
        setGameCells(cellSize: cellSize)
    }
    
    
    // Calculating and setting cell "detectors"
    func setGameCells(cellSize: CGFloat) {
        // TOP LEFT
        addPlaneDetector(key: "1", cellSize: cellSize, centerX: cellSize, centerY: cellSize)
        
        // TOP MIDDLE
        addPlaneDetector(key: "2", cellSize: cellSize, centerX: cellSize, centerY: 0)
        
        // TOP RIGHT
        addPlaneDetector(key: "3", cellSize: cellSize, centerX: cellSize, centerY: -cellSize)
        
        // MIDDLE LEFT
        addPlaneDetector(key: "4", cellSize: cellSize, centerX: 0, centerY: cellSize)
        
        // MIDDLE
        addPlaneDetector(key: "5", cellSize: cellSize, centerX: 0, centerY: 0)
        
        // MIDDLE RIGHT
        addPlaneDetector(key: "6", cellSize: cellSize, centerX: 0, centerY: -cellSize)
        
        // BOTTOM LEFT
        addPlaneDetector(key: "7", cellSize: cellSize, centerX: -cellSize, centerY: cellSize)
        
        // BOTTOM MIDDLE
        addPlaneDetector(key: "8", cellSize: cellSize, centerX: -cellSize, centerY: 0)
        
        // BOTTOM RIGHT
        addPlaneDetector(key: "9", cellSize: cellSize, centerX: -cellSize, centerY: -cellSize)
        
        Log.info(log: "Game is set and ready to play")
        setNextPlayer(nextPlayer: "cross")
    }
    
    // Adding detectors in cells
    func addPlaneDetector(key: String, cellSize: CGFloat, centerX: CGFloat, centerY: CGFloat) {
        guard let parentPlane = parentPlane else {
            Log.error(log: "No parent plane defined")
            return
        }
        
        let formattedCellSize = cellSize / 1.5
        
        // Creating a detector plane in a node
        let detectorBox = SCNBox(width: formattedCellSize, height: formattedCellSize / 3, length: formattedCellSize, chamferRadius: 0)
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

        parentPlane.addChildNode(detector)
        
        // Saving cell for later use
        gameCells.setValue(GameCell(key: key, detector: detector), forKey: key) // Adding gamecell to local array
    }
    
    
    
    
    func insertCube(cell: GameCell) {
        guard let parentPlane = parentPlane else {
            Log.error(log: "No parent plane defined")
            return
        }
        
        let cellWidth = cell.detector.boundingBox.max.x - cell.detector.boundingBox.min.x
        let cellHeight = cell.detector.boundingBox.max.y - cell.detector.boundingBox.min.y
        
        let size = CGFloat(cellWidth)
        let cube = SCNBox(width: size, height: CGFloat(cellHeight), length: size, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white.withAlphaComponent(0)
        cube.materials = [material]
        
        let cubeNode = SCNNode(geometry: cube)
        
        let yDropPosition: Float = 0.1
        cubeNode.position = SCNVector3Make(cell.detector.position.x,
                                           cell.detector.position.y + yDropPosition,
                                           cell.detector.position.z)
        
        
        let shape = SCNPhysicsShape(geometry: cube, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody.mass = 1.0
        physicsBody.restitution = 0.35
        physicsBody.friction = 1.0
        physicsBody.categoryBitMask = CollisionTypes.shape.rawValue
        
        cubeNode.physicsBody = physicsBody
        
        let player = playing // circle playing on pair numbers
        if let playerElement = getPlayerObject(player: player, container: cubeNode) {
            
            cubeNode.addChildNode(playerElement)
            cell.setContains(node: cubeNode, type: player)
            
            if player == "cross" {
                crossCells.add(cell.key)
            } else {
                circleCells.add(cell.key)
            }
            
            updateGameStatus()
            
            parentPlane.addChildNode(cubeNode)
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
        let nbPlays = circleCells.count + crossCells.count
        
        var gameIsOver: Bool = false
        if (nbPlays >= 5) { // After 5 pieces have been placed, there could be a winner
            checkGameResult()
            if (nbPlays == 9 && winner == nil) { // If 9 pieces have been placed and still no winner : it's a tie!
                gameIsOver = true
            }
        }
        
        if (gameIsOver || winner != nil) {
            endGame()
        } else {
            setNextPlayer(nextPlayer: nil)
        }
    }
    
    // Calculating game result
    func checkGameResult() {
        
        // Loop on winning sequences
        for winningCellSequence in winningSequences {
            
            // Checking circle cells
            if (circleCells.count >= 3) {
                var winning = 0
                for selectedKey in circleCells {
                    let key = Int(selectedKey as! String)!
                    if winningCellSequence.contains(key) {
                        winning = winning + 1
                    }
                    
                    if winning == 3 {
                        winner = "O"
                        break
                    }
                }
            }
            
            // If circle didnt win, checking cross cells
            if (winner == nil && crossCells.count >= 3) {
                var winning = 0
                for selectedKey in crossCells {
                    let key = Int(selectedKey as! String)!
                    if winningCellSequence.contains(key) {
                        winning = winning + 1
                    }
                    
                    if winning == 3 {
                        winner = "X"
                        break
                    }
                }
            }
        }
    }
    
    
    // Set End of game : show status & add 3D Text
    func endGame() {
        
        // Create text "-- WINS"
        var text = "It's a tie!"
        if (winner != nil) {
            text = winner!+" wins!"
        }
        
        Log.info(log: "Game is over : \(text)")
        
        // Drop 3D text on game set
        draw3DText(text: text)
    }
    
    
    
    
    // Draw winning 3D Text
    func draw3DText(text: String) {
        guard let parentPlane = parentPlane else {
            Log.error(log: "No parent plane defined")
            return
        }
        
        let maxLength = baseGameSize! / 3.5
        
        // Creating a custom SCNText, extrusionDepth defines the text depth
        let textGeometry = SCNText(string: text, extrusionDepth: CGFloat(maxLength / 5))
        textGeometry.font = UIFont(name: "Helvetica Neue", size: 2)
        let textNode = SCNNode(geometry: textGeometry)
        
        // Calculating text scale
        let textLength = textNode.boundingBox.max.x - textNode.boundingBox.min.x
        let textHeight = textNode.boundingBox.max.y - textNode.boundingBox.min.y
        
        let textScale = Float(baseGameSize!) / textLength
        textNode.scale = SCNVector3Make(textScale, textScale, 1)
        
        let scaledTextLength = textLength * textScale
        let scaledTextHeight = textHeight * textScale
        
        textNode.position.x = -(scaledTextLength / 2)
        
        
        if let _ = parentPlane as? Plane {
            let plane = SCNPlane(width: CGFloat(scaledTextLength), height: CGFloat(scaledTextHeight))
            let blueMaterial = SCNMaterial()
            blueMaterial.diffuse.contents = UIColor.white.withAlphaComponent(0)
            plane.firstMaterial = blueMaterial
            let textParentNode = SCNNode(geometry: plane) // this node will hold our text node

            if let cameraEulerAngles = delegate!.getCurrentCameraPosition(manager: self) {
                textParentNode.eulerAngles = SCNVector3(0, cameraEulerAngles.y, 0)
            }
            
            textNode.position.y = -(scaledTextHeight / 2)
            textParentNode.addChildNode(textNode)
            
            textParentNode.position.y = scaledTextHeight
            parentPlane.addChildNode(textParentNode)
        }
      
        else {
            
            textNode.position.y = scaledTextHeight / 2
            parentPlane.addChildNode(textNode)
        }
        
        winTextNode = textNode
        let materialText = SCNMaterial()
        materialText.diffuse.contents = generateRandomColor()
        winTextNode!.geometry!.materials = [materialText]
        
        // Just for fun, changing text color every 0.2 seconds
        winningTextTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
            let material = SCNMaterial()
            material.diffuse.contents = self.generateRandomColor()
            if let winTextNode = self.winTextNode {
                if let winTextGeometry = winTextNode.geometry {
                    winTextGeometry.materials = [material]
                }
            }

            self.explodePiece() // Explosion in random cell
        }
    }
    
    var cellExploded = 0
    func explodePiece() {
        if let particleSystem = SCNParticleSystem(named: "Explosion", inDirectory: "art.scnassets/Explosion") {
            let systemNode = SCNNode()
            systemNode.addParticleSystem(particleSystem)
    
            cellExploded = cellExploded + 1
            if cellExploded == 10 {
                cellExploded = 1
            }
            
            if let cell = gameCells.value(forKey: String(cellExploded)) as? GameCell {
                cell.detector.addChildNode(systemNode)
                cell.emptyCell()
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
    
    
    
}
