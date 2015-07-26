//
//  ViewController.swift
//  EventDispatcher
//
//  Created by Simon Gladman on 24/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        var testFoo: TestFoo? = TestFoo()
        
        let stringChangeHandler = EventHandler(function: {
            (event: Event) in
            print("hello from string change handler! \((event.target as! DispatchingString).string)")
        })
        
        let testFooEventHandler = EventHandler(function: testFoo!.stringChangeHandler)
        
        let string = DispatchingString()
        string.addEventListener(.change, handler: stringChangeHandler)
        string.addEventListener(.change, handler: testFooEventHandler)
        
        string.string = "Simon"
        
        testFoo = nil
        
        string.string = "Simon Gladman"

        
        string.removeEventListener(.change, handler: stringChangeHandler)

        
        string.string = "Simon XXX"
        
                string.removeEventListener(.change, handler: testFooEventHandler)
        
        string.string = "Simon YYY"
        
    }



}

// -------

class TestFoo
{
    func stringChangeHandler(event: Event)
    {
        print("test foo! string change handler! \((event.target as! DispatchingString).string)")
    }
    
    deinit
    {
        print ("test foo deinit")
    }
}

// -------

class DispatchingString: EventDispatcher
{
    var string: String = ""
    {
        didSet
        {
            dispatchEvent(Event(type: EventType.change, target: self))
        }
    }
}

// -------

protocol EventDispatcher: class
{
    func addEventListener(type: EventType, handler: EventHandler)
    
    func removeEventListener(type: EventType, handler: EventHandler)
    
    func dispatchEvent(event: Event)
}

extension EventDispatcher
{
    func addEventListener(type: EventType, handler: EventHandler)
    {
        var eventListeners: EventListeners
        
        if let el = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners
        {
            eventListeners = el
            
            if let _ = eventListeners.listeners[type]
            {
                eventListeners.listeners[type]?.insert(handler)
            }
            else
            {
                eventListeners.listeners[type] = Set<EventHandler>([handler])
            }
        }
        else
        {
            eventListeners = EventListeners()
            eventListeners.listeners[type] = Set<EventHandler>([handler])
        }
        
        objc_setAssociatedObject(self,
            &EventDispatcherKey.eventDispatcher,
            eventListeners,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func removeEventListener(type: EventType, handler: EventHandler)
    {
        guard let eventListeners = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners,
            _ = eventListeners.listeners[type]
            else
        {
            // no handler for this object / event type
            return
        }
        
        eventListeners.listeners[type]?.remove(handler)

        objc_setAssociatedObject(self,
            &EventDispatcherKey.eventDispatcher,
            eventListeners,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func dispatchEvent(event: Event)
    {
        guard let eventListeners = objc_getAssociatedObject(self, &EventDispatcherKey.eventDispatcher) as? EventListeners,
            handlers = eventListeners.listeners[event.type]
            else
        {
            // no handler for this object / event type
            return
        }
        
        for handler in handlers
        {
            handler.function(event)
        }
    }

}

struct EventDispatcherKey
{
    static var eventDispatcher = "eventDispatcher"
}

struct EventHandler: Hashable
{
    let function: Event -> Void
    let id = NSUUID()
    
    var hashValue: Int
    {
        return id.hashValue
    }
}

func == (lhs: EventHandler, rhs: EventHandler) -> Bool
{
    return lhs.id == rhs.id
}

class EventListeners
{
    var listeners: [EventType: Set<EventHandler>] = [:]
}

struct Event
{
    let type: EventType
    let target: EventDispatcher
}

enum EventType: String
{
    case change
}