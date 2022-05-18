//
//  EventQueueAssemblyTests.swift
//  PaltaLibAnalytics
//
//  Created by Vyacheslav Beltyukov on 18/05/2022.
//

import Foundation
import XCTest
import PaltaLibCore
@testable import PaltaLibAnalytics

final class EventQueueAssemblyTests: XCTestCase {
    var assembly: EventQueueAssembly!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        assembly = EventQueueAssembly(
            coreAssembly: CoreAssembly(),
            analyticsCoreAssembly: AnalyticsCoreAssembly(coreAssembly: CoreAssembly())
        )
    }
    
    func testApplyTarget() {
        let target = ConfigTarget(
            name: .amplitude,
            sendMechanism: .paltaBrain,
            settings: ConfigSettings(
                eventUploadThreshold: 98,
                eventUploadMaxBatchSize: 234,
                eventMaxCount: 12,
                eventUploadPeriodSeconds: 15,
                minTimeBetweenSessionsMillis: 87,
                trackingSessionEvents: true,
                realtimeEventTypes: ["real-time"],
                excludedEventTypes: ["excluded-event"]
            ),
            url: URL(string: "http://example.com")
        )
        
        assembly.apply(target)
        
        XCTAssertEqual(assembly.eventQueueCore.config?.uploadThreshold, 98)
        XCTAssertEqual(assembly.eventQueueCore.config?.maxBatchSize, 234)
        XCTAssertEqual(assembly.eventQueueCore.config?.maxEvents, 12)
        XCTAssertEqual(assembly.eventQueueCore.config?.uploadInterval, 15)
        XCTAssertEqual(assembly.sessionManager.maxSessionAge, 87)
//        XCTAssertEqual(assembly.sessionManager.trackingSessionEvents, true)
        XCTAssertEqual(assembly.eventQueue.excludedEvents, ["excluded-event"])
        XCTAssertEqual(assembly.eventQueue.liveEventTypes, ["real-time"])
        
        XCTAssertEqual(assembly.eventSender.baseURL, URL(string: "http://example.com"))
    }
}
