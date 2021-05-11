//
//  ASUserMainView.swift
//  PromoAvril
//
//  Created by Admin on 04/05/2021.
//

import SwiftUI

struct ASUserMainView: View {
    @State private var showModal = false
    @AppStorage("my_user") var user = ASUser(name: "jean", firstName: "Paul", age: 34, places: [.init(latitude: 24, longitude: 23.4)])
    var body: some View {
        
        VStack {
            Text("Bonjour, \(user.name)")
            Button("open") {
                showModal = true
            }
                .sheet(isPresented: $showModal) {
                    VStack {
                        ASUserView()
                        Button("close"){
                            showModal = false
                        }
                    }
            }

        }
    }
}

struct ASUserMainView_Previews: PreviewProvider {
    static var previews: some View {
        ASUserMainView()
    }
}
