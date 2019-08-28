//
//  SwiftTipsInPracticeTests.swift
//  SwiftTipsInPracticeTests
//
//  Created by kingcos on 2019/8/29.
//  Copyright © 2019 kingcos. All rights reserved.
//
// #102 让异步测试执行更快更稳定
//

import XCTest

class SwiftTipsInPracticeTests: XCTestCase {
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
