//
//  NavigationVM.swift
//  InventoryTrackerVision
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import Foundation
import SwiftUI

class NavigationViewModel: ObservableObject{    
    @Published var selectedItem: InventoryItem?
    
    init(selectedItem: InventoryItem? = nil) {
        self.selectedItem = selectedItem
    }
}
