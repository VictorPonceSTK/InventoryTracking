//
//  String+Extension.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import Foundation

extension String: Error, LocalizedError{
    public var errorDescription: String? {self}
}
