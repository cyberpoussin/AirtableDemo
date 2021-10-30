//
//  HyperStoreView.swift
//  HyperStoreView
//
//  Created by Admin on 04/09/2021.
//

import SwiftUI
import Combine

class HyperStoreViewModel: ObservableObject {
    let store = HyperStore()
    private var cancellables: Set<AnyCancellable> = []
    
    struct ViewState {
        var items: [MasterStore.Item] = []
        var error: String?
        var loading: Bool = false
    }
    
    @Published var state = ViewState()

    
    init() {
        store.$state
            .sink { [weak self] state in
                self?.state.error = nil
                self?.state.loading = false
                switch state {
                case let .content(items):
                    self?.state.items = items
                case let .error(error):
                    self?.state.error = error
                case .loading:
                    self?.state.loading = true
                default: break
                }
            }
            .store(in: &cancellables)
    }
    
    func fetchAllItems() {
        store.send(.fetchList)
    }
    
}

struct HyperStoreView: View {
    @StateObject var vm = HyperStoreViewModel()
    var body: some View {
        List(vm.state.items) {item in
            NavigationLink(destination: Text("")) {
                Text(item.name)
            }
        }
        .toolbar {
            HStack {
                Text(vm.state.loading ? "charge" : "")
                Text(vm.state.error ?? "" )
                Button("Refresh", action: vm.fetchAllItems)
            }
        }
        .onAppear { vm.fetchAllItems() }
    }
}

struct HyperStoreView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
        HyperStoreView()
        }
    }
}
