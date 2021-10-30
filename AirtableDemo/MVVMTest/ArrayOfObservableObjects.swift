//
//  ArrayOfObservableObjects.swift
//  ArrayOfObservableObjects
//
//  Created by Admin on 02/09/2021.
//

import Combine
import SwiftUI

struct ArrayOfObservableObjects: View {
    @StateObject var store = RecordStore()
    var body: some View {
        NavigationView {
            List(store.records) { record in
                Text(record.score.description)
            }
            .toolbar {
                HStack {
                    Button("Shuffle") {
                        store.records.shuffle()
                    }
                    Button("Change First") {
                        store.records.first?.score = 666
                    }
                    Button("Add") {
                        store.records.insert(Record(store.records.count + 1), at: 0)
                    }
                }
            }
        }
    }
}

class Record: ObservableObject, Identifiable {
    let id = UUID()
    @Published var score: Int
    init(_ score: Int) {
        self.score = score
    }
}

class RecordStore: ObservableObject {
    @Published var records: [Record] = (1 ... 5).map(Record.init) {
        didSet {
            subscribeToChanges()
        }
    }

    private var c: AnyCancellable?
    init() {
        subscribeToChanges()
    }

    func subscribeToChanges() {
        c = records
            .publisher
            .flatMap { record in record.objectWillChange }
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
    }
}

struct ArrayOfObservableObjects_Previews: PreviewProvider {
    static var previews: some View {
        ArrayOfObservableObjects()
    }
}
