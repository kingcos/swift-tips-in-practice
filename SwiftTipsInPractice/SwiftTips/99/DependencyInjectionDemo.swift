//
//  DependencyInjectionDemo.swift
//  SwiftTipsInPractice
//
//  Created by kingcos on 2019/8/29.
//  Copyright © 2019 kingcos. All rights reserved.
//
// #99 使用函数进行依赖注入
//

import Foundation

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
