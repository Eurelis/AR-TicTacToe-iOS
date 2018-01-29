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
    
    let ARCompatible = ARConfiguration.isSupported
    var isHost = false
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        if !ARCompatible {
            Log.info(log: "Device is not ARKit compatible")
            let alert = UIAlertController(title: "ARKit unavailable", message: "Your device is not compatible with ARKit, the game will only be static 3D", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion:nil)
        }
    }
    
    @IBAction func showConnectionPrompt(_ sender: Any) {
        Log.info(log: "showConnectionPrompt")
        
        showAlert()
        
//        let actionSheet = UIAlertController(title: "Connect to others", message: nil, preferredStyle: .actionSheet)
//
//        if ARCompatible {
//             actionSheet.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
//        }
//
//        actionSheet.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
//        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//
//        if let popoverController = actionSheet.popoverPresentationController {
//            popoverController.sourceView = view
//            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
//            popoverController.permittedArrowDirections = []
//        }
//
//        present(actionSheet, animated: true, completion:nil)
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Coming Soon!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion:nil)
    }
    
    
    func startHosting(action: UIAlertAction) {
        if ARCompatible {
            Log.info(log: "startHosting")
            isHost = true
            performSegue(withIdentifier: "twodevicessegue", sender: self)
        }
    }
    
    func joinSession(action: UIAlertAction) {
        Log.info(log: "joinSession")
        isHost = false
        performSegue(withIdentifier: "twodevicessegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let twoDevicesVC = segue.destination as? TwoDevicesViewController {
            twoDevicesVC.isHost = isHost
        }
    }
    
}
