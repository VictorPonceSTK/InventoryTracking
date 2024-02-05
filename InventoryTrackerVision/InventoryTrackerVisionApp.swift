//
//  InventoryTrackerVisionApp.swift
//  InventoryTrackerVision
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import SwiftUI

@main
struct InventoryTrackerVisionApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var navVM = NavigationViewModel()
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                InventoryListView()
                    .environmentObject(navVM)
            }
        }
        WindowGroup(id:"item"){
            InventoryItemView().environmentObject(navVM)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1,depth: 1, in:.meters)
    }
}
