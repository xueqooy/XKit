//
//  PagingDataManager.swift
//  XKit
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
    
    public enum Status {
        case idle
        case loading
        case success
        case failure(Error)
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
    
    @State
    public private(set) var status: Status = .idle
    
    public var isDataEmpty: Bool {
        data.isEmpty
    }
        
    public let startPage: Int
    public let numberOfLoadsPerPage: Int
    public let provider: Provider
    public let clearDataWhenFailure: Bool

    private var currentLoadRequest: Cancellable?
    private var currentTaskId: UUID?
        
    public init(startPage: Int, numberOfLoadsPerPage: Int, provider: Provider, clearDataWhenFailure: Bool = false, debugName: String? = nil) {
        self.startPage = startPage
        self.numberOfLoadsPerPage = numberOfLoadsPerPage
        self.provider = provider
        self.clearDataWhenFailure = clearDataWhenFailure
        self.debugName = debugName
    }
    
    @discardableResult
    public func loadData(action: Action = .refresh) -> Bool {
        let taskId = UUID()
        self.currentTaskId = taskId
        
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
        status = .loading
        currentLoadRequest = provider.requestToLoadData(atPage: pageToLoad, forManager: self) { [weak self] result in
            guard let self, self.currentTaskId == taskId else { return }
            
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
                
                self.status = .success
                
                Logs.info("\(self) \(action) -> data did load +\(data.count)", tag: debugName)
            case .failure(let error):
                guard !error.isCancelled else { return }
                            
                if self.clearDataWhenFailure {
                    self.data = []
                    self.currentPage = nil
                    self.isEndOfData = false
                    self.canLoadMore = false
                } else {
                    // Enable load more if has more data and loaded data
                    self.canLoadMore = !self.isEndOfData && !self.isDataEmpty
                }
                
                self.status = .failure(error)
                
                Logs.error("\(self) \(action) -> load data error \(error)", tag: debugName)
            }
        }
        
        return true
    }
    
    public func cancelCurrentLoadRequest() {
        currentTaskId = nil
        currentLoadRequest?.cancel()
    }
    
    public func reset() {
        performBatchStateUpdates {
            $0.cancelCurrentLoadRequest()
            $0.canLoadMore = false
            $0.currentPage = nil
            $0.isEndOfData = false
            $0.data = []
            $0.status = .idle
        }
    }
}


extension PagingDataManager: CustomStringConvertible {
    public var description: String {
        "[data: \(data.count), currentPage: \(currentPage ?? 0), canLoadMore: \(canLoadMore), isEndOfData: \(isEndOfData)]"
    }
}
