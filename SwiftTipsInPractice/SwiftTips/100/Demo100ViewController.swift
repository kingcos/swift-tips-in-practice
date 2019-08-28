//
//  Demo100ViewController.swift
//  SwiftTipsInPractice
//
//  Created by kingcos on 2019/8/29.
//  Copyright © 2019 kingcos. All rights reserved.
//
// #100 函数绑定值
//

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
