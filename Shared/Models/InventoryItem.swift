//
//  InventoryItem.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//


import Foundation
import SwiftData
import FirebaseFirestoreSwift

struct InventoryItem: Identifiable, Codable, Equatable {
    var id = UUID().uuidString
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
    
    var name: String
    var quantity: Int
    
    var usdzLink: String?
    var udszURL: URL? {
        guard let usdzLink else { return nil }
        return URL(string: usdzLink)
    }
    
    var thumnailLink: String?
    var thumnailURL: URL?{
        guard let thumnailLink else { return nil }
        return URL(string:thumnailLink)
    }
}
