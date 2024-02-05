//
//  URL+Extension.swift
//  InventoryTrackerVision
//
//  Created by Victor David Ponce Quintanilla on 03/02/24.
//

import Foundation

extension URL {
    
    var usdzFileCacheURL: URL? {
        guard
            let urlComps = URLComponents(url:self,resolvingAgainstBaseURL: false),
            let cacheDirURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else{
            return nil
        }
        
        let token = urlComps.queryItems?.first(where:{ $0.name == "token"})?.value ?? UUID().uuidString
        let fileCacheURL = cacheDirURL.appending(
            path: "\(token)_\(lastPathComponent)")
        return fileCacheURL
    }
}
