//
//  T2GTriangleView.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 05/05/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Custom UIView class for animating triangle while animating the appearance of the navigation bar menu.
*/
class T2GTriangleView: UIView {

    /// overridden property to be able to distribute the change to the fill of the layer
    override var backgroundColor: UIColor? {
        get {
            return UIColor(cgColor: shapeLayer.fillColor!)
        }
        set {
            shapeLayer.fillColor = newValue!.cgColor
        }
    }
    
    /// custom calculated property for layer
    var shapeLayer: CAShapeLayer! {
        return self.layer as! CAShapeLayer
    }
    
    /**
    Sets custom class of the layer.
    
    - returns: Default Cocoa API - The class used to create the view’s Core Animation layer.
    */
    override class var layerClass : AnyClass {
        return TriangleLayer.self
    }
    
    //MARK: -
    /**
    Custom private shape layer class for animating the triangle with smooth transition.
    */
    class TriangleLayer: CAShapeLayer {
        override var bounds: CGRect {
            didSet {
                path = self.shapeForBounds(bounds).cgPath
            }
        }
        
        /**
        Creates the triangle shape for given rectangle. Created triangle always points down.
        
        - parameter rect: CGRect object to define the bounds where the triangle path should be drawn.
        - returns: UIBezierPath defining the path of the triangle.
        */
        func shapeForBounds(_ rect: CGRect) -> UIBezierPath {
            let point1 = CGPoint(x: rect.minX, y: rect.minY)
            let point2 = CGPoint(x: rect.midX, y: rect.maxY)
            let point3 = CGPoint(x: rect.maxX, y: rect.minY)
            
            let triangle = UIBezierPath()
            triangle.move(to: point1)
            triangle.addLine(to: point2)
            triangle.addLine(to: point3)
            triangle.close()
            return triangle
        }
        
        /**
        Overrides default behavior to be able to render the view when the frame gets changed.
        
        - parameter anim: Default Cocoa API - The animation to be added to the render tree.
        - parameter key: Default Cocoa API - A string that identifies the animation.
        */
        override func add(_ anim: CAAnimation, forKey key: String?) {
            super.add(anim, forKey: key)
            
            if (anim.isKind(of: CABasicAnimation.self)) {
                let basicAnimation = anim as! CABasicAnimation
                if (basicAnimation.keyPath == "bounds.size") {
                    let pathAnimation = basicAnimation.mutableCopy() as! CABasicAnimation
                    pathAnimation.keyPath = "path"
                    pathAnimation.fromValue = self.path
                    pathAnimation.toValue = self.shapeForBounds(self.bounds).cgPath
                    self.removeAnimation(forKey: "path")
                    self.add(pathAnimation,forKey: "path")
                }
            }
        }
    }
}
