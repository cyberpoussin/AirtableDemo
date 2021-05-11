//
//  CustomerForm.swift
//  PromoAvril
//
//  Created by Admin on 22/04/2021.
//

import SwiftUI
import Combine

struct CustomerForm: View {
    @State private var login: String = ""
    @State private var password: String = ""
    @State private var tel: String = ""

    @State private var showCart = false
    
    var telIsValid: Bool {
        if tel.count != 10 {
            return false
        }

        let telInteger: Int? = Int(tel)

        if telInteger == nil {
            return false
        }

        return true
        
//        if tel.count != tel.filter({"0123456789".contains($0)}).count {
//            return false
//        }
//        if tel.first! == "0" {
//            return true
//        }
//        return false
    }
    
    
    var canEnter: Bool {
        login.count > 7
            && password.count > 7
            && password.contains("@")
            && telIsValid
        
    }

    var body: some View {
        VStack {

            TextField("login", text: $login)
            .disableAutocorrection(true)
            .padding(10)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.red.opacity(0.5), lineWidth: 2)
            )
            .onReceive(Just(self.login)) { inputValue in
                    // With a little help from https://bit.ly/2W1Ljzp
                    if inputValue.count > 15 {
                        self.login.removeLast()
                    }
                }
            TextField("mot de passe", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
            TextField("téléphone", text: $tel)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .keyboardType(.numberPad)
            Button("Entrer") {
                withAnimation {
                    showCart = true
                }
            }
            .padding()
            .background(canEnter ? Color.green : Color.gray)
            .cornerRadius(20)
            .foregroundColor(.white)
            .disabled(!canEnter)
            
            Text(canEnter ? "Entrez s'il vous plait!" : "")
        }
        .padding()
    }
}

struct CustomerForm_Previews: PreviewProvider {
    static var previews: some View {
        CustomerForm()
    }
}
