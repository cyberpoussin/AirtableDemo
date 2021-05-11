//
//  CartView.swift
//  PromoAvril
//
//  Created by Admin on 22/04/2021.
//

import SwiftUI

struct GeometryAndInfinity: View {
    
    var body: some View {
        VStack(spacing: 0) {
            
            
            HStack {
                Image("Bill")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 50)
                    .clipped()
                Image("Larry")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: 50)

                    .clipped()
            }
            
            GeometryReader { proxy in
            Image("Bill")
                .resizable(resizingMode: .stretch)
                
                .aspectRatio(contentMode: .fill)
                .frame(width: proxy.size.width, height: proxy.size.width)
                .clipped()
                .cornerRadius(1000)
                
            }
            .padding(20)
                //.layoutPriority(-1)
                
            
            
            Text("")
                .fontWeight(.bold)
            
            Rectangle()
                
                .padding(10)
                .background(Color.purple.cornerRadius(20))

        }
    }
}

struct GeometryAndInfinity_Previews: PreviewProvider {
    static var previews: some View {
        GeometryAndInfinity()
    }
}
