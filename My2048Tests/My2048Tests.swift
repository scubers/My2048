//
//  My2048Tests.swift
//  My2048Tests
//
//  Created by JMacMini on 16/4/29.
//  Copyright © 2016年 Jrwong. All rights reserved.
//

import XCTest
@testable import My2048

class My2048Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRightUpCoordinate() {
        let d = 4
        let count = d * 2 - 1
        print("count: \(count)")
        for i in 0..<count {
            let subCount = (d - 1) - abs(d - 1 - i)
            var string: String = ""
            for j in 0...subCount {
                let col = min(d - 1, i) - j
                let row = max(i - d + 1, 0) + j
                string += " (\(col), \(row))"
            }
            print(string)
        }
    }
    func testLeftUpCoordinate() {
        let d = 4
        let count = d * 2 - 1
        print("count: \(count)")
        for i in 0..<count {
            let subCount = (d - 1) - abs(d - 1 - i)
            var string: String = ""
            for j in 0...subCount {
                let col = max(d - i - 1, 0) + j
                let row = max(i - d + 1, 0) + j
                string += " (\(col), \(row))"
            }
            print(string)
        }
    }

    func testRightDownCoordinate() {
        let d = 4
        let count = d * 2 - 1
        print("count: \(count)")
        for i in 0..<count {
            let subCount = (d - 1) - abs(d - 1 - i)
            var string: String = ""
            for j in 0...subCount {
                let col = min(2 * (d - 1) - i, d - 1) - j
                let row = min(i, d - 1) - j
                string += " (\(col), \(row))"
            }
            print(string)
        }
    }

    func testLeftDownCoordinate() {
        let d = 4
        let count = d * 2 - 1
        print("count: \(count)")
        for i in 0..<count {
            let subCount = (d - 1) - abs(d - 1 - i)
            var string: String = ""
            for j in 0...subCount {
                let col = min(i - d + 1, d - 1) + j
                let row = min(i, d - 1) - j
                string += " (\(col), \(row))"
            }
            print(string)
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
