//
//  Store.swift
//  Store
//
//  Created by Admin on 02/09/2021.
//

import Combine
import Foundation

func machine<State, Input, Action, Service>(
    input: AnyPublisher<(Input, State), Never>,
    initialState: State,
    feedbacks: @escaping (Input, State) -> AnyPublisher<Action, Never>,
    reducer: @escaping (State, Action) -> State,
    service: Service
) -> AnyPublisher<State, Never> {
    input
        .flatMap { input, state in feedbacks(input, state) }
        .scan(initialState, reducer)
        .eraseToAnyPublisher()
}

func machine<State, Input, Output, Action, Service>(
    parentOutput: AnyPublisher<Output, Never>,
    inputReducer: @escaping (Output) -> Input?,
    inputSubject: AnyPublisher<Input, Never>,
    statePublisher: AnyPublisher<State, Never>,
    initialState: State,
    feedbacks: @escaping (Input, State) -> AnyPublisher<Action, Never>,
    reducer: @escaping (State, Action) -> State,
    service: Service
) -> AnyPublisher<State, Never> {
    let input = parentOutput
        .compactMap(inputReducer)
        .merge(with: inputSubject)
        .zip(statePublisher)
        .eraseToAnyPublisher()
    return machine(input: input, initialState: initialState, feedbacks: feedbacks, reducer: reducer, service: service)
}


protocol WithMachine {
    associatedtype State
    associatedtype Event

    var state: State { get }
    
    func machine(event: AnyPublisher<Event,Never>, state: AnyPublisher<State,Never>) -> AnyPublisher<State,Never>
    
    static func reducer(currentState: State, action: Event) -> State
    
    func feedbacks(state: State, event: Event) -> AnyPublisher<Event, Never>
}

extension WithMachine {
    func machine(event: AnyPublisher<Event,Never>, state: AnyPublisher<State,Never>) -> AnyPublisher<State,Never> {
        let input = state.zip(event)
        let sideEffects = input
            .flatMap {(state, event) in
                self.feedbacks(state: Self.reducer(currentState: state, action: event), event: event).map { ( state, $0)
                }
            }
            //.switchToLatest()
            .map(Self.reducer)
        return input
            .map(Self.reducer)
            .merge(with: sideEffects)
            .eraseToAnyPublisher()
    }
}


final class HyperStore: WithMachine {
    typealias Item = MasterStore.Item

    enum State {
        case idle
        case content([Item])
        case error(String)
        
        case loading

    }

    enum Event {
        case fetchList
        case fetchItem(Item)
        case postItem(Item)

        case setList([Item])
        case setItem(Item)
        case setError(String)
    }
    
    enum Input {
        case fetchList
        case fetchItem(Item)
        case postItem(Item)
    }
    
    let event = PassthroughSubject<Event, Never>()
    @Published var state: State = .idle
    private var network = MockItemService()

    init() {
        machine(event: event.eraseToAnyPublisher(), state: $state.eraseToAnyPublisher())
            .assign(to: &$state)
//        $state
//            .map(feedbacks)
//            .switchToLatest()
//            .merge(with: event)
//            .scan(.idle, reducer)
//            .prepend(.idle)
//            .sink {[weak self] newState in self?.state = newState}
//            .store(in: &cancellables)
    }
    
    static func reducer(currentState: State, action: Event) -> State {
        switch action {
        case .fetchList, .fetchItem, .postItem:
            return .loading
        case let .setList(list):
            return .content(list)
        case .setItem(let item):
            if case let .content(items) = currentState {
                var newItems = items
                let index = newItems.firstIndex(where: { $0.id == item.id })!
                newItems[index] = item
                return .content(newItems)
            }
            return .error("unknown")
        case .setError(let error):
            return .error(error)
        }
    }
    
    func feedbacks(state: State, event: Event) -> AnyPublisher<Event, Never> {
            switch event {
            case .fetchList:
                return network.fetchAllItems()
                    .map { .setList($0) }
                    .replaceError(with: .setError("error"))
                    .eraseToAnyPublisher()
            case .fetchItem(let item):
                guard case .content = state else { return Just(.setError("erreur")).eraseToAnyPublisher() }
                return network.update(item: item)
                    .map { _ in .setItem(item) }
                    .replaceError(with: .setError("error"))
                    .eraseToAnyPublisher()
            default : break
            }

        
        return Empty().eraseToAnyPublisher()
    }
    
    func send(_ input: Input) {
        let event: Event
        switch input {
        case .fetchList:
            event = .fetchList
        case .fetchItem(let item):
            event = .fetchItem(item)
        case .postItem(let item):
            event = .postItem(item)
        }
        self.event.send(event)
    }
}

final class MasterStore: ObservableObject {

    struct Item: Identifiable {
        var id: Int
        var name: String
        var description: String
    }

    enum State {
        case idle
        case content([Item])
        case error
    }

    enum Input {
        case syncContent
        case changeItem(Item)
    }

    enum Action {
        case updateState(State)
        case itemChanged(Item)
    }

