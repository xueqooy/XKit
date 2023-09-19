//
//  PagingDataManager.swift
//  EDKit
//
//  Created by xueqooy on 2023/9/12.
//

import Foundation
import Combine

public protocol PagingDataProviding {
    associatedtype DataType
    
    func requestToLoadData(atPage pageToLoad: Int, forManager manager: PagingDataManager<Self>, completionHandler: @escaping (Result<(data: [DataType], isEndOfData: Bool), Error>) -> Void) -> Cancellable?
}

/// Manage paging loaded data, so that we only need to focus on data request.
public class PagingDataManager<Provider: PagingDataProviding>: StateObservableObject {
    
    public enum Action: String {
        case refresh // Reload data but not clear loaded data
        case clearAndRefresh // Clear and reload data
        case loadMore // Load more data
    }
    
    public typealias DataType = Provider.DataType
                
    public var debugName: String?
    
    @State
    public var data: [DataType] = []
    
    @EquatableState
    public private(set) var canLoadMore: Bool = false
    
    @EquatableState
    public private(set) var currentPage: Int?

    @EquatableState
    public private(set) var isEndOfData: Bool = false
    
    public var isDataEmpty: Bool {
        data.isEmpty
    }
        
    public var didBeginLoadingPublisher: AnyPublisher<Void, Never> {
        didBeginLoadingSubject.eraseToAnyPublisher()
    }
    public var didEndLoadingPublisher: AnyPublisher<Void, Never> {
        didEndLoadingSubject.eraseToAnyPublisher()
    }
    private let didBeginLoadingSubject = PassthroughSubject<Void, Never>()
    private let didEndLoadingSubject = PassthroughSubject<Void, Never>()
    
    public let startPage: Int
    public let numberOfLoadsPerPage: Int
    public let provider: Provider
    
    private var currentLoadRequest: Cancellable?
    
    public init(startPage: Int, numberOfLoadsPerPage: Int, provider: Provider, debugName: String? = nil) {
        self.startPage = startPage
        self.numberOfLoadsPerPage = numberOfLoadsPerPage
        self.provider = provider
        self.debugName = debugName
    }
    
    @discardableResult
    public func loadData(action: Action = .refresh) -> Bool {
        if action == .loadMore && !canLoadMore {
            Logs.error("\(self) -> Load more is disabled [\(self)]", tag: debugName)
            return false
        }
        
        let requireFirstPage: Bool
        switch action {
        case .clearAndRefresh:
            requireFirstPage = true

            // Clear data before load
            data = []
            
            // Disable load more after clearing data
            canLoadMore = false
            
            // Reset isEndOfData
            isEndOfData = false
    
        case .refresh:
            requireFirstPage = true
            
            // Enable load more if has more data and loaded data when refreshing
            canLoadMore = !isEndOfData && !isDataEmpty
            
            // Reset isEndOfData
            isEndOfData = false
            
        case .loadMore:
            requireFirstPage = false
            
            // Disable load more when loading more data
            canLoadMore = false
        }
        
        var pageToLoad: Int = startPage
        if !requireFirstPage, let currentPage = currentPage {
            pageToLoad = currentPage + 1
        }
        
        // Cancel previous request
        currentLoadRequest?.cancel()
        currentLoadRequest = nil
        
        Logs.info("\(self) \(action) -> request to load page \(pageToLoad)", tag: debugName)
        
        // Start new request
        didBeginLoadingSubject.send()
        currentLoadRequest = provider.requestToLoadData(atPage: pageToLoad, forManager: self) { [weak self] result in
            guard let self = self else { return }
            
            self.currentLoadRequest = nil
            
            switch result {
            case .success((let data, let isEndOfData)):
                switch action {
                case .refresh, .clearAndRefresh:
                    self.data = data
                case .loadMore:
                    self.data.append(contentsOf: data)
                }
                
                self.isEndOfData = isEndOfData
                self.currentPage = pageToLoad
                
                // Enable load more if has more data
                self.canLoadMore = !isEndOfData
                
                self.didEndLoadingSubject.send()
                
                Logs.info("\(self) \(action) -> data did load +\(data.count)", tag: debugName)
            case .failure(let error):
                guard !error.isCancelled else { return }
                            
                // Enable load more if has more data and loaded data
                self.canLoadMore = !self.isEndOfData && !self.isDataEmpty
                
                self.didEndLoadingSubject.send()
                
                Logs.error("\(self) \(action) -> load data error \(error)", tag: debugName)
            }
        }
        
        return true
    }
    
    public func cancelCurrentLoadRequest() {
        currentLoadRequest?.cancel()
    }
}


extension PagingDataManager: CustomStringConvertible {
    public var description: String {
        "[data: \(data.count), currentPage: \(currentPage ?? 0), canLoadMore: \(canLoadMore), isEndOfData: \(isEndOfData)]"
    }
}
