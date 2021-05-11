//
//  PromoAvrilApp.swift
//  PromoAvril
//
//  Created by Admin on 19/04/2021.
//

import SwiftUI

@main
struct PromoAvrilApp: App {
    var body: some Scene {
        WindowGroup {
            DateFormatted()
                .environment(\.locale, .init(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier))
        }
    }
}
