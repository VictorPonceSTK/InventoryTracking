//
//  InventoryFormVM.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import Foundation
import SwiftUI
import QuickLookThumbnailing
import FirebaseFirestore
import FirebaseStorage

class InventoryFormViewModel: ObservableObject{
    let db = Firestore.firestore()
    let formType: FormType
    
    let id: String
    @Published var name = ""
    @Published var quantity = 0
    @Published var usdzURL: URL?
    @Published var thumbnailURL: URL?
    
    @Published var loadingState = LoadingType.none
    @Published var error: String?
    
    @Published var uploadProgress: UploadProgress?
    @Published var showUSDZSource:Bool = false
    @Published var selectedUSDZSource: USDZSourceType?
    //lazy
    let byteConutFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()
    
    
    var navigationTitle: String{
        switch formType {
        case .add:
            return "Add item"
        case .edit:
            return "Edit Item"
        }
    }
    
    init(formType: FormType = .add){
        self.formType = formType
        switch formType {
        case .add:
            id = UUID().uuidString
        case .edit(let item):
            id = item.id
            name = item.name
            quantity = item.quantity
            if let usdzURL = item.udszURL{
                self.usdzURL = usdzURL
            }
            if let thumnailURL = item.thumnailURL{
                self.thumbnailURL = thumnailURL
            }
        }
    }
    
    func save() throws {
        loadingState = .savingItem
        
        defer {loadingState = .none}
        
        var item: InventoryItem
        switch formType{
        case .add:
            item = .init(id:id, name: name,quantity: quantity)
            
        case .edit(let inventoryItem):
            item = inventoryItem
            item.name = name
            item.quantity = quantity
        }
        item.usdzLink = usdzURL?.absoluteString
        item.thumnailLink = thumbnailURL?.absoluteString
        
        do {
            try db.document("items/\(item.id)")
                .setData(from: item, merge:false)
        }catch{
            self.error  = error.localizedDescription
            throw error
        }
    }
    
    @MainActor
    func deleteUSDZ() async{
        let storageRef = Storage.storage().reference()
        let usddzRef = storageRef.child("\(id).usdz")
        let thubnailRef = storageRef.child("\(id).jpg")
        loadingState = .deleting(.usdzWithThumbnail)
        defer { loadingState = .none}
        
        do {
            try await usddzRef.delete()
            try? await thubnailRef.delete()
            self.usdzURL = nil
            self.thumbnailURL = nil
        } catch{
            self.error = error.localizedDescription
        }
    }
    @MainActor
    func deleteItem() async throws{
        loadingState = .deleting(.item)
        do{
            try await db.document("items/\(id)").delete()
            try? await Storage.storage().reference().child("\(id).usdz").delete()
            try? await Storage.storage().reference().child("\(id).jpg").delete()
        }catch{
            loadingState = .none
            throw error
        }
    }
    
    @MainActor
    func uploadUSDZ(fileURL: URL) async{
        let gotAcess = fileURL.startAccessingSecurityScopedResource() //TODO: Search more about this
        guard gotAcess, let data = try? Data(contentsOf: fileURL) else {return}
        fileURL.stopAccessingSecurityScopedResource()
        uploadProgress = .init(UploadProgress(fractionCompleted: 0, totalUnitCount: 0, completedUnitCount: 0))
        loadingState = .uploading(.usdz)
        
        defer{ loadingState = .none}
        do {
            // Upload USDZ to Firebase Storage
            let storageRef = Storage.storage().reference()
            let usdzRef = storageRef.child("\(id).usdz")
            _ = try await usdzRef.putDataAsync(data,metadata: .init(dictionary: ["contentType":"model/vnd.usd+zip"])){
                [weak self] progress in
                guard let self, let progress else {return}
                self.uploadProgress = .init(fractionCompleted: progress.fractionCompleted, totalUnitCount: progress.totalUnitCount, completedUnitCount: progress.completedUnitCount)
                
            }
            let downloadURL = try await usdzRef.downloadURL()
            
            // Generate Thumbnail
            let cacheDirURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let fileCacheURL = cacheDirURL.appending(path: "temp_\(id).usdz")
            try? data.write(to: fileCacheURL)
            
            let thumbnailRequest = QLThumbnailGenerator.Request(fileAt: fileCacheURL, size: .init(width: 300,height:300), scale: UIScreen.main.scale, representationTypes: .all)
            
            if let thumbnail = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: thumbnailRequest),
               let jpgData = thumbnail.uiImage.jpegData(compressionQuality: 0.5){
                loadingState = .uploading(.thumnail)
                let thumbnailRef = storageRef.child("\(id).jpg")
                _ = try? await thumbnailRef.putDataAsync(jpgData, metadata: .init(dictionary: ["contentType":"image/jpeg"]), onProgress: {[weak self] progress in
                    guard let self, let progress else {return }
                    self.uploadProgress = .init(fractionCompleted:progress.fractionCompleted, totalUnitCount: progress.totalUnitCount, completedUnitCount: progress.completedUnitCount)
                })
                if let thumbnailURL = try? await thumbnailRef.downloadURL(){
                    self.thumbnailURL = thumbnailURL
                }
            }
            self.usdzURL = downloadURL
        }catch{
            self.error = error.localizedDescription
        }
    }
    
}


enum FormType: Identifiable {
    case add
    case edit(InventoryItem)
    
    var id:String{
        switch self{
        case . add:
            return "add"
        case .edit(let invenotryItem):
            return "edit-\(invenotryItem.id)"
        }
    }
}


enum LoadingType: Equatable{
    case none
    case savingItem
    case uploading(UploadType)
    case deleting(DeleteType)
}

enum USDZSourceType {
    case fileImporter, objectCapture
}

enum UploadType: Equatable{
    case usdz,thumnail
}

enum DeleteType {
    case usdzWithThumbnail, item
}


struct UploadProgress{
    var fractionCompleted: Double
    var totalUnitCount: Int64
    var completedUnitCount: Int64
}