    let inputSubject = PassthroughSubject<Input, Never>()
    let outputPublisher = PassthroughSubject<Action, Never>()

    let statePublisher: AnyPublisher<State, Never>

    private var stateSubject = CurrentValueSubject<State, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var network = MockItemService()

    func feedbacks(input: Input, state: State) -> AnyPublisher<Action, Never> {
        switch input {
        case .syncContent:
            return network.fetchAllItems()
                .map { .updateState(.content($0)) }
                .replaceError(with: .updateState(.error))
                .eraseToAnyPublisher()
        case let .changeItem(item):
            guard case .content = state else { return Just(.updateState(.error)).eraseToAnyPublisher() }
            return network.update(item: item)
                .map { _ in .itemChanged(item) }
                .replaceError(with: .updateState(.error))
                .eraseToAnyPublisher()
        }
    }

    func reducer(currentState: State, action: Action) -> State {
        outputPublisher.send(action)
        switch action {
        case let .updateState(state):
            return state
        case let .itemChanged(item):
            if case let .content(items) = currentState {
                var newItems = items
                let index = newItems.firstIndex(where: { $0.id == item.id })!
                newItems[index] = item
                return .content(newItems)
            }
            return currentState
        }
    }

    init() {
        statePublisher = stateSubject.share().eraseToAnyPublisher()
        machine(
            input: inputSubject.zip(statePublisher).eraseToAnyPublisher(),
            initialState: .idle,
            feedbacks: feedbacks,
            reducer: reducer,
            service: network)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.stateSubject.send($0)
            }
            .store(in: &cancellables)
    }

    func send(_ input: Input) {
        inputSubject.send(input)
    }
}

final class ChildStore {
    typealias Item = MasterStore.Item

    enum State {
        case content(Item)
        case error
    }

    enum Input {
        case syncContent
        case changeItem(Item)
        case masterError
    }

    enum Action {
        case updateState(State)
        case itemChanged(Item)
    }

    private var state: State {
        didSet {
            newChildInput = false
            statePublisher.send(state)
        }
    }

    let statePublisher: CurrentValueSubject<State, Never>

    private let inputSubject = PassthroughSubject<Input, Never>()
    private let parentInputSubject: PassthroughSubject<MasterStore.Input, Never>
    private var cancellables = Set<AnyCancellable>()
    private var newChildInput: Bool = false
    private var network = MockItemService()
    private let initialValue: Item

    func feedbacks(input: Input, state: State) -> AnyPublisher<Action, Never> {
        switch input {
        case .syncContent:
            return network.fetchFullItem(item: initialValue)
                .map { .updateState(.content($0)) }
                .replaceError(with: .updateState(.error))
                .eraseToAnyPublisher()
        case let .changeItem(item):
            return Just(.itemChanged(item)).eraseToAnyPublisher()
        case .masterError:
            return Just(.updateState(.error)).eraseToAnyPublisher()
        default:
            return Empty().eraseToAnyPublisher()
        }
    }

    func reducer(currentState: State, action: Action) -> State {
        switch action {
        case let .updateState(state):
            return state
        case let .itemChanged(item):
            return .content(item)
        }
    }

    func inputReducer(output: MasterStore.Action) -> Input? {
        switch output {
        case let .itemChanged(item):
            return .changeItem(item)
        case let .updateState(state):
            switch state {
            case .content:
                return .syncContent
            case .error:
                return .masterError
            default: return nil
            }
        }
    }

    init(initialValue: Item, parentInput: PassthroughSubject<MasterStore.Input, Never>, parentOutput: AnyPublisher<MasterStore.Action, Never>) {
        state = .content(initialValue)
        statePublisher = CurrentValueSubject<State, Never>(.content(initialValue))
        parentInputSubject = parentInput
        self.initialValue = initialValue

        machine(parentOutput: parentOutput,
                inputReducer: inputReducer,
                inputSubject: inputSubject.eraseToAnyPublisher(),
                statePublisher: statePublisher.eraseToAnyPublisher(),
                initialState: .content(initialValue),
                feedbacks: feedbacks,
                reducer: reducer,
                service: network
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] in
            self?.statePublisher.send($0)
        }
        .store(in: &cancellables)

//        let input = parentOutput
//            .combineLatest(inputSubject.zip(statePublisher).eraseToAnyPublisher())
//            .removeDuplicates { [weak self] _, _ in
//                self?.newChildInput != true
//            }
//            .map {(parentState, inputAndState) -> (Input, MasterStore.State, State)  in
//                let (input, state) = inputAndState
//                return (input, parentState, state)
//            }
//            .eraseToAnyPublisher()
//
//        childMachine(
//            input: input,
//            initialState: .content(initialValue),
//            feedbacks: feedbacks,
//            reducer: reducer,
//            service: network)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] in
//                self?.state = $0
//            }
//            .store(in: &cancellables)
    }

    func send(_ input: Input) {
        switch input {
        case let .changeItem(item): parentInputSubject.send(.changeItem(item))
        case .syncContent: parentInputSubject.send(.syncContent)
        default: inputSubject.send(input)
        }
    }
}
