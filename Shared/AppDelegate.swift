//
//  AppDelegate.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // UNcomment this line if you want to use Local Emulator suite
        setUpFirebaseLocalEmulator()
        return true
    }
    
    func setUpFirebaseLocalEmulator(){
        var host = "127.0.0.1"
        #if !targetEnvironment(simulator)
        host = "192.168.1.6"
        #endif
        
        let settings = Firestore.firestore().settings
        settings.host = "\(host):8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        Storage.storage().useEmulator(withHost: host, port: 9199)
    }
    
    
}
