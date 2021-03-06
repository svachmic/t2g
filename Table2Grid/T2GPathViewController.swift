//
//  T2GPathViewController.swift
//  TabSplitView
//
//  Created by Michal Švácha on 07/05/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Protocol to inform that selection has been made and delegate should act accordingly (e.g. pop to selected ViewController).
*/
protocol T2GPathViewControllerDelegate {
    
    /**
    Gets called when prepended item is selected. In some cases it could be desirable to pop all the way to the root and sometimes not - that's when this method comes in. Is called every time any prependable index is selected.
    
    - parameter index: Index of the prependable item.
    - returns: Boolean flag stating whether or not should the view hierarchy should be popped to its root.
    */
    func shouldPopToRootWhenPrependedIndexIsSelected(index: Int) -> Bool
    
    /**
    Gets called when prepended item gets selected.
    
    :index: Index of the prepended item.
    */
    func didSelectPrependedIndex(index: Int)
    
    /**
    Gets called when a row has been selected.
    
    - parameter index: Selected row in the table view.
    */
    func didSelectViewController(index: Int, completion: (() -> Void)?)
    
    /**
    Gets called when prepended index is selected and delegate does approve popping to root view controller. Returns optional closure to be performed when popping has ended.
    
    - returns: Optional closure.
    */
    func completionHandlerAfterRootViewControllerAppears() -> (() -> Void)?
}

/**
Custom UITableView controller for showing popover with path to current VC in the navigation controller stack.
*/
class T2GPathViewController: UITableViewController {
    var path = [[String : String]]()
    var pathDelegate: T2GPathViewControllerDelegate?
    var prependedItemCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func viewDidAppear(animated: Bool) {
        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.path.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.path.count
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50.0
    }

    /**
    Sets up the cell. Last cell (currently active ViewController) is grayed out and prepended with '>' symbol to show that this is where the user currently is in the structure.
    */
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) 
        
        var text = self.path[indexPath.row]["name"]!
        if indexPath.row == self.path.count - 1 {
            text = "▸ \(text)" // ▶ ▸
            cell.textLabel?.textColor = .lightGrayColor()
        } else {
            cell.textLabel?.textColor = .blackColor()
        }
        
        cell.textLabel?.text = text
        
        let image = UIImage(named: self.path[indexPath.row]["image"]!) ?? self.imageWithColor(.blackColor(), rect: CGRectMake(0, 0, 32, 32))
        cell.imageView?.image = image
        return cell
    }
    
    /**
    Calls delegate method didSelectViewController with given index.
    
    - DISCUSSION: Needs to handle indices 0 and 1 as they are too proprietary for Pydio use.
    
    - parameter tableView: Default Cocoa API - A table-view object informing the delegate about the new row selection.
    - parameter indexPath: Default Cocoa API - An index path locating the new selected row in tableView.
    */
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if let delegate = self.pathDelegate {
            if indexPath.row > self.prependedItemCount - 1 {
                let vcIndex = indexPath.row - self.prependedItemCount
                delegate.didSelectViewController(vcIndex, completion: nil)
            } else {
                delegate.didSelectPrependedIndex(indexPath.row)
                
                if delegate.shouldPopToRootWhenPrependedIndexIsSelected(indexPath.row) {
                    delegate.didSelectViewController(0, completion: delegate.completionHandlerAfterRootViewControllerAppears())
                }
            }
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /**
    Highlights every row except for the one that represents currently active ViewController.
    
    - parameter tableView: Default Cocoa API - The table-view object that is making this request.
    - parameter indexPath: Default Cocoa API - The index path of the row being highlighted.
    - returns: Boolean value indicating whether or not highlight selected row.
    */
    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row != self.path.count - 1
    }
    
    /**
    Returns an image for given CGRect filled with given UIColor.
    
    - DISCUSSION: Is used only when the image mentioned in the path object is not present.
    
    - parameter color: UICOlor object
    - parameter rect: CGRect object giving exact size of the UIImage.
    - returns: UIImage with given color and size.
    */
    func imageWithColor(color: UIColor, rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContext(rect.size)
        let context: CGContextRef = UIGraphicsGetCurrentContext()!
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
