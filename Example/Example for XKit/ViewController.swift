//
//  ViewController.swift
//  XKit
//
//  Created by xue-nd on 09/21/2022.
//  Copyright (c) 2022 xue-nd. All rights reserved.
//

import UIKit
import XKit
import Combine

class Person: StateObservableObject {
    
    @EquatableState
    var name: String = "Hi"
    
    @EquatableState
    var age: Int = 0
}

extension Person: CustomStringConvertible {
    
    var description: String {
        "\(name) : \(age)"
    }
    
}

class ViewController: UIViewController {
        
    let tuple = (1, 2)

    private let person = Person()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        person.stateWillChange
//            .sink { [weak self] in
//                guard let self else { return }
//                
//                print("will change \(self.person)")
//            }
//            .store(in: &cancellables)
//
//        person.stateDidChange
//            .sink { [weak self] in
//                guard let self else { return }
//                
//                print("did change \(self.person)")
//            }
//            .store(in: &cancellables)
//        
//        person.$name.didChange
//            .sink { name in
//                print("name -> \(name)")
//            }
//            .store(in: &cancellables)
//        
//        person.$age.didChange
//            .sink { age in
//                print("age -> \(age)")
//            }
//            .store(in: &cancellables)
//        
//        person.performBatchStateUpdates {
//            $0.name = "Hello"
//            $0.age = 100
//        }
//
        
//        let behavior: RetryDelayBehavior = .exponential(initial: 1, multiplier: 0.5)
//
//        let delayOptions = RetryDelayOptions(scheduler: RunLoop.main, behavior: behavior)
//       
//        Deferred {
//            Future<String, NSError> { promise in
//                promise(.failure(NSError(domain: "Retry", code: 0)))
//            }
//        }
//        .retry(10, delayOptions: delayOptions) { error, triesAlready in
//            print("will retry \(triesAlready) \(Int(NSDate().timeIntervalSince1970))")
//            
//            return true
//        }
//        .sink { completion in
//            switch completion {
//            case .failure(let error):
//                print("error \(error)")
//            case .finished:
//                print("finished")
//            }
//        } receiveValue: { output in
//            print("output \(output)")
//        }
//        .store(in: &cancellables)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func requestData(completionHandler: @escaping (Data) -> Void) async -> Bool {
        false
    }
    

}

