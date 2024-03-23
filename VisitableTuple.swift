//
//  VisitableTuple.swift
//
//  Created by Bartłomiej Bukowiecki on 23/03/2024.
//

import SwiftUI

// MARK: Case dependent code

protocol Visitor {
    func visit<T>(_ item: T) where T: View
}

struct AnyVisitable: VisitableItem {
    private let wrappedAcceptor: (Visitor) -> Void
    
    init<V>(item: V) where V: View {
        self.wrappedAcceptor = { visitor in
            visitor.visit(item)
        }
    }
    
    func accept<T>(visitor: T) where T: Visitor {
        wrappedAcceptor(visitor)
    }
}

@resultBuilder
struct VisitableTupleBuilder {
    static func buildBlock<each Item: View>(_ item: repeat each Item) -> VisitableTuple<(repeat each Item)> {
        func makeVisitable<T: View>(_ item: T, counter: inout Int, visitables: inout [AnyVisitable]) -> T {
            counter += 1
            visitables.append(.init(item: item))
            
            return item
        }
        
        var counter = 0
        var visitables = [AnyVisitable]()
        let tuple = (repeat makeVisitable(each item, counter: &counter, visitables: &visitables))
        
        return VisitableTuple(value: tuple, valuesCount: counter, visitables: visitables)
    }
}

extension VisitableTuple: View {
    var body: some View {
        TupleView<T>(value)
    }
}

// MARK: Generic code

protocol VisitableItem {
    func accept<T>(visitor: T) where T: Visitor
}

struct VisitableTuple<T> {
    let value: T
    let valuesCount: Int
    private let visitables: [AnyVisitable]
    
    fileprivate init(value: T, valuesCount: Int, visitables: [AnyVisitable]) {
        self.value = value
        self.valuesCount = valuesCount
        self.visitables = visitables
    }
    
    public static func create(@VisitableTupleBuilder builder: () -> VisitableTuple<T>) -> VisitableTuple<T>{
        return builder()
    }
    
    func accept<V: Visitor>(visitor: V, at elementIndex: Int) {
        guard elementIndex < visitables.count else {
            fatalError("Index passed to VisitableTuple exceed amount of tuple elements!")
        }
        
        visitables[elementIndex].accept(visitor: visitor)
    }
}
