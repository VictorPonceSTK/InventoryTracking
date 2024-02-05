//
//  InventoryFormView.swift
//  InventoryTracker
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import SwiftUI
import UniformTypeIdentifiers
import SafariServices

struct InventoryFormView: View {
    @StateObject var vm = InventoryFormViewModel()
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Form{
            List{
                inputSection
                arSection
                if case .deleting(let type) = vm.loadingState{
                    HStack{
                        Spacer()
                        VStack(spacing:8){
                            ProgressView()
                            Text("Deleting \(type == .usdzWithThumbnail ? "USDZ file" : "Item")")
                        }
                        Spacer()
                    }
                }
                if case .edit = vm.formType{
                    Button("Delete", role: .destructive){
                        Task {
                            do{
                                try await vm.deleteItem()
                                dismiss()
                            }catch{
                                vm.error = error.localizedDescription
                            }
                        }
                    }
                }
            }
        }
        .toolbar{
            ToolbarItem(placement: .cancellationAction){
                Button("Cancel"){
                    dismiss()
                }
                .disabled(vm.loadingState != .none)
            }
            
            ToolbarItem(placement: .confirmationAction){
                Button("Save"){
                    do{
                        try vm.save()
                        dismiss()
                    }catch{}
                }
                .disabled(vm.loadingState != .none ||
                          vm.name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            }
        }
        .confirmationDialog("Add USDZ", isPresented: $vm.showUSDZSource,titleVisibility: .visible,  actions:{
            Button("Select file"){
                vm.selectedUSDZSource = .fileImporter
            }
            Button("Object Capture"){
                vm.selectedUSDZSource = .objectCapture
            }
        })
        .fileImporter(isPresented: .init(get: {vm.selectedUSDZSource == .fileImporter}, set: {_ in vm.selectedUSDZSource = nil} ), allowedContentTypes: [UTType.usdz], onCompletion: { result in
            switch result {
            case .success(let url):
                Task { await vm.uploadUSDZ(fileURL: url)} //TODO: research this!!
            case .failure(let failure):
                vm.error = failure.localizedDescription
            }
            
        })
        //        Error = title
        //        messsage = subtitle
        .alert(isPresented:.init(get: {vm.error != nil},
                                 set:{ _ in vm.error = nil}),
               error: "An error has occurred",
               actions: {_ in },
               message: {_ in Text(vm.error ?? "")})
        .navigationTitle(vm.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
    
    var inputSection: some View {
        Section{
            TextField("Name", text:$vm.name)
            Stepper("Quantity: \(vm.quantity)", value:$vm.quantity)
                .disabled(vm.loadingState != .none)
        }
    }
    var arSection: some View{
        Section("AR Model"){
            if let thumbnailURL = vm.thumbnailURL{
                AsyncImage(url: thumbnailURL){phase in
                    switch phase{
                    case .success(let image):
                        image.resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity,maxHeight: 300)
                            .onTapGesture {
                                guard let usdzURL = vm.usdzURL else { return }
                                viewAR(url: usdzURL)
                            }
                    case .failure:
                        Text("Failed to fetch thumbnail")
                    default: ProgressView()
                    }
                }
            }
            
            if let usdzURL = vm.usdzURL{
                Button{
                    viewAR(url: usdzURL)
                } label: {
                    HStack {
                        Image(systemName: "arkit").imageScale(.large)
                        Text("View")
                    }
                }
                Button("Delete USDZ",role: .destructive){
                    Task { await vm.deleteUSDZ() }
                }
            }else{
                Button{
                    vm.showUSDZSource = true
                }label: {
                    HStack {
                        Image(systemName: "arkit").imageScale(.large)
                        Text("Add USDZ")
                    }
                }
            }
            if let progress = vm.uploadProgress,
               case let .uploading(type) = vm.loadingState, progress.totalUnitCount > 0 {
                VStack{
                    ProgressView(value:progress.fractionCompleted){
                        Text("Uploading \(type == .usdz ? "USDZ" : "Thubmnail") file \(Int(progress.fractionCompleted * 100))%")
                    }
                    Text("\(vm.byteConutFormatter.string(fromByteCount: progress.completedUnitCount)) / \(vm.byteConutFormatter.string(fromByteCount: progress.totalUnitCount))")
                }
            }
        }
        .disabled(vm.loadingState != .none)
    }
    
    func viewAR(url:URL){
        let safariVC = SFSafariViewController(url: url)
        let vd = UIApplication.shared.firstKeyWindow?.rootViewController?.presentedViewController ?? UIApplication.shared.firstKeyWindow?.rootViewController
        vd?.present(safariVC, animated: true)
    }
}





extension UIApplication{
    var firstKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap{$0 as? UIWindowScene}
            .filter {$0.activationState == .foregroundActive}
            .first?.keyWindow
    }
}


#Preview {
    NavigationStack{
        InventoryFormView()
    }
    
}
