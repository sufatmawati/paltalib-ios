//
//  FeaturesServiceTests.swift
//  PaltaLibTests
//
//  Created by Vyacheslav Beltyukov on 20/05/2022.
//

import Foundation
import XCTest
@testable import PaltaLibPayments

final class FeaturesServiceTests: XCTestCase {
    var service: FeaturesServiceImpl!
    var httpMock: HTTPClientMock!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        httpMock = .init()
        service = .init(environment: .dev, httpClient: httpMock)
    }
    
    func testSuccess() {
        let uuid = UUID()
        let expectedFeatures = [Feature.mock()]
        let completionCalled = expectation(description: "Success called")
        
        httpMock.result = .success(FeaturesResponse(features: expectedFeatures))
        
        service.getFeatures(for: .uuid(uuid)) { result in
            guard case let .success(features) = result else {
                return
            }
            
            XCTAssertEqual(features, expectedFeatures)
            
            completionCalled.fulfill()
        }
        
        XCTAssertEqual((httpMock.request as? PaymentsHTTPRequest)?.endpoint, .getFeatures(.uuid(uuid)))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testFail() {
        let uuid = UUID()
        let expectedFeatures = [Feature.mock()]
        let completionCalled = expectation(description: "Fail called")
        
        httpMock.result = .success(FeaturesResponse(features: expectedFeatures))
        
        service.getFeatures(for: .uuid(uuid)) { result in
            guard case let .success(features) = result else {
                return
            }
            
            XCTAssertEqual(features, expectedFeatures)
            
            completionCalled.fulfill()
        }
        
        XCTAssertEqual((httpMock.request as? PaymentsHTTPRequest)?.endpoint, .getFeatures(.uuid(uuid)))
        
        wait(for: [completionCalled], timeout: 0.1)
    }
    
    func testDevEnvironment() {
        service = FeaturesServiceImpl(environment: .dev, httpClient: httpMock)
        
        service.getFeatures(for: .uuid(.init())) { _ in }
        
        guard
            let request = httpMock.request as? PaymentsHTTPRequest
        else {
            XCTAssert(false)
            return
        }
        
        XCTAssertEqual(request.environment, .dev)
    }
    
    func testProdEnvironment() {
        service = FeaturesServiceImpl(environment: .prod, httpClient: httpMock)
        
        service.getFeatures(for: .uuid(.init())) { _ in }
        
        guard
            let request = httpMock.request as? PaymentsHTTPRequest
        else {
            XCTAssert(false)
            return
        }
        
        XCTAssertEqual(request.environment, .prod)
    }
}
