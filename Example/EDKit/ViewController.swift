//
//  ViewController.swift
//  EDKit
//
//  Created by xue-nd on 09/21/2022.
//  Copyright (c) 2022 xue-nd. All rights reserved.
//

import UIKit
import EDKit
import Combine


class ViewController: UIViewController {
    
    lazy var myDataProvider = MyDataProvider()
    lazy var dataManager = PagingDataManager(startPage: 0, numberOfLoadsPerPage: 10, provider: myDataProvider)
    
    var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Logs.add(ConsoleLogger.shared)
        
//        dataManager.didBeginLoadingPublisher
//            .sink {
//                print("Begin load")
//            }
//            .store(in: &cancellables)
//
//        dataManager.didEndLoadingPublisher
//            .sink {
//                print("End load")
//            }
//            .store(in: &cancellables)
        
        dataManager.$data.didChange
            .sink { data in
//                print(data)
            }
            .store(in: &cancellables)
        
        dataManager.loadData(action: .refresh)
//        Queue.main.execute(.delay(2)) {
            self.dataManager.loadData(action: .clearAndRefresh)

//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func requestData(completionHandler: @escaping (Data) -> Void) async -> Bool {
        false
    }
}

final class MyDataProvider: PagingDataProviding {
    func requestToLoadData(atPage pageToLoad: Int, forManager manager: PagingDataManager<MyDataProvider>, request: inout Cancellable?) async throws -> (data: [String], isEndOfData: Bool) {
        print("Request")
        request = AnyCancellable {
        }
        
//        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 3)
        
        return (["A", "B", "C"], false)
    }
}
