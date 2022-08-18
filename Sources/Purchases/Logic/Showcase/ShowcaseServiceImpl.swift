//
//  ShowcaseService.swift
//  PaltaLibPayments
//
//  Created by Vyacheslav Beltyukov on 18/08/2022.
//

import PaltaLibCore

protocol ShowcaseService {
    func getProductIds(for userId: UserId, _ completion: @escaping (Result<Set<String>, PaymentsError>) -> Void)
}

final class ShowcaseServiceImpl: ShowcaseService {
    private let environment: Environment
    private let httpClient: HTTPClient
    
    init(environment: Environment, httpClient: HTTPClient) {
        self.environment = environment
        self.httpClient = httpClient
    }
    
    func getProductIds(for userId: UserId, _ completion: @escaping (Result<Set<String>, PaymentsError>) -> Void) {
        httpClient
            .perform(PaymentsHTTPRequest.getShowcase(environment, userId, nil)) { (result: Result<ShowcaseResponse, NetworkErrorWithoutResponse>) in
            completion(
                result
                    .map { Set($0.pricePoints.map { $0.appStoreId }) }
                    .mapError { PaymentsError(networkError: $0) }
            )
        }
    }
}
