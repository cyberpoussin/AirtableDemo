//
//  ASUserView.swift
//  PromoAvril
//
//  Created by Admin on 04/05/2021.
//

import SwiftUI

struct ASUserView: View {
    @AppStorage("my_user") var user = ASUser(name: "jean", firstName: "Paul", age: 34, places: [.init(latitude: 24, longitude: 23.4)])
    
    var body: some View {
        VStack {
            Text(user.name)
            Text(user.firstName)
            Text(user.age.description)

            List(user.places) {place in
                Text(place.latitude.description)
            }
            Button("Add favorite place") {
                user.places.append(.init(latitude: 23.1, longitude: 45.2))
                user.firstName = "booouh"
            }

        }
    }
}

struct ASUserView_Previews: PreviewProvider {
    static var previews: some View {
        ASUserView()
    }
}
