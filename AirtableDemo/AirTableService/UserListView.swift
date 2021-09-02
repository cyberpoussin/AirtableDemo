//
//  BurgerView.swift
//  PromoAvril
//
//  Created by Admin on 29/04/2021.
//

import SwiftUI
import Combine

class UserListViewViewModel: ObservableObject {
    var cancellable: Set<AnyCancellable> = []
    let useCases = UserUseCase()
    @Published var users: [FinalUser] = []
    
    func getAllUsers() {
        useCases.getAllUsers()
            .replaceError(with: [])
            .sink {[weak self] value in
                self?.users = value
            }
            .store(in: &cancellable)
    }
    
}

struct UserListView: View {
    @StateObject var vm = UserListViewViewModel()
    var body: some View {
        ZStack(alignment: .top) {
            List(vm.users) {user in
                Text(user.name)
            }
            Button("Hello, World!") {
                vm.getAllUsers()
            }
        }
    }
}

struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        UserListView()
    }
}
