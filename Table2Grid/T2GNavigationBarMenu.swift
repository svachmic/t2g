//
//  T2GNavigationBarMenu.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 04/05/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Protocol for T2GNavigationBarMenu items' appearance and for handling clicking event.
*/
@objc protocol T2GNavigationBarMenuDelegate {
    /**
    Returns the height of the menu.
    */
    func heightForMenu() -> CGFloat
    
    /**
    Returns the number of cells in the menu.
    */
    func numberOfCells() -> Int
    
    /**
    Gets called when the menu is being created.
    
    - parameter index: Index of the cell in the menu. Indexed from 0 from the top.
    - parameter size: Size of the whole cell.
    - returns: UIView object that will be put as a subview of the button.
    */
    func viewForCell(index: Int, size: CGSize) -> UIView
    
    /**
    Gets called when a button has been pressed.
    
    - parameter index: Index of the selected button.
    */
    func didSelectButton(index: Int)
}

/**
Class for menu view sliding from below the navigation bar.
*/
class T2GNavigationBarMenu: UIView {
    var delegate: T2GNavigationBarMenuDelegate?
    
    /**
    Custom initializer - initializes the menu and creates all its subviews. If delegate isn't set the cells will be empty.
    
    - parameter frame: Default Cocoa API - The frame rectangle for the view, measured in points.
    - parameter itemCount: Expected number of items. Their size is calculated proportionally
    - parameter delegate: Delegate object that will determine appearance of the items in the menu and handle their events.
    */
    convenience init(frame: CGRect, delegate: T2GNavigationBarMenuDelegate?) {
        self.init(frame: frame)
        
        self.delegate = delegate
        let itemCount = self.delegate?.numberOfCells() ?? 0
        let itemHeight = frame.size.height / CGFloat(itemCount)
        
        for index in 0..<itemCount {
            let y = CGFloat(index) * itemHeight
            let button = T2GColoredButton(frame: CGRectMake(0, y, frame.size.width, itemHeight))
            button.normalBackgroundColor = .clearColor()
            button.highlightedBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
            button.tag = index
            button.addTarget(self, action: "buttonClicked:", forControlEvents: UIControlEvents.TouchUpInside)
            if let subview = self.delegate?.viewForCell(button.tag, size: button.frame.size) {
                subview.userInteractionEnabled = false
                subview.exclusiveTouch = false
                button.addSubview(subview)
            }
            self.addSubview(button)
            
            /// separators
            if index + 1 < itemCount {
                let offset: CGFloat = 30.0
                let line = UIView(frame: CGRectMake(offset, button.frame.origin.y + button.frame.size.height, button.frame.size.width - offset, 1))
                line.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
                self.addSubview(line)
            }
        }
    }
    
    /**
    Redirects button action to its delegate.
    
    - parameter sender: The button on which the action has been called.
    */
    internal func buttonClicked(sender: T2GColoredButton) {
        self.delegate?.didSelectButton(sender.tag)
    }
}
