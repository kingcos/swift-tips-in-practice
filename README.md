# swift-tips-in-practice

## Preface

[SwiftTips](https://github.com/johnsundell/swifttips) 是 [John Sundell](https://github.com/johnsundell) 在 GitHub 开源的 Swift 小技巧列表。随着 Swift 5 的发布以及 ABI 稳定，是时候再学习一遍 Swift 啦。本文将是该列表的实践版本，并保证文中代码的**可运行性**，且尽可能做到倒序~~日更~~。（But why in reverse? 🤫）

关于本文的代码，都可以在 [swift-tips-in-practice](https://github.com/kingcos/swift-tips-in-practice) 下载并实际运行。

|    Date    | Update |
| :--------: | :----: |
| 2019.08.22 |  #102  |
| 2019.08.23 |  #100  |
| 2019.08.27 |  #99   |

## #102 让异步测试执行更快更稳定

异步代码似乎总是很难去编写单元测试，因为我们不清楚什么时候请求才能回来。现在在 Swift 中，我们可以使用 `expectation`（预料）简单设定超时时间，并在 Closure 回调时调用 `fulfill()` 即可轻松实现。

Talk is cheap, show me the code!

```swift
import XCTest
@testable import TestUnitTest

class TestUnitTestTests: XCTestCase {
    func fetchFromNetwork(_ completion: @escaping (String) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            let response = "Foo"
            completion(response)
        }
    }

    // 🙅 Not good
    func testAsyncOperationsWithSleep() {
        fetchFromNetwork { res in
            XCTAssert(res == "Foo", "Response should be 'Foo'.")
        }

        sleep(2)
    }

    // 🚩 Preferred
    func testAsyncOperationsWithoutSleep() {
        // 声明 exp
        let exp = expectation(description: "Async Test")

        var result = ""
        fetchFromNetwork { res in
            result = res

            // Closure 执行完毕
            exp.fulfill()
        }

        // 等待 exp，超时时间 2 秒
        wait(for: [exp], timeout: 2.0)
        XCTAssert(result == "Foo", "Response should be 'Foo'.")
    }
}
```

对于单元测试，在 iOS 项目中使用「[Quick](https://github.com/Quick/Quick)」&「[Nimble](https://github.com/Quick/Nimble)」、在 Swift Package Management 项目中使用「[Spectre](https://github.com/kylef/Spectre)」可以编写更加符合 BDD（Behavior Driven Design 即行为驱动设计）的测试用例。后者我曾在开源项目 [WWDCHelper](https://github.com/kingcos/WWDCHelper) 中使用过，配合 CI 即可持续保障代码覆盖率。

### Reference

- [Unit testing asynchronous Swift code](https://www.swiftbysundell.com/posts/unit-testing-asynchronous-swift-code)

## #101 支持 Apple Pencil 双击

- 迫于没有设备，跳过该节。

## #100 函数绑定值

将值和函数使用额外的 `combine` 函数绑定起来，可无需在闭包（Closure）中捕获 `self`，相当于只将最终需要检查的执行者与参数告知即可。对于 `combine` 函数是支持泛型的，即其无需关心具体的业务内容，它只负责将参数与闭包组装并执行：

```swift
import UIKit

// 类型别名
typealias Handler = () -> Void

// 闭包包裹器，否则无法存储在关联对象内
fileprivate class ClosureWrapper {
    var handler: Handler?

    init(_ closure: Handler?) {
        handler = closure
    }
}

extension UIButton {
    // 关联键
    private struct AssociatedKeys {
        static var touchUpInside = "touchUpInside"
    }

    // 处理方法
    var handler: Handler? {
        get {
            if let wrapper = objc_getAssociatedObject(self,
                                                      &AssociatedKeys.touchUpInside) as? ClosureWrapper,
                let handler = wrapper.handler {
                return handler
            }

            return nil
        }

        set {
            if let newValue = newValue {
                objc_setAssociatedObject(self,
                                         &AssociatedKeys.touchUpInside,
                                         ClosureWrapper(newValue),
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

                addTarget(self, action: #selector(runHandler), for: .touchUpInside)
            } else {
                removeTarget(self, action: #selector(runHandler), for: .touchUpInside)
            }
        }
    }

    @objc func runHandler() {
        handler?()
    }
}


struct Product {
    var bar: Int
}

struct ProductManager {
    func startCheckout(for product: Product) {
        switch product.bar {
        case 0..<60:
            print("不合格")
        case 60...100:
            print("合格")
        default:
            fatalError()
        }
    }
}

// 泛型 A B
func combine<A, B>(_ value: A,
                   with closure: @escaping (A) -> B) -> () -> B {
    return { closure(value) }
}

class Demo100ViewController: UIViewController {
    lazy var fooButton: UIButton! = {
        let button = UIButton(type: .system)

        button.frame = CGRect(x: 0.0, y: 100.0, width: 100, height: 50)
        button.setTitle("Foo", for: .normal)

        view.addSubview(button)

        return button
    }()

    var product = Product(bar: 89)
    var productManager = ProductManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "100"
        view.backgroundColor = .white

        // 🙅‍♂️ Not good
        fooButton.handler = { [weak self] in
            guard let self = self else { return }

            self.productManager.startCheckout(for: self.product)
        }

        // 🚩 Preferred
        fooButton.handler = combine(self.product, with: productManager.startCheckout)
    }
}
```

然而在真正实现这一段的 `handler` 时，却花费了一些周折。`UIButton` 在官方的设计模式是 Target Action，而我们需要改为闭包回调的形式。由于 Swift 的 `extension` 并不支持存储属性，类似 Obj-C 的 Category 不支持实例变量，这里仍然使用了关联对象来将闭包关联在对象上。又由于闭包无法直接被关联，仍然需要包裹在类中才得以实现。

## #99 使用函数进行依赖注入

在开始前，我们先来认识一下什么是**依赖注入（Dependency Injection）**。

依赖注入又称控制反转（Inversion of Control，IoC）。简单来说，依赖注入的重点在于注入，即将依赖以**注入**的方式引入，而非直接在依赖内创建，以避免耦合。举个简单的例子：

```swift
struct Foo {
    var bar: String
}

struct FooFactory {
    static func generate(_ bar: String) -> Foo {
        return Foo(bar: bar)
    }
}

struct Bar {
    var foo: Foo

    // 🙅 Not good
    init(_ bar: String) {
        foo = Foo(bar: bar)
        // foo = FooFactory.generate(bar)
    }

    // 🚩 Preferred
    init(_ foo: Foo) {
        self.foo = foo
    }
}
```

设计模式上更加推荐将 `foo` 直接注入到 `Bar` 中，显而易见的好处是这样可以便于单元测试，因为我们将 `Foo` 的构造暴露了在外部，避免增加了 `Bar` 的耦合度。这也正符合其另一个名称控制反转，即将控制权交由外界，`Bar` 无需关心 `foo` 是如何创建的（通过构造器，抑或工厂方法等），其只需要直接使用即可。

在 Swift 中，函数是一类公民，即可以作为一种类型。因此函数的注入也使得内部无需关心函数具体的定义，只需要定义好参数和返回值即可。比如在网络请求中，我们可以无需关心网络层到底是通过 `URLSession` 还是 `Alamofire` 这样封装好的网络库来构造的：

```swift

```

### Reference

- [Simple Swift dependency injection with functions](https://www.swiftbysundell.com/posts/simple-swift-dependency-injection-with-functions)
- [Under the hood of Futures & Promises in Swift](https://www.swiftbysundell.com/posts/under-the-hood-of-futures-and-promises-in-swift)

## #98 使用自定义异常处理器

---

**_All rights reserved by [JohnSundell/SwiftTips](https://github.com/johnsundell/swifttips)._**
