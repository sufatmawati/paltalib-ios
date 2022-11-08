//
//  AppstoreProductService.swift
//  PaltaLibPayments
//
//  Created by Vyacheslav Beltyukov on 18/08/2022.
//

import Foundation
import StoreKit

protocol AppstoreProductService {
    func retrieveProducts(with ids: Set<String>, pricePoints: [String: [PricePoint]], completion: @escaping (Result<[Product], PaymentsError>) -> Void)
}

final class AppstoreProductServiceImpl: AppstoreProductService {
    private var pendingRequests: [RequestHandler] = []
    
    private let mapper: AppstoreProductMapper
    
    init(mapper: AppstoreProductMapper) {
        self.mapper = mapper
    }
    
    func retrieveProducts(with ids: Set<String>, pricePoints: [String: [PricePoint]], completion: @escaping (Result<[Product], PaymentsError>) -> Void) {
        let request = SKProductsRequest(productIdentifiers: ids)
        let handler = RequestHandler(request: request, pricePoints: pricePoints, mapper: mapper) { [unowned self] in
            pendingRequests.removeAll(where: { $0.request == request })
            completion($0)
        }
        pendingRequests.append(handler)
    }
}

private final class RequestHandler: NSObject, SKProductsRequestDelegate {
    private let timeoutInterval: TimeInterval = 10

    let request: SKProductsRequest
    private let pricePoints: [String: [PricePoint]]
    private let mapper: AppstoreProductMapper
    private let completion: (Result<[Product], PaymentsError>) -> Void
    
    private let lock = NSRecursiveLock()
    private var timeoutTask: DispatchWorkItem?
    private var isCompleted = false
    
    init(
        request: SKProductsRequest,
        pricePoints: [String: [PricePoint]],
        mapper: AppstoreProductMapper,
        completion: @escaping (Result<[Product], PaymentsError>) -> Void
    ) {
        self.request = request
        self.pricePoints = pricePoints
        self.mapper = mapper
        self.completion = completion
        
        super.init()
        
        request.delegate = self
        request.start()
        
        scheduleTimeout()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isCompleted else {
            return
        }
        
        completion(
            .success(
                response.products.flatMap { mapper.map($0, pricePoints: pricePoints) }
            )
        )
        
        isCompleted = true
        timeoutTask?.cancel()
        timeoutTask = nil
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isCompleted else {
            return
        }
        
        let code = (error as? SKError)?.code
        
        completion(.failure(.storeKitError(code)))
        
        isCompleted = true
        timeoutTask?.cancel()
        timeoutTask = nil
    }
    
    private func scheduleTimeout() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.cancel()
        }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
        timeoutTask = workItem
    }
    
    private func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        guard !isCompleted else {
            return
        }
        
        completion(.failure(.timedOut))
        
        isCompleted = true
        timeoutTask = nil
    }
}
