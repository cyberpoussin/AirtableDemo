//
//  BurgerView.swift
//  PromoAvril
//
//  Created by Admin on 29/04/2021.
//

import SwiftUI
import Combine

struct BurgerView: View {
    @State private var cancellable: AnyCancellable? = nil
    var body: some View {
        VStack {
            Link("Open adress in Maps", destination: URL(string: "http://maps.apple.com/?address=1600,PennsylvaniaAve.,20500")!)
            Button("Hello, World!") {
                cancellable = fetch(request: Endpoint<ATResponse<ATUser>>.fetchAllUsers)
                    .map {
                        return $0.records
                    }
                    .flatMap {
                        $0.publisher
                    }
                    .map {$0}
                    .flatMap { (user: ATRecord<ATUser>) -> AnyPublisher<FinalUser, NetworkRequestError> in
                        fetch(request: Endpoint<ATResponse<ATBurger>>.fetchBurgers(ids: user.object.burgers))
                            .map {
                                FinalUser(networkRecord: user, burgers: $0.allObjects)
                            }
                            .eraseToAnyPublisher()
                    }
                    .sink { (completion) in
                        switch completion {
                        case let .failure(error):
                            print(error)
                        case .finished:
                            print("fini")
                        }
                    } receiveValue: { _ in
                        print("hoho")
                    }
            }
        }
    }
}

struct BurgerView_Previews: PreviewProvider {
    static var previews: some View {
        BurgerView()
    }
}
