//
//  SwiftUIView2.swift
//  AirtableDemo
//
//  Created by Admin on 29/06/2021.
//

import SwiftUI


class ParentViewModel: ObservableObject {
    
    @Published var color: Color = .red

}

class ChildViewModel: ObservableObject {
    
    @Published var color: Color
    
    init(color: Color) {
        self.color = color
    }

}

struct SuperView: View {
    @StateObject var tVM: ParentViewModel = ParentViewModel()
    var body: some View {
        ScrollView {
            Button("refresh") {
                tVM.color = .black
            }
            SwiftUIView2(tVM: ChildViewModel(color: tVM.color))
        }
    }
}
struct SwiftUIView2: View {
    @ObservedObject var tVM: ChildViewModel
    var body: some View {
        ScrollView {
            Button("refresh") {
                tVM.color = .black
            }
            listChilds
        }
    }
    
    @ViewBuilder var listChilds: some View {
        ForEach((1...4), id: \.self) {_ in
            let newVM = ChildViewModel(color: tVM.color)
            CellView(tVM: newVM, buttonAction: {
                tVM.color = .orange
            })
        }
    }
}


struct SwiftUIView2_Previews: PreviewProvider {
    static var previews: some View {
        SuperView()
    }
}

struct CellView: View {
    @ObservedObject var tVM: ChildViewModel
    
    var buttonAction: () -> ()
    var body: some View {
        VStack {
            Text("haha")
                .foregroundColor(tVM.color)
            Button("lol") {
                buttonAction()
            }
        }
    }
}
