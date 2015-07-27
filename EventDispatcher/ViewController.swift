//
//  ViewController.swift
//  EventDispatcher
//
//  Created by Simon Gladman on 24/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    let mainGroup = UIStackView()
    
    let stepper = UIStepper()
    let slider = UISlider()
    let resetButton = UIButton()
    let label = UILabel()
    
    let dispatchingValue = DispatchingValue(25)
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // set up user interface...
        
        view.addSubview(mainGroup)
        
        mainGroup.axis = UILayoutConstraintAxis.Vertical
        mainGroup.distribution = UIStackViewDistribution.EqualSpacing
        
        mainGroup.addArrangedSubview(label)
        mainGroup.addArrangedSubview(stepper)
        mainGroup.addArrangedSubview(slider)
        mainGroup.addArrangedSubview(resetButton)
        
        // dispatchingValue...
        
        let dispatchingValueChangeHandler = EventHandler(function: {
            (event: Event) in
            self.label.text = "\(self.dispatchingValue.value)"
            self.slider.value = Float(self.dispatchingValue.value)
            self.stepper.value = Double(self.dispatchingValue.value)
            })
        
        dispatchingValue.addEventListener(.change, handler: dispatchingValueChangeHandler)
        
        // reset button...
        
        resetButton.setTitle("Reset to Zero", forState: UIControlState.Normal)
        resetButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)

        let buttonTapHandler = EventHandler(function: {
            (event: Event) in
            self.dispatchingValue.value = 0
        })
        
        resetButton.addEventListener(.tap, handler: buttonTapHandler)
        
        // stepper...
        
        stepper.minimumValue = 0
        stepper.maximumValue = 50
        stepper.value = Double(dispatchingValue.value)
        
        let stepperChangeHandler = EventHandler(function: {
            (event: Event) in
            self.dispatchingValue.value = Int(self.stepper.value)
        })
        
        stepper.addEventListener(.change, handler: stepperChangeHandler)
        
        // slider...
        
        slider.minimumValue = 0
        slider.maximumValue = 50
        slider.value = Float(dispatchingValue.value)
        
        let sliderChangeHandler = EventHandler(function: {
            (event: Event) in
            self.dispatchingValue.value = Int(self.slider.value)
        })
        
        slider.addEventListener(.change, handler: sliderChangeHandler)
        
        // label...
        
        label.text = "\(dispatchingValue.value)"
    }
    
    override func viewDidLayoutSubviews()
    {
        mainGroup.frame = view.frame.rectByInsetting(dx: 50, dy: 50)
    }

}

