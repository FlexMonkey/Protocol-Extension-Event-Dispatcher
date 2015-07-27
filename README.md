# Protocol-Extension-Event-Dispatcher
## Implementation of EventDispatcher pattern using Swift Protocol Extensions

*This is the companion project to this blog post: http://flexmonkey.blogspot.com/2015/07/event-dispatching-in-swift-with.html*

One of the highlights for Swift 2.0 at WWDC was the introduction of protocol extensions: the ability to add default method implementations to protocols. Plenty has been written about protocol oriented programming in Swift since WWDC from bloggers such as SketchyTech, David Owens and Ray Wenderlich, and I thought it was high time to put my own spin on it.

After working with event dispatching in ActionScript for may years, protocol extensions seemed the perfect technique to implement a similar pattern in Swift. Indeed, protocol extensions offer the immediate advantage that I can add event dispatching to any type of object without the need for that object to extend a base class. For example, not only can user interface components dispatch events, but value objects and data structures can too: perfect for the MVVM pattern where a view may react to events on the view model to update itself. 

My project, Protocol Extension Event Dispatcher, contains a demonstration application containing a handful of user interface components: a slider, a stepper, a label and a button. There's a single 'model': an integer that dispatches a change event when its value changes via those components.  The end result is when the user interacts with any component, the entire user interface updates, via events, to reflect the change. 

This isn't meant to be a complete implementation of event dispatching in Swift, rather a demonstration of what's possible in Swift with protocol oriented programming. For a more complete version, take a look at ActionSwift. 

Let's take a look at how my code works. First of all, I have my protocol, EventDispatcher  which defines a handful of methods. It's a class protocol, because we want the dispatcher to be a single reference object:

```
    protocol EventDispatcher: class
    {
        func addEventListener(type: EventType, handler: EventHandler)
        
        func removeEventListener(type: EventType, handler: EventHandler)
        
        func dispatchEvent(event: Event)
    }
```

Each instance of an object that conforms to EventDispatcher will need a little repository of event listeners which I store as a dictionary with the event type as the key and a set of event handlers as the value.

The first stumbling block is that extensions may not contain stored properties. There are a few options to overcome this issue: I could create a global repository or I could use objc_getAssociatedObject and objc_setAssociatedObject. These functions all me to attach the event listeners to each EventDispatcher instance with some simple syntax. The code for my default implementation of addEventListener looks like:

```
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

}
```

For a given type and event handler, I check to see if there's an existing EventListeners object, if there is, I check to see if that object has an entry for the type and create or update values accordingly. Once I have my up-to-date EventListeners object, I can write it back with objc_setAssociatedObject.

In a similar fashion, for dispatchEvent()  I query for an associated object, check the handlers for the event type and execute them if there are any:

```
extension EventDispatcher
{
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
```

I've created a simple wrapper that utilises generics to allow any data type to dispatch an event when it changes:

```
class DispatchingValue: EventDispatcher
{
    required init(_ value: T)
    {
        self.value = value
    }
    
    var value: T
    {
        didSet
        {
            dispatchEvent(Event(type: EventType.change, target: self))
        }
    }
}
```

My demo application uses DispatchingValue to wrap an integer:

```
    let dispatchingValue = DispatchingValue(25)
```

...which updates the user interface controls when it changes by adding an event listener:

```
    let dispatchingValueChangeHandler = EventHandler(function: {
        (event: Event) in
        self.label.text = "\(self.dispatchingValue.value)"
        self.slider.value = Float(self.dispatchingValue.value)
        self.stepper.value = Double(self.dispatchingValue.value)
        })

    dispatchingValue.addEventListener(.change, handler: dispatchingValueChangeHandler)
```

I've also created an extension onto UIControl that makes all UI controls conform to EventDispatcher and dispatch change and tap events:

```
extension UIControl: EventDispatcher
{
    override public func didMoveToSuperview()
    {
        super.didMoveToSuperview()
        
        addTarget(self, action: "changeHandler", forControlEvents: UIControlEvents.ValueChanged)
        addTarget(self, action: "tapHandler", forControlEvents: UIControlEvents.TouchDown)
    }
    
    override public func removeFromSuperview()
    {
        super.removeFromSuperview()
        
        removeTarget(self, action: "changeHandler", forControlEvents: UIControlEvents.ValueChanged)
        removeTarget(self, action: "tapHandler", forControlEvents: UIControlEvents.TouchDown)
    }
    
    func changeHandler()
    {
        dispatchEvent(Event(type: EventType.change, target: self))
    }
    
    func tapHandler()
    {
        dispatchEvent(Event(type: EventType.tap, target: self))
    }
}
```

So, my slider, for example, can update dispatchingValue when the user changes its value:

```
    let sliderChangeHandler = EventHandler(function: {
        (event: Event) in
        self.dispatchingValue.value = Int(self.slider.value)
    })
    
    slider.addEventListener(.change, handler: sliderChangeHandler)
```

...which in turn will invoke dispatchingValueChangeHandler and update the other user interface components. My reset button sets the value of dispatchingValue to zero when tapped:

```
    let buttonTapHandler = EventHandler(function: {
        (event: Event) in
        self.dispatchingValue.value = 0
    })
    

    resetButton.addEventListener(.tap, handler: buttonTapHandler)
```

I hope this post gives a taste of the incredible power offered by protocol oriented programming. Once again, my project is available at my GitHub repository here. Enjoy!
