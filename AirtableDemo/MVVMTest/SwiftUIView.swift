//
//  SwiftUIView.swift
//  SwiftUIView
//
//  Created by Admin on 02/09/2021.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        ScrollView {
            VStack {
                Spacer()
                    .frame(height: 1000)
                Text("Hello, World! Hello, World! Hello, World! Hello, World! ")
                //.fixedSize(horizontal: false, vertical: true)
                // ou
                // .frame(height: 100)
                Spacer()
                    .frame(height: 1000)
            }
            .background(Rectangle().fill(.red).frame(height: 200))
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
