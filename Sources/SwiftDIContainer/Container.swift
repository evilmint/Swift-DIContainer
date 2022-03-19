//
//  Container.swift
//  TestSwinject
//
//  Created by Aleksander Lorenc on 12/03/2022.
//

enum DependencyScope {
    case shared
    case transient
    case scoped
}

private final class DependencyStorage {
    private(set) fileprivate var sharedInstances: [ObjectIdentifier: Any] = [:]
    private(set) fileprivate var scopedInstances: [ObjectIdentifier: [ObjectIdentifier: Any]] = [:]
    private(set) fileprivate var scopes: [ObjectIdentifier: DependencyScope] = [:]
    fileprivate var factories: [ObjectIdentifier: Any] = [:]

    func registerFactory<T>(_ factory: Any, forType type: T.Type, withScope scope: DependencyScope) {
        factories[ObjectIdentifier(T.self)] = factory
        scopes[ObjectIdentifier(T.self)] = scope
    }

    func setScopedInstance<T>(_ value: T, scope: Container) {
        if scopedInstances[ObjectIdentifier(scope)] == nil {
            scopedInstances[ObjectIdentifier(scope)] = [:]
        }
        scopedInstances[ObjectIdentifier(scope)]![ObjectIdentifier(T.self)] = value
    }

    func retrieveScopedInstance<T>(scope: Container) -> T? {
        scopedInstances[ObjectIdentifier(scope)]?[ObjectIdentifier(T.self)] as? T
    }
}

final class Container {
    private typealias FactorySignatureArg0<T> = (Container) -> T
    private typealias FactorySignatureArg1<T, Arg1> = (Container, Arg1) -> T
    private typealias FactorySignatureArg2<T, Arg1, Arg2> = (Container, Arg1, Arg2) -> T

    private let storage: DependencyStorage
    private weak var parent: Container?

    init() {
        storage = DependencyStorage()
    }

    init(parent: Container) {
        self.storage = parent.storage
    }

    func resolve<T>(_ type: T.Type) -> T? {
        guard let scope = storage.scopes[ObjectIdentifier(T.self)] else { return nil }

        let creator = storage.factories[ObjectIdentifier(T.self)] as? FactorySignatureArg0<T>
        let value = retrieveValue(forType: type, scope: scope) ?? creator?(self)

        value.map { storeValue($0, forScope: scope) }

        return value
    }

    func resolve<T, Arg1>(_ type: T.Type, arg1: Arg1) -> T? {
        guard let scope = storage.scopes[ObjectIdentifier(T.self)] else { return nil }

        let creator = storage.factories[ObjectIdentifier(T.self)] as? FactorySignatureArg1<T, Arg1>
        let value = retrieveValue(forType: type, scope: scope) ?? creator?(self, arg1)

        value.map { storeValue($0, forScope: scope) }

        return value
    }

    func resolve<T, Arg1, Arg2>(_ type: T.Type, arg1: Arg1, arg2: Arg2) -> T? {
        guard let scope = storage.scopes[ObjectIdentifier(T.self)] else { return nil }

        let creator = storage.factories[ObjectIdentifier(T.self)] as? FactorySignatureArg2<T, Arg1, Arg2>
        let value = retrieveValue(forType: type, scope: scope) ?? creator?(self, arg1, arg2)

        value.map { storeValue($0, forScope: scope) }

        return value
    }

    func register<T>(_ type: T.Type, scope: DependencyScope = .shared, factory: @escaping (Container) -> T) {
        storage.registerFactory(factory, forType: type, withScope: scope)
    }

    func register<T, Arg1>(_ type: T.Type, scope: DependencyScope = .shared, factory: @escaping (Container, Arg1) -> T) {
        storage.registerFactory(factory, forType: type, withScope: scope)
    }

    func register<T, Arg1, Arg2>(_ type: T.Type, scope: DependencyScope = .shared, factory: @escaping (Container, Arg1, Arg2) -> T) {
        storage.registerFactory(factory, forType: type, withScope: scope)
    }

    func spawnSubcontainer() -> Container {
        let container = Container(parent: self)
        container.parent = self
        return container
    }

    private func retrieveValue<T>(forType type: T.Type, scope: DependencyScope) -> T? {
        switch scope {
        case .shared:
            return storage.sharedInstances[ObjectIdentifier(T.self)] as? T
        case .scoped:
            let instance: T? = storage.retrieveScopedInstance(scope: self)
            return instance
        case .transient:
            return nil
        }
    }

    private func storeValue<T>(_ value: T, forScope scope: DependencyScope) {
        switch scope {
        case .shared:
            storage.sharedInstances[ObjectIdentifier(T.self)] = value
        case .scoped:
            storage.setScopedInstance(value, scope: self)
        case .transient:
            break
        }
    }
}
