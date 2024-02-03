//
//  InvenotryListVM.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import Foundation
import SwiftUI
import FirebaseFirestore


class InvenotryListViewModel:ObservableObject {
    @Published var items = [InventoryItem]()
    
    @MainActor
    func listToTitems(){
        Firestore.firestore().collection("items")
            .order(by: "name")
            .limit(toLast: 100)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot else {
                    print("Error fetching snapshot: \(error?.localizedDescription ?? "error")")
                    return
                }
                let docs = snapshot.documents
                let items = docs.compactMap {
                    try? $0.data(as: InventoryItem.self)
                }
                withAnimation{
                    self.items = items
                }                            
            }
    }
    
}

