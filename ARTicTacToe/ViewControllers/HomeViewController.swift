//
//  HomeViewController.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 11/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit
import ARKit
import MultipeerConnectivity

class HomeViewController: UIViewController {
    
    @IBOutlet weak var oneDeviceText2: UILabel!
    @IBOutlet weak var oneDeviceText: UILabel!
    @IBOutlet weak var oneDeviceButton: UIButton!
    
    var ARCompatible = true
    var isHost = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        if !ARConfiguration.isSupported {
            Log.info(log: "Device is not ARKit compatible")
            self.ARCompatible = false
            
            self.oneDeviceButton.isEnabled = false
            self.oneDeviceButton.alpha = 0.5
            self.oneDeviceText.alpha = 0.5
            self.oneDeviceText2.alpha = 0.5
            
            let alert = UIAlertController(title: "ARKit unavailable", message: "Your device is not compatible with ARKit, you will not be able to play single player", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion:nil)
        }
    }
    
    @IBAction func showConnectionPrompt(_ sender: Any) {
        Log.info(log: "showConnectionPrompt")
        
        let actionSheet = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
        
        if self.ARCompatible {
             actionSheet.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        }
       
        actionSheet.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
                
        present(actionSheet, animated: true, completion:nil)
    }
    
    
    func startHosting(action: UIAlertAction) {
        if self.ARCompatible {
            Log.info(log: "startHosting")
            self.isHost = true
            performSegue(withIdentifier: "twodevicessegue", sender: self)
        }
    }
    
    func joinSession(action: UIAlertAction) {
        Log.info(log: "joinSession")
        self.isHost = false
        performSegue(withIdentifier: "twodevicessegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let twoDevicesVC = segue.destination as? TwoDevicesViewController {
            twoDevicesVC.isHost = self.isHost
        }
    }
    
}
