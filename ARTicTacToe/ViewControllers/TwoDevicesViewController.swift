//
//  TwoDevicesViewController.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 11/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class TwoDevicesViewController: UIViewController, MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    
    var isHost = false
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!

    var isConnected: Bool = false
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var ConnectedDeviceNameLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        let status = isHost ? "Waiting for connection" : "Waiting for host"
        self.updateStatus(status: status, deviceName: nil)
        
        
        
        /*
         5. When device selected : popup "Please put both devices next to each other" and tap Ready
         
         6. When both devices "ready" : on device 1 "please scan your surrounding to find a plane" / "tap to select and set game"
         7. When game is set :
                - device 1 : "waiting for device 2" ---> READY
                - device 2 : "receiving data" / "game is set" ---> READY
 
         8. When both ready, start game, send data to other device when player played
 
        */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.isConnected {
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
        } else {
            Log.info(log: "Device is connected and waiting for game set ")
            //TODO GAME SET
        }
    }
    
    @IBAction func backToHome(_ sender: Any) {
        Log.info(log: "Session disconnected")
        mcSession.disconnect()
        self.isConnected = false
        self.updateStatus(status: "Disconnected", deviceName: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    private func updateStatus(status:String, deviceName: String?) {
        DispatchQueue.main.async {
            self.connectionStatusLabel.text = status
            self.ConnectedDeviceNameLabel.text = deviceName
        }
    }
    
    
     // -- MARK MCBrowserViewControllerDelegate
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    
    
    // -- MARK MCSessionDelegate
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            self.isConnected = true
            Log.info(log: "Connected: \(peerID.displayName)")
            if !isHost {
                dismiss(animated: true) // Dismissing scan browser
            }
            self.updateStatus(status: "Connected to", deviceName: peerID.displayName)
        case MCSessionState.connecting:
            self.isConnected = false
            Log.info(log: "Connecting: \(peerID.displayName)")
            self.updateStatus(status: "Connecting to", deviceName: peerID.displayName)
        case MCSessionState.notConnected:
            self.isConnected = false
            Log.info(log: "Not Connected: \(peerID.displayName)")
            self.updateStatus(status: "Disconnected", deviceName: nil)
        }
    }
    
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }


    
    // -- MARK MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Log.error(log: "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        Log.info(log: "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.mcSession)
    }
    
}



