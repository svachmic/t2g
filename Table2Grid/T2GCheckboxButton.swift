//
//  T2GCheckboxButton.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 01/04/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Base class for checkbox in editing mode (can be overriden).
*/
class T2GCheckboxButton: UIButton {
    let strokeColor = UIColor(named: .PYDOrange)
    var wasSelected: Bool = false {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    /**
    Custom draws the button based on property wasSelected.
    
    - parameter rect: Default Cocoa API - The portion of the view’s bounds that needs to be updated.
    */
    override func drawRect(rect: CGRect) {
        let lineWidth: CGFloat = self.wasSelected ? 4.0 : 3.0
        let fillColor = self.wasSelected ? UIColor.blackColor().CGColor : UIColor.clearColor().CGColor
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetLineWidth(context, lineWidth)
        CGContextAddArc(context, frame.size.width / 2, frame.size.height / 2, (frame.size.width - 10)/2, 0.0, CGFloat(M_PI * 2.0), 1)
        CGContextSetFillColorWithColor(context, fillColor)
        CGContextSetStrokeColorWithColor(context, self.strokeColor.CGColor)
        CGContextDrawPath(context, CGPathDrawingMode.FillStroke)
    }
    
    /**
    Overriden initializer that serves for setting up initial background color.
    
    - parameter frame: Default Cocoa API - The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
