//
//  Store.swift
//  Store
//
//  Created by Admin on 02/09/2021.
//

import Foundation
import Combine

final class MasterStore {
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
        case addItem(Item)
        case changeItem(Item)
    }
    enum Action {
        case updateState(State)
        case itemAdded(Item)
        case itemChanged(Item)
    }
    
    let inputSubject = PassthroughSubject<Input, Never>()
    let statePublisher: AnyPublisher<State, Never>
    private var stateSubject = CurrentValueSubject<State, Never>(.idle)
    private var cancellables = Set<AnyCancellable>()
    private var storeState: State = .idle
    private var network = MockItemService()
    init() {
        statePublisher = stateSubject.share().eraseToAnyPublisher()
    
        inputSubject
            .zip(statePublisher)
            .flatMap { [network] (input, currentState) -> AnyPublisher<Action, Never> in
                print("event reçu dans le Master")
                //guard let self = self else { return Empty<Action,Never>().eraseToAnyPublisher()}
                switch input {
                case .syncContent:
                    print("Master demande sync")

                    return network.fetchAllItems()
                        .map { .updateState(.content($0)) }
                        .replaceError(with: .updateState(.error))
                        .eraseToAnyPublisher()
                case let .addItem(item):
                    print("Master demande addItem")

                    guard case .content = currentState else { return Just(.updateState(.error)).eraseToAnyPublisher()
                    }
                    return network.post(item: item)
                        .map {_ in .itemAdded(item) }
                        .replaceError(with: .updateState(.error))
                        .eraseToAnyPublisher()
                case let .changeItem(item):
                    print("Master demande changeItem")

                    guard case .content = currentState else { return Just(.updateState(.error)).eraseToAnyPublisher()
                    }
                    return network.update(item: item)
                        .map {_ in .itemChanged(item) }
                        .replaceError(with: .updateState(.error))
                        .eraseToAnyPublisher()
                }
            }
            .scan(storeState) { (currentState, action) -> State in
                switch action {
                case let .updateState(state):
                    print("Master nouveau State : \(state)")
                    return state
                case let .itemAdded(item):

                    if case let .content(items) = currentState {
                        print("Master nouvel item : \(item)")

                        var newItems = items
                        newItems.append(item)
                        return .content(newItems)
                    }
                    print("Master échec nouvel item : \(item)")

                    return currentState
                case let .itemChanged(item):
                    if case let .content(items) = currentState {
                        print("Master changement item : \(item)")

                        var newItems = items
                        let index = newItems.firstIndex(where: {$0.id == item.id})!
                        newItems[index] = item
                        return .content(newItems)
                    }
                    print("Master échec changement: \(item)")

                    return currentState
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.storeState = $0
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
        case idle
        case content(Item)
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
    
    let statePublisher: CurrentValueSubject<State, Never>
    private let inputSubject = PassthroughSubject<Input, Never>()
    private var input: Input? = nil
    private let parentStatePublisher: AnyPublisher<MasterStore.State, Never>
    private let parentInputSubject: PassthroughSubject<MasterStore.Input, Never>
    private var cancellables = Set<AnyCancellable>()
    private var storeState: State
    private var network = MockItemService()
    private var initialValue: Item
    private var newChildInput: Bool = false
    init(initialValue: Item, parentInput: PassthroughSubject<MasterStore.Input, Never>, parentOutput: AnyPublisher<MasterStore.State, Never>) {
        self.initialValue = initialValue
        self.storeState = .content(initialValue)
        self.statePublisher = CurrentValueSubject<State, Never>(.content(initialValue))
        self.parentInputSubject = parentInput
        self.parentStatePublisher = parentOutput

        
        parentStatePublisher
            .combineLatest(inputSubject)
            .removeDuplicates {[weak self] value,_ in
                self?.newChildInput != true
            }
            .flatMap { [network, initialValue] (parentOutput, input) -> AnyPublisher<Action, Never> in
                //guard let self = self else { return Empty<Action, Never>().eraseToAnyPublisher() }
                print("Event \(input) reçu dans le Child")
                print("avec le retour parent : \(parentOutput)")
                switch input {
                case .syncContent:
                    switch parentOutput {
                    case .error:
                        print("print error")
                        return Just(.updateState(.error)).eraseToAnyPublisher()
                    default:
                        return network.fetchFullItem(item: initialValue)
                            .map { .updateState(.content($0)) }
                            .replaceError(with: .updateState(.error))
                            .eraseToAnyPublisher()
                    }
                case let .changeItem(item):
                    switch parentOutput {
                    case .error:
                        print("print error")
                        return Just(.updateState(.error)).eraseToAnyPublisher()
                    default:
                        print("changed")
                        return Just(.itemChanged(item)).eraseToAnyPublisher()
                    }
                }
                
            }
            .scan(storeState) { (currentState, action) -> State in
                print("\(action)")
                switch action {
                case let .updateState(state):
                    print("updated")
                    return state
                case let .itemChanged(item):
                    print("changed again")
                    return .content(item)
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.newChildInput = false
                self?.storeState = $0
                self?.statePublisher.send($0)
            }
            .store(in: &cancellables)
    }
            
    func send(_ input: Input) {
        inputSubject.send(input)
        self.newChildInput = true
        switch input {
        case let .changeItem(item): parentInputSubject.send(.changeItem(item))
        case .syncContent: parentInputSubject.send(.syncContent)
        default: break
        }
    }
}


@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publisher {
  ///  Merges two publishers into a single publisher by combining each value
  ///  from self with the latest value from the second publisher, if any.
  ///
  ///  - parameter other: Second observable source.
  ///  - parameter resultSelector: Function to invoke for each value from the self combined
  ///                              with the latest value from the second source, if any.
  ///
  ///  - returns: A publisher containing the result of combining each value of the self
  ///             with the latest value from the second publisher, if any, using the
  ///             specified result selector function.
  func withLatestFrom<Other: Publisher, Result>(_ other: Other,
                                                resultSelector: @escaping (Output, Other.Output) -> Result)
      -> Publishers.WithLatestFrom<Self, Other, Result> {
    return .init(upstream: self, second: other, resultSelector: resultSelector)
  }

  ///  Upon an emission from self, emit the latest value from the
  ///  second publisher, if any exists.
  ///
  ///  - parameter other: Second observable source.
  ///
  ///  - returns: A publisher containing the latest value from the second publisher, if any.
  func withLatestFrom<Other: Publisher>(_ other: Other)
      -> Publishers.WithLatestFrom<Self, Other, Other.Output> {
    return .init(upstream: self, second: other) { $1 }
  }
}

// MARK: - Publisher
extension Publishers {
  @available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
  public struct WithLatestFrom<Upstream: Publisher,
                               Other: Publisher,
                               Output>: Publisher where Upstream.Failure == Other.Failure {
    public typealias Failure = Upstream.Failure
    public typealias ResultSelector = (Upstream.Output, Other.Output) -> Output

    private let upstream: Upstream
    private let second: Other
    private let resultSelector: ResultSelector
    private var latestValue: Other.Output?

    init(upstream: Upstream,
         second: Other,
         resultSelector: @escaping ResultSelector) {
      self.upstream = upstream
      self.second = second
      self.resultSelector = resultSelector
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
      let sub = Subscription(upstream: upstream,
                             second: second,
                             resultSelector: resultSelector,
                             subscriber: subscriber)
      subscriber.receive(subscription: sub)
    }
  }
}

// MARK: - Subscription
@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension Publishers.WithLatestFrom {
  private class Subscription<S: Subscriber>: Combine.Subscription where S.Input == Output, S.Failure == Failure {
    private let subscriber: S
    private let resultSelector: ResultSelector
    private var latestValue: Other.Output?

    private let upstream: Upstream
    private let second: Other

    private var firstSubscription: Cancellable?
    private var secondSubscription: Cancellable?

    init(upstream: Upstream,
         second: Other,
         resultSelector: @escaping ResultSelector,
         subscriber: S) {
      self.upstream = upstream
      self.second = second
      self.subscriber = subscriber
      self.resultSelector = resultSelector
      trackLatestFromSecond()
    }

    func request(_ demand: Subscribers.Demand) {
      // withLatestFrom always takes one latest value from the second
      // observable, so demand doesn't really have a meaning here.
      firstSubscription = upstream
        .sink(
          receiveCompletion: { [subscriber] in subscriber.receive(completion: $0) },
          receiveValue: { [weak self] value in
            guard let self = self else { return }

            guard let latest = self.latestValue else { return }
            _ = self.subscriber.receive(self.resultSelector(value, latest))
        })
    }

    // Create an internal subscription to the `Other` publisher,
    // constantly tracking its latest value
    private func trackLatestFromSecond() {
      let subscriber = AnySubscriber<Other.Output, Other.Failure>(
        receiveSubscription: { [weak self] subscription in
          self?.secondSubscription = subscription
          subscription.request(.unlimited)
        },
        receiveValue: { [weak self] value in
          self?.latestValue = value
          return .unlimited
        },
        receiveCompletion: nil)

      self.second.subscribe(subscriber)
    }

    func cancel() {
      firstSubscription?.cancel()
      secondSubscription?.cancel()
    }
  }
}
