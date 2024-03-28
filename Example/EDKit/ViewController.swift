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
        
    private let person = Person()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        person.stateWillChange
            .sink { [weak self] in
                guard let self else { return }
                
                print("will change \(self.person)")
            }
            .store(in: &cancellables)

        person.stateDidChange
            .sink { [weak self] in
                guard let self else { return }
                
                print("did change \(self.person)")
            }
            .store(in: &cancellables)
        
        person.$name.didChange
            .sink { name in
                print("name -> \(name)")
            }
            .store(in: &cancellables)
        
        person.$age.didChange
            .sink { age in
                print("age -> \(age)")
            }
            .store(in: &cancellables)
        
        person.performBatchStateUpdates {
            $0.name = "Hello"
            $0.age = 100
        }
        
//        person.name = "Hello"
//        person.age = 100
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func requestData(completionHandler: @escaping (Data) -> Void) async -> Bool {
        false
    }
}
