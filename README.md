# SwiftDIContainer

A very basic DI Container with factory methods.

Supports three dependency scopes: shared (across all containers), transient (created dependencies are not stored) and scoped (dependencies created in a sub-container are not visible in the parent containers).

## Dependency registration


```
protocol Car {
    var name: String { get }
    var age: Int { get }
}

class Supercar: Car {
    let name = "Supercar"
    let age: Int

    init(age: Int) {
        self.age = age
    }
}

protocol Builder { func buildInt() -> Int }
class SuperBuilder: Builder {

    func buildInt() -> Int {
        1337
    }
}

let container = Container()

container.register(Builder.self) { _ in SuperBuilder() }
container.register(Car.self) { (c: Container, age: Int) in
    let builder: Builder = c.resolve(Builder.self)!
    return Supercar(age: builder.buildInt() * 2)
}


```

## Resolving dependencies

```
let subContainer = container.spawnSubcontainer()

let car = subContainer.resolve(Car.self, arg1: 4)
let car2 = container.resolve(Car.self, arg1: 4)
```
