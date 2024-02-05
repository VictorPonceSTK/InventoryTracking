//
//  InventoryItemView.swift
//  InventoryTrackerVision
//
//  Created by Victor David Ponce Quintanilla on 02/02/24.
//

import SwiftUI
import RealityKit

struct InventoryItemView: View {
    @EnvironmentObject var navVM: NavigationViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject var vm = InventoryItemViewModel()
    
    //3D Rotation
    @State var angle: Angle = .degrees(0)
    @State var startAngle: Angle?
    
    @State var axis: (CGFloat,CGFloat,CGFloat) = (.zero,.zero,.zero)
    @State var startAxis: (CGFloat,CGFloat,CGFloat)?
    
    //Scale
    @State var scale: Double = 2
    @State var startScale: Double?
    
    var body: some View {
        ZStack(alignment: .bottom){
            RealityView{ _ in }
        update: { content in
            if vm.entity == nil && !content.entities.isEmpty {
                content.entities.removeAll()
            }
            if let entity = vm.entity{
                if let currentEntity = content.entities.first, entity == currentEntity{
                    return
                }
                content.entities.removeAll()
                content.add(entity)
            }
        }
        .rotation3DEffect(angle,axis: axis)
        .scaleEffect(scale)
        .simultaneousGesture(DragGesture().onChanged{ value in
            if let startAngle, let startAxis{
                let _angle = sqrt(pow(value.translation.width, 2) + pow(value.translation.height,2)) + startAngle.degrees
                let axisX = ((-value.translation.height + startAxis.0) / CGFloat(_angle))
                let axisY = ((value.translation.width + startAxis.1) / CGFloat(_angle))
                angle = Angle(degrees: Double(_angle))
                axis = (axisX,axisY,0)
                
            }else{
                startAngle = angle
                startAxis = axis
            }
        } .onEnded{value in
            startAngle = angle
            startAxis = axis
        })
        .simultaneousGesture(MagnifyGesture()
            .onChanged{ value in
                if let startScale {
                    scale = max(1, min(3,value.magnification * startScale))
                } else {
                    startScale = scale
                }
            }
            .onEnded{ _ in
                startScale = scale
            }
        )
        
            zIndex(1)
            
            
            VStack{
                Text(vm.item?.name ?? "")
                Text("Quantity \(vm.item?.quantity ?? 0) ")
            }
            .padding(32)
            .background(.ultraThinMaterial).cornerRadius(16)
            .font(.extraLargeTitle)
            .zIndex(1)
        }
        .onAppear{
            guard let item = navVM.selectedItem else{return}
            print("selected item: \(item.name)")
            vm.onItemDeleted = {dismiss()}
            vm.listenToItem(item)
        }
    }
}

#Preview {
    @StateObject var navVM = NavigationViewModel(selectedItem: .init(id:"2E9D5B5E-F28F-415A-ABBB-51E7097F6005",name:"Nike AirForce 1",quantity: 1))
    
    return InventoryItemView()
        .environmentObject(navVM)
}
