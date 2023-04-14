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

class Owner: StateObservableObject {
    @StateObject var dog: Dog
    
    init(dog: Dog) {
        self.dog = dog
    }
}

class Dog: StateObservableObject {
    @EquatableState var name: String
    
    init(name: String) {
        self.name = name
    }
}

class ViewController: UIViewController, StateObservableObject {

    @State var isOpen: Bool = false
        
    @StateObject var owner: Owner = .init(dog: Dog(name: "bokita"))
    
    var cancellables: Set<AnyCancellable> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
             
        Queue.main.execute(.delay(1)) { [weak self] in
//            self?.isOpen = true
            self?.owner.dog.name = "bokita"
        }
    
        stateWillChange.sink { [weak self]  in
            guard let self = self else {
                return
            }
            print("will change \(self.owner.dog.name) \(self.isOpen)")
        }
        .store(in: &cancellables)
        
        stateDidChange.sink { [weak self]  in
            guard let self = self else {
                return
            }
            print("did change \(self.owner.dog.name) \(self.isOpen)")
        }
        .store(in: &cancellables)
                
//        exchangeImplementations(Human.self, originSelector: #selector(Human.walk), newSelector: #selector(Human.swizzle_walk))
//
//        overrideImplementation(Human.self, selector: #selector(Human.walk)) { originClass, originSelector, originIMPProvider in
//            return ({ (object: AnyObject) -> Void in
//                // call origin impl
//                let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector) -> Void).self)
//                oriIMP(object, originSelector)
//
//                print("has override walk method")
//            } as @convention(block) (AnyObject) -> Void)
//        }
//
//        overrideImplementation(Human.self, selector: #selector(Human.speak(_:))) { originClass, originSelector, originIMPProvider in
//            return ({ (object: AnyObject, words: String) -> Void in
//                if let human = object as? Human {
//                    // call origin impl
//                    let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector, String) -> Void).self)
//                    oriIMP(human, originSelector, words)
//
//                    print("has override speak method")
//                }
//            } as @convention(block) (AnyObject, String) -> Void)
//        }
//
//        overrideImplementation(Human.self, selector: #selector(Human.doWork(_:))) { originClass, originSelector, originIMPProvider in
//            return ({ (object: AnyObject, task: String) -> String in
//                // call origin impl
//                let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector, String) -> String).self)
//                let result = oriIMP(object, originSelector, task)
//
//                print("has override doWork method")
//
//                return result
//            } as @convention(block) (AnyObject, String) -> String)
//        }
        
//        Human().speak("123")
//        Human().walk()
//        Human().swizzle_walk()
//        print(Human().doWork("1236"))
        
//        Once.execute("123") {
//            print("123")
//        }
//
//        Once.execute("123") {
//            print("456")
//        }
        var set = WeakSet<Int>()
        
        let h1 = Human()
        let h2 = Human()
       
        set.insert(1)
        set.insert(2)
        
        print(set.weakReferenceCount)
        
        set.remove(1)
        set.remove(2)
        
        DispatchQueue.main.async {
            print(set.weakReferenceCount)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

class Human {
    
    @objc dynamic func walk() {
        print("Human walk")
    }
    
    @objc dynamic func swizzle_walk() {
        print("Human walk (swizzled)")
    }
    
    @objc dynamic func speak(_ words: String) {
        print(words)
    }
    
    @objc dynamic func doWork(_ task: String) -> String {
        if task.count > 5 {
            return "Human failed in task \(task)"
        } else {
            return"Human succeeded in task \(task)"
        }
    }
}

//class Man: Human {
//    override func walk() {
//        print("Man walk")
//    }
//}
