//
//  sensmoveTests.swift
//  sensmoveTests
//
//  Created by RIEUX Alexandre on 13/03/2015.
//  Copyright (c) 2015 ___alexprod___. All rights reserved.
//

import UIKit
import XCTest

class sensmoveTests: XCTestCase {
    
    var user: SMUser?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func createUserAndSaveToKeychain() {

    }
    
    func getUser() {
        
    }
    
    func testExample() {
        var userDictionary = [
            "name": "Alexandre",
            "weight": 70,
            "height": 180,
            "doctor": "TestDoctor",
            "balance": "Great balance",
            "averageForceLeft": 120,
            "averageForceRight": 111
        ]
        self.user = SMUser.alloc()
        self.user?.initWithDictionary(userDictionary)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
