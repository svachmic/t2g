//
//  T2GCellButton.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 24/03/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


/**
Base class for drawer buttons (can be overriden). Implements resizing based on how much the scrollView in T2GCell is opened.
*/
class T2GCellDrawerButton: T2GColoredButton {
    var minOriginCoord: CGPoint?
    var maxOriginCoord: CGPoint? {
        get {
            return CGPoint(x: minOriginCoord!.x - (minSize! / 2), y: minOriginCoord!.y - (minSize! / 2))
        }
    }
    
    var minSize: CGFloat?
    var maxSize: CGFloat? {
        get {
            return 2 * minSize!
        }
    }
    
    /**
    Overriden initializer that serves for setting up initial values of minSize and minOriginCoord (that serves for calculated property maxOriginCoord).
    
    - parameter frame: Default Cocoa API - The frame rectangle, which describes the view’s location and size in its superview’s coordinate system.
    */
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.minSize = frame.size.width
        self.minOriginCoord = frame.origin
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
    Resizes the button while scrollView is scrolling. Increases size while going left on the X axis and decreases while going right.
    
    - parameter tailPosition: The X coordinate of the tip of the tail of the T2GCell that is being scrolled.
    - parameter sizeDifference: The difference of how much it moved since this method has been called last time. The method automatically adjusts if the value is out of bounds.
    */
    func resize(_ tailPosition: CGFloat, sizeDifference: CGFloat) {
        let size = self.frame.size.width
        
        /// The '+ (size - 4)' is there because in case the tail is moving left, then the button is smaller and we want it to start getting bigger a brief moment before it actually appears.
        let didBeginOverlapping = tailPosition < self.frame.origin.x + (size - 4)
        let isStillOverlapping = tailPosition > self.frame.origin.x
        
        if didBeginOverlapping && isStillOverlapping {
            var newSize = size + sizeDifference
            var newX = self.frame.origin.x - (sizeDifference / 2)
            var newY = self.frame.origin.y - (sizeDifference / 2)
            
            if newSize > self.maxSize {
                newX = self.maxOriginCoord!.x
                newY = self.maxOriginCoord!.y
                newSize = self.maxSize!
            } else if newSize < self.minSize {
                newX = self.minOriginCoord!.x
                newY = self.minOriginCoord!.y
                newSize = self.minSize!
            }
            
            self.frame = CGRect(x: newX, y: newY, width: newSize, height: newSize)
        } else {
            let isFarOut = tailPosition < self.frame.origin.x
            if isFarOut && size < self.maxSize {
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    self.frame = CGRect(x: self.maxOriginCoord!.x, y: self.maxOriginCoord!.y, width: self.maxSize!, height: self.maxSize!)
                })
            }
            
            let isFarOverlapped = tailPosition > self.frame.origin.x + size
            if isFarOverlapped && size > self.minSize {
                self.frame = CGRect(x: self.minOriginCoord!.x, y: self.minOriginCoord!.y, width: self.minSize!, height: self.minSize!)
            }
        }
    }
}
