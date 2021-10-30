//
//  MasterView.swift
//  MasterView
//
//  Created by Admin on 01/09/2021.
//

import Combine
import SwiftUI

struct MasterView: View {
    let items: [MasterViewModel.Item]
    let selection: MasterViewModel.Selection?
    let selectDetail: (_ id: MasterViewModel.Item.ID) -> Void
    let unselectDetail: () -> Void
    let onAppear: () -> Void
    let changeItem: (MasterStore.Item) -> Void
    let error: Bool

    var body: some View {
        List {
            ForEach(items, id: \.id) { element in
                NavigationLink(
                    tag: element.id,
                    selection: link()) {
                    if let selection = self.selection {
                        DetailViewContainer(vm: selection.viewModel)
                    }
                } label: {
                    Text("\(element.name)")
                }
            }
        }
        .toolbar {
            if !error {
                Button("Change") {
                    let itemsToChange = items.filter { $0.name != "Anonymous" }
                    var newItem = itemsToChange[Int.random(in: 0 ..< itemsToChange.count)]
                    newItem.name = "Anonymous"
                    changeItem(newItem)
                }
            } else {
                Button("Error : try to reconnect", action: onAppear)
            }
        }
        .onAppear {
            print("on appear")
            onAppear()
        }
    }

    func link() -> Binding<MasterStore.Item.ID?> {
        Binding {
            self.selection?.id
        } set: { id in
            if let id = id {
                selectDetail(id)
            } else {
                unselectDetail()
            }
        }
    }
}

struct DetailViewContainer: View {
    @ObservedObject var vm: DetailViewModel
    var body: some View {
        DetailView(error: vm.viewState.error,
                   item: vm.viewState.item,
                   reSync: vm.reSync,
                   changeItem: vm.changeItem)
    }
}

struct DetailView: View {
    let error: Bool
    let item: DetailViewModel.Item
    let reSync: () -> Void
    let changeItem: (DetailViewModel.Item) -> Void
    
    var body: some View {
        VStack {
            if !error {
                Button("Save") {
                    var item = item
                    item.name = "Saved"
                    changeItem(item)
                }
            } else {
                Button("Error : try to reconnect") {
                    reSync()
                }
            }
            Text(item.name)
        }
    }
}

class MockItemService {
    typealias Item = MasterStore.Item
    var MOCKDATA: [Item] = [
        .init(id: 1, name: "John", description: "The best"),
        .init(id: 2, name: "Bob", description: "The best"),
        .init(id: 3, name: "Mary", description: "The best"),
        .init(id: 4, name: "Jeanne", description: "The best"),
        .init(id: 5, name: "Steeve", description: "The best"),
        .init(id: 6, name: "Greg", description: "The best"),
        .init(id: 7, name: "Steeven", description: "The best"),
    ]
    func applyAndSendResponse<T: Any>(_ data: T, _ action: @escaping () -> Void = {}) -> AnyPublisher<T, Error> {
        Just(data)
            .delay(for: 0.3, scheduler: DispatchQueue.main)
            .tryMap { item in
                if Int.random(in: 1 ... 100) != 1 {
                    action()
                    return item
                } else {
                    throw URLError(.unknown)
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchAllItems() -> AnyPublisher<[Item], Error> {
        applyAndSendResponse(MOCKDATA.shuffled())
    }

    func fetchFullItem(item: Item) -> AnyPublisher<Item, Error> {
        var newItem = item
        newItem.description = "A very long description"
        return applyAndSendResponse(item)
    }

    func post(item: Item) -> AnyPublisher<Bool, Error> {
        applyAndSendResponse(true, { self.MOCKDATA.append(item) })
    }

    func update(item: Item) -> AnyPublisher<Bool, Error> {
        guard let index = MOCKDATA.firstIndex(where: { $0.id == item.id }) else { return Fail(error: URLError(.unknown)).eraseToAnyPublisher() }
        return applyAndSendResponse(true, {
            self.MOCKDATA[index] = item
            print("item posted")
        })
    }
}

final class MasterViewModel: ObservableObject {
    typealias Item = MasterStore.Item
    struct ViewState {
        var items: [Item] = []
        var error: Bool = false
        var selection: Selection? = nil
    }

    struct Selection: Identifiable {
        var id: Item.ID
        var viewModel: DetailViewModel
    }

    @Published private(set) var viewState: ViewState
    let store: MasterStore
    var cancellables: Set<AnyCancellable> = []
    init(store: MasterStore = MasterStore()) {
        self.store = store
        viewState = ViewState()
        store.statePublisher
            .sink { [weak self] newStoreState in
                self?.viewState.error = false
                switch newStoreState {
                case let .content(items):
                    self?.viewState.items = items
                case .error:
                    self?.viewState.error = true
                default: break
                }
            }
            .store(in: &cancellables)
    }

    func selectDetail(id: Item.ID) {
        guard let item = viewState.items.first(where: { id == $0.id }) else { return }
        let detailViewModel = DetailViewModel(
            item: item,
            store: ChildStore(
                initialValue: item,
                parentInput: store.inputSubject,
                parentOutput: store.outputPublisher.eraseToAnyPublisher()
            )
        )
        viewState.selection = Selection(
            id: item.id,
            viewModel: detailViewModel)
    }

    func unselectDetail() {
        viewState.selection = nil
    }

    func onAppear() {
        if viewState.items.isEmpty || viewState.error {
            store.send(.syncContent)
        }
    }

    func changeItem(_ item: Item) {
        store.send(.changeItem(item))
    }
}

final class DetailViewModel: ObservableObject {
    typealias Item = MasterStore.Item
    struct ViewState {
        var item: Item
        var error: Bool
    }

    @Published private(set) var viewState: ViewState
    private var store: ChildStore
    private var cancellable: AnyCancellable?
    init(item: Item, store: ChildStore) {
        viewState = .init(item: item, error: false)
        self.store = store
        cancellable = store.statePublisher
            .sink { [weak self] newStoreState in
                self?.viewState.error = false
                switch newStoreState {
                case .error:
                    self?.viewState.error = true
                case let .content(item):
                    self?.viewState.item = item
                }
            }
    }

    func reSync() {
        store.send(.syncContent)
    }

    func changeItem(_ item: Item) {
        store.send(.changeItem(item))
    }
}

struct MasterContainerView: View {
    @ObservedObject private(set) var viewModel: MasterViewModel

    var body: some View {
        MasterView(
            items: viewModel.viewState.items,
            selection: viewModel.viewState.selection,
            selectDetail: viewModel.selectDetail(id:),
            unselectDetail: viewModel.unselectDetail,
            onAppear: viewModel.onAppear,
            changeItem: viewModel.changeItem,
            error: viewModel.viewState.error)
    }
}

struct MasterTestView: View {
    @StateObject var viewModel = MasterViewModel()

    var body: some View {
        NavigationView {
            MasterContainerView(viewModel: viewModel)
        }
        .navigationViewStyle(.stack)
    }
}

struct MasterView_Previews: PreviewProvider {
    static var previews: some View {
        MasterTestView()
    }
}
