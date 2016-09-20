//
//  T2GViewController.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 25/03/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Protocol for view controller delegate defining required methods to properly display all subviews and also to define action methods to be called when an event occurrs.
*/
protocol T2GViewControllerDelegate {
    /// View methods
    
    /**
    Creates and returns a T2GCell object ready to be put in the scrollView.
    
    - parameter indexPath: NSIndexPath object with precise location of the cell (row and section).
    - parameter frame: Expected frame for the cell.
    - returns:
    */
    func cellForIndexPath(_ indexPath: IndexPath, frame: CGRect) -> T2GCell
    
    /**
    Returns the header text for section delimiter.
    
    - parameter section: Integer value defining number of cells in given section.
    - returns: Optional String to be set in the UILabel of T2GDelimiterView
    */
    func titleForHeaderInSection(_ section: Int) -> String?
    
    /**
    Gets called when cell needs an update.
    
    - parameter cell: T2GCell view to be updated.
    - parameter indexPath: NSIndexPath object with precise location of the cell (row and section).
    */
    func updateCellForIndexPath(_ cell: T2GCell, indexPath: IndexPath)
    
    /// Action methods
    
    /**
    Gets called when cell is tapped.
    
    - parameter indexPath: NSIndexPath object with precise location of the cell (row and section).
    */
    func didSelectCellAtIndexPath(_ indexPath: IndexPath)
    
    /**
    Gets called when button in the drawer is tapped.
    
    - parameter indexPath: NSIndexPath object with precise location of the cell (row and section).
    - parameter buttonIndex: Index of the button in the drawer - indexed from right to left starting with 0.
    */
    func didSelectDrawerButtonAtIndex(_ indexPath: IndexPath, buttonIndex: Int)
    
    /**
    Gets called when a cell will be removed from the scrollView.
    
    - parameter NSIndexPath: object with precise location of the cell (row and section).
    */
    func willRemoveCellAtIndexPath(_ indexPath: IndexPath)
    
    /**
    Unused at the moment. Planned for future development.
    */
    func willSelectCellAtIndexPath(_ indexPath: IndexPath) -> IndexPath?
    
    /**
    Unused at the moment. Planned for future development.
    */
    func willDeselectCellAtIndexPath(_ indexPath: IndexPath) -> IndexPath?
    
    /**
    Unused at the moment. Planned for future development.
    */
    func didDeselectCellAtIndexPath(_ indexPath: IndexPath)
}

/**
Protocol for delegate handling drop event.
*/
protocol T2GDropDelegate {
    /**
    Gets called when a T2GCell gets dropped on top of another cell. This method should handle the event of success/failure.
    
    - parameter cell: Dragged cell.
    - parameter onCell: Cell on which the dragged cell has been dropped.
    - parameter completion: Completion closure to be performed in case the drop has been successful.
    - parameter failure: Failure closure to be performed in case the drop has not been successful.
    */
    func didDropCell(_ cell: T2GCell, onCell: T2GCell, completion: () -> Void, failure: () -> Void)
}

/**
Enum defining scrolling speed. Used for deciding how fast should rows be added in method addRowsWhileScrolling.
*/
private enum T2GScrollingSpeed {
    case slow
    case normal
    case fast
}

/**
Custom view controller class handling the whole T2G environment (meant to be overriden for customizations).
*/
class T2GViewController: T2GScrollController, T2GCellDelegate, T2GDragAndDropDelegate {
    var scrollView: T2GScrollView!
    var openCellTag: Int = -1
    
    var lastSpeedOffset: CGPoint = CGPoint(x: 0, y: 0)
    var lastSpeedOffsetCaptureTime: TimeInterval = 0
    
    var isEditingModeActive: Bool = false {
        didSet {
            if !self.isEditingModeActive {
                self.editingModeSelection = [Int : Bool]()
            }
        }
    }
    var editingModeSelection = [Int : Bool]()
    
    var delegate: T2GViewControllerDelegate! {
        didSet {
            var count = self.scrollView.visibleCellCount()
            let totalCells = self.scrollView.totalCellCount()
            count = count > totalCells ? totalCells : count
            
            for index in 0..<count {
                self.insertRowWithTag(index + T2GViewTags.cellConstant)
            }
            self.scrollView.adjustContentSize()
        }
    }

    var dropDelegate: T2GDropDelegate?
    
    /**
    Sets slight delay for VC push in case T2GNaviViewController is present. Then adds scrollView to the view with constraints such that the scrollView is always the same size as the superview.
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let navigationCtr = self.navigationController as? T2GNaviViewController {
            navigationCtr.segueDelay = 0.16
        }
        
        self.scrollView = T2GScrollView()
        //self.scrollView.delaysContentTouches = false
        self.scrollView.backgroundColor = UIColor(red: 238.0/255.0, green: 233.0/255.0, blue: 233/255.0, alpha: 1.0)
        self.view.addSubview(scrollView)
        
        // View must be added to hierarchy before setting constraints.
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["view": self.view, "scroll_view": scrollView]
        
        let constH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[scroll_view]|", options: .alignAllCenterY, metrics: nil, views: views)
        view.addConstraints(constH)
        
        let constW = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scroll_view]|", options: .alignAllCenterX, metrics: nil, views: views)
        view.addConstraints(constW)
    }
    
    /**
    Sets the scrollView delegate to be self. Makes sure that all cells that should be visible are visible. Also checks if T2GNavigationBarTitle is present to form appearance for Normal and Highlighted state.
    
    - parameter animated: Default Cocoa API - If YES, the view was added to the window using an animation.
    */
    override func viewDidAppear(_ animated: Bool) {
        self.scrollView.delegate = self
        self.displayMissingCells()
        self.scrollView.adjustContentSize()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
    Reloads the whole scrollView - does NOT delete everything, rather calls update on every visible cell.
    */
    func reloadScrollView() {
        for view in self.scrollView.subviews {
            if let cell = view as? T2GCell {
                self.delegate.updateCellForIndexPath(cell, indexPath: self.scrollView.indexPathForCell(cell.tag))
            }
        }
        
        self.displayMissingCells()
    }
    
    //MARK: - Editing mode
    
    /**
    Turns on editing mode - all cells are moved and displayed with checkbox button. Also a toolbar in the botom of the screen appears.
    
    - DISCUSSION: How to make this more modular and settable? Maybe another delegate method.
    */
    func toggleEdit() {
        if self.openCellTag != -1 {
            if let view = self.scrollView!.viewWithTag(self.openCellTag) as? T2GCell {
                view.closeCell()
            }
        }
        
        self.isEditingModeActive = !self.isEditingModeActive
        
        for view in self.scrollView.subviews {
            if let cell = view as? T2GCell {
                let isSelected = self.editingModeSelection[cell.tag - T2GViewTags.cellConstant] ?? false
                cell.toggleMultipleChoice(self.isEditingModeActive, mode: self.scrollView.layoutMode, selected: isSelected, animated: true)
            }
        }
        
        self.toggleToolbar()
    }
    
    /**
    Closes the cell at the given indexPath. Does nothing if the cell isn't visible anymore.
    
    - parameter indexPath: NSIndexPath of the given cell.
    */
    func closeCell(_ indexPath: IndexPath) {
        let index = self.scrollView.indexForIndexPath(indexPath)
        
        if let cell = self.scrollView.viewWithTag(index + T2GViewTags.cellConstant) as? T2GCell {
            cell.closeCell()
        }
    }
    
    /**
    Not implemented yet
    
    - DISCUSSION: This method probably shouldn't be here at all.
    */
    func moveBarButtonPressed() {
        print("Not implemented yet.")
    }
    
    /**
    Gets called when delete button in the toolbar has been pressed and therefore multiple rows should be deleted. Animates all the visible/potentinally visible after the animation, notifies the delegate before doing so to adjust the model so the new cell frames could be calculated.
    */
    func deleteBarButtonPressed() {
        var indexPaths: [IndexPath] = []
        
        for key in self.editingModeSelection.keys {
            if self.editingModeSelection[key] == true {
                indexPaths.append(self.scrollView.indexPathForCell(key + T2GViewTags.cellConstant))
            }
        }
        
        self.removeRowsAtIndexPaths(indexPaths.sorted{($0 as NSIndexPath).section == ($1 as NSIndexPath).section ? ($0 as NSIndexPath).row < ($1 as NSIndexPath).row : ($0 as NSIndexPath).section < ($1 as NSIndexPath).section}, notifyDelegate: true)
        self.editingModeSelection = [Int : Bool]()
    }
    
    /**
    Shows toolbar with Move and Delete buttons.
    
    - DISCUSSION: Another TODO for making it more modular.
    */
    func toggleToolbar() {
        if let bar = self.view.viewWithTag(T2GViewTags.editingModeToolbar) {
            bar.removeFromSuperview()
            self.scrollView.adjustContentSize()
        } else {
            let bar = UIToolbar(frame: CGRect(x: 0, y: self.view.frame.size.height - 44, width: self.view.frame.size.width, height: 44))
            bar.tag = T2GViewTags.editingModeToolbar
            bar.isTranslucent = false
            
            let leftItem = UIBarButtonItem(title: "Move", style: UIBarButtonItemStyle.plain, target: self, action: #selector(T2GViewController.moveBarButtonPressed))
            let rightItem = UIBarButtonItem(title: "Delete", style: UIBarButtonItemStyle.plain, target: self, action: #selector(T2GViewController.deleteBarButtonPressed))
            let space = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            bar.items = [leftItem, space, rightItem]
            
            self.scrollView.contentSize = CGSize(width: self.scrollView.contentSize.width, height: self.scrollView.contentSize.height + 44.0)
            bar.alpha = 0.0
            self.view.addSubview(bar)
            
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                bar.alpha = 1.0
            })
        }
    }
    
    //MARK: - CRUD methods
    
    /**
    Inserts delimiter for the given section.
    
    - parameter mode: T2GLayoutMode for which the delimiter's frame should be calculated.
    - parameter section: Integer value representing the section of the delimiter to ask for the title accordingly.
    */
    func insertDelimiterForSection(_ mode: T2GLayoutMode, section: Int) {
        if self.scrollView.viewWithTag(section + 1) as? T2GDelimiterView == nil {
            let name = self.delegate.titleForHeaderInSection(section) ?? ""
            
            let delimiter = T2GDelimiterView(frame: self.scrollView.frameForDelimiter(mode, section: section), title: name)
            delimiter.tag = section + 1
            
            self.scrollView.addSubview(delimiter)
        }
    }
    
    /**
    Inserts cell in given indexPath.
    
    - parameter indexPath:
    */
    func insertRowAtIndexPath(_ indexPath: IndexPath) {
        let totalIndex = self.scrollView.indexForIndexPath(indexPath)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            for cell in self.scrollView.subviews {
                if cell.tag >= (totalIndex + T2GViewTags.cellConstant) {
                    if let c = cell as? T2GCell {
                        let newFrame = self.scrollView.frameForCell(indexPath: self.scrollView.indexPathForCell(c.tag + 1))
                        c.frame = newFrame
                        c.tag = c.tag + 1
                        self.delegate.updateCellForIndexPath(c, indexPath: self.scrollView.indexPathForCell(c.tag))
                    }
                } else if let delimiter = cell as? T2GDelimiterView {
                    let frame = self.scrollView.frameForDelimiter(section: delimiter.tag - 1)
                    delimiter.frame = frame
                }
            }
        }, completion: { (_) -> Void in
            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                self.scrollView.adjustContentSize()
            }, completion: { (_) -> Void in
                _ = self.insertRowWithTag(totalIndex + T2GViewTags.cellConstant, animated: true)
                return
            })
        })
    }
    
    /**
    Inserts cell with given tag. Meant mainly for internal use as it is strongly advised not to use the internal tags.
    
    - parameter tag: Integer value representing the tag of the new cell.
    - parameter animated: Boolean flag determining if the cell should be added animated.
    - returns: Integer value representing the tag of the newly added cell.
    */
    fileprivate func insertRowWithTag(_ tag: Int, animated: Bool = false) -> Int {
        let indexPath = self.scrollView.indexPathForCell(tag)
        
        if (indexPath as NSIndexPath).row == 0 {
            self.insertDelimiterForSection(self.scrollView.layoutMode, section: (indexPath as NSIndexPath).section)
        }
        
        if let cell = self.scrollView.viewWithTag(tag) {
            return cell.tag
        } else {
            let frame = self.scrollView.frameForCell(indexPath: indexPath)
            let cellView = self.delegate.cellForIndexPath(indexPath, frame: frame)
            cellView.tag = tag
            
            if self.isEditingModeActive {
                let isSelected = self.editingModeSelection[cellView.tag - T2GViewTags.cellConstant] ?? false
                cellView.toggleMultipleChoice(true, mode: self.scrollView.layoutMode, selected: isSelected, animated: false)
            }
            
            let isDragged = self.view.viewWithTag(tag) != nil
            
            cellView.delegate = self
            cellView.alpha = (animated || isDragged) ? 0 : 1
            self.scrollView.addSubview(cellView)
            
            if animated && !isDragged {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    cellView.alpha = 1.0
                })
            }
            
            return cellView.tag
        }
    }
    
    /**
    Removes rows at given indexPaths. Used even for single row removal.
    
    - parameter indexPaths: Array of NSIndexPath objects defining the positions of the cells.
    - parameter notifyDelegate: Boolean flag saying whether or not the delegate should be notified about the removal - maybe the call was performed before the model has been adjusted.
    */
    func removeRowsAtIndexPaths(_ indexPaths: [IndexPath], notifyDelegate: Bool = false) {
        var indices: [Int] = []
        for indexPath in indexPaths {
            indices.append(self.scrollView.indexForIndexPath(indexPath))
        }
        
        UIView.animate(withDuration: 0.6, animations: { () -> Void in
            var removedCount = 0
            
            for idx in indices {
                if let view = self.scrollView!.viewWithTag(idx + T2GViewTags.cellConstant) as? T2GCell {
                    if notifyDelegate {
                        self.delegate.willRemoveCellAtIndexPath(self.scrollView.indexPathForCell(idx - removedCount + T2GViewTags.cellConstant))
                    }
                    
                    if self.openCellTag == view.tag {
                        view.closeCell()
                    }
                    
                    view.frame = CGRect(x: view.frame.origin.x - 40, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height)
                }
                removedCount += 1
            }
        }, completion: { (_) -> Void in
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                for idx in indices {
                    if let view = self.scrollView!.viewWithTag(idx + T2GViewTags.cellConstant) as? T2GCell {
                        view.frame = CGRect(x: self.scrollView.bounds.width + 40, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height)
                    }
                }   
            }, completion: { (_) -> Void in
                for idx in indices {
                    if let view = self.scrollView!.viewWithTag(idx + T2GViewTags.cellConstant) as? T2GCell {
                        view.removeFromSuperview()
                    }
                }
                
                var tags = self.scrollView.subviews.filter({$0 is T2GCell || $0 is T2GDelimiterView}).map({(subview) -> Int in return subview.tag})
                tags.sort(by: <)
                        
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    var changedCount = 0
                    for tag in tags {
                        let firstIP = indexPaths.first!
                        let idx = self.scrollView.indexForIndexPath(firstIP)
                        
                        if let cell = self.scrollView.viewWithTag(tag) {
                            if cell.tag > (idx + T2GViewTags.cellConstant) {
                                if let c = cell as? T2GCell {
                                    let newRowNum = idx + changedCount
                                    let newFrame = self.scrollView.frameForCell(indexPath: self.scrollView.indexPathForCell(newRowNum + T2GViewTags.cellConstant))
                                    c.frame = newFrame
                                    c.tag = newRowNum + T2GViewTags.cellConstant
                                    self.delegate.updateCellForIndexPath(c, indexPath: self.scrollView.indexPathForCell(c.tag))
                                    
                                    changedCount += 1
                                }
                            } else if let delimiter = cell as? T2GDelimiterView {
                                let frame = self.scrollView.frameForDelimiter(section: delimiter.tag - 1)
                                delimiter.frame = frame
                            }
                        }
                    }
                }, completion: { (_) -> Void in
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        self.scrollView.adjustContentSize()
                    }, completion: { (_) -> Void in
                        self.displayMissingCells()
                    })
                })
            })
        })
    }
    
    //MARK: - View transformation (Table <-> Collection)
    
    /**
    Wrapper around transformViewWithCompletion for UIBarButton implementation.
    */
    func transformView() {
        self.transformViewWithCompletion() { ()->Void in }
    }
    
    /**
    Rearranges the scrollView's layout.
    
    - DISCUSSION: Rearranging items when deep in view - the animation could be much nicer (sometimes, when deep in the view, tha animation makes everything "slide away" and then it magically shows everything that's supposed to be visible) - maybe scroll to point where the top item should be after the view is rearranged.
    
    - parameter completionClosure:
    */
    fileprivate func transformViewWithCompletion(_ completionClosure:@escaping () -> Void) {
        let collectionClosure = {() -> T2GLayoutMode in
            let indicesExtremes = self.scrollView.firstAndLastVisibleTags()
            var from = (indicesExtremes.highest) + 1
            
            if from > self.scrollView.totalCellCount() {
                from = self.scrollView.totalCellCount() - 1 + T2GViewTags.cellConstant
            }
            
            var to = (indicesExtremes.highest) + 10
            if to > self.scrollView.totalCellCount() {
                to = self.scrollView.totalCellCount() - 1 + T2GViewTags.cellConstant
            }
            
            
            for index in from...to {
                _ = self.insertRowWithTag(index)
            }
            
            return .collection
        }
        
        let mode = self.scrollView.layoutMode == .collection ? T2GLayoutMode.table : collectionClosure()
        self.scrollView.adjustContentSize(mode)
        self.displayMissingCells()
        self.displayMissingCells(mode)
        
        UIView.animate(withDuration: 0.8, animations: { () -> Void in
            
            for view in self.scrollView.subviews {
                if let cell = view as? T2GCell {
                    let frame = self.scrollView.frameForCell(mode, indexPath: self.scrollView.indexPathForCell(cell.tag))
                    
                    /*
                    * Not really working - TBD
                    *
                    if !didAdjustScrollview {
                    self.scrollView.scrollRectToVisible(CGRectMake(0, frame.origin.y - 12 - 64, self.scrollView.bounds.size.width, self.scrollView.bounds.size.height), animated: false)
                    didAdjustScrollview = true
                    }
                    */
                    
                    cell.changeFrameParadigm(mode, frame: frame)
                } else if let delimiter = view as? T2GDelimiterView {
                    let frame = self.scrollView.frameForDelimiter(mode, section: delimiter.tag - 1)
                    delimiter.frame = frame
                }
            }
            
            }, completion: { (_) -> Void in
                self.scrollView.performSubviewCleanup()
                self.displayMissingCells()
                completionClosure()
        }) 
        
        self.scrollView.layoutMode = mode
    }
    
    //MARK: - Rotation handler
    
    /**
    Makes sure that all subviews get properly resized (Table) or placed (Collection) during rotation. Forces navigation controller menu to close when opened.
    
    - parameter toInterfaceOrientation: Default Cocoa API - The new orientation for the user interface.
    - parameter duration: Default Cocoa API - The duration of the pending rotation, measured in seconds.
    */
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        super.willAnimateRotation(to: toInterfaceOrientation, duration: duration)
        
        if let navCtr = self.navigationController as? T2GNaviViewController {
            navCtr.toggleBarMenu(true)
        }
        
        let indicesExtremes = self.scrollView.firstAndLastVisibleTags()
        
        if indicesExtremes.lowest != Int.max || indicesExtremes.highest != Int.min {
            let from = (indicesExtremes.highest) + 1
            let to = (indicesExtremes.highest) + 10
            if (to - T2GViewTags.cellConstant) < self.scrollView.totalCellCount() {
                for index in from...to {
                    _ = self.insertRowWithTag(index)
                }
            }
            
            UIView.animate(withDuration: 0.8, animations: { () -> Void in
                if let bar = self.view.viewWithTag(T2GViewTags.editingModeToolbar) as? UIToolbar {
                    let height: CGFloat = UIInterfaceOrientationIsLandscape(toInterfaceOrientation) ? 35.0 : 44.0
                    bar.frame = CGRect(x: 0, y: self.view.frame.size.height - height, width: self.view.frame.size.width, height: height)
                }
                
                for view in self.scrollView.subviews {
                    if let cell = view as? T2GCell {
                        let frame = self.scrollView.frameForCell(indexPath: self.scrollView.indexPathForCell(cell.tag))
                        cell.changeFrameParadigm(self.scrollView.layoutMode, frame: frame)
                    } else if let delimiter = view as? T2GDelimiterView {
                        let frame = self.scrollView.frameForDelimiter(section: delimiter.tag - 1)
                        delimiter.frame = frame
                    }
                }
                
            }, completion: { (_) -> Void in
                self.scrollView.adjustContentSize()
                self.scrollView.performSubviewCleanup()
            }) 
        }
    }
    
    /**
    Makes sure to display all missing cells after the rotation ended.
    
    - parameter fromInterfaceOrientation: Default Cocoa API - The old orientation of the user interface.
    */
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.displayMissingCells()
    }
    
    //MARK: - ScrollView delegate
    
    /**
    Helper method after the scrollView has snapped back (most likely after UIRefreshControl has been pulled). The thing is, that performSubviewCleanup is usually called and the last cells could be missing because they go off-screen during UIRefreshControl's loading. This method makes sure that all cells are properly displayed afterwards.
    */
    override func handleSnapBack() {
        self.displayMissingCells()
    }
    
    /**
    Performs cleanup of all forgotten subviews that are off-screen.
    
    - parameter scrollView: Default Cocoa API - The scroll-view object in which the decelerating occurred.
    */
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollView.performSubviewCleanup()
    }
    
    /**
    If the view ended without decelaration it performs cleanup of subviews that are off-screen.
    
    - WARNING: Super must be called if hiding feature of T2GScrollController is desired.
    
    - parameter scrollView: Default Cocoa API - The scroll-view object that finished scrolling the content view.
    - parameter willDecelerate: Default Cocoa API - true if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
    */
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        
        if !decelerate {
            self.scrollView.performSubviewCleanup()
        }
    }
    
    /**
    Dynamically deletes and adds rows while scrolling.
    
    - WARNING: Super must be called if hiding feature of T2GScrollController is desired. Fix has been done to handle rotation, not sure what it will do when scrolling fast.
    
    - parameter scrollView: Default Cocoa API - The scroll-view object in which the scrolling occurred.
    */
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        let currentOffset = scrollView.contentOffset;
        let currentTime = Date.timeIntervalSinceReferenceDate
        var currentSpeed = T2GScrollingSpeed.slow
        
        if(currentTime - self.lastSpeedOffsetCaptureTime > 0.1) {
            let distance = currentOffset.y - self.lastSpeedOffset.y
            let scrollSpeed = fabsf(Float((distance * 10) / 1000))
            
            if (scrollSpeed > 6) {
                currentSpeed = .fast
            } else if scrollSpeed > 0.5 {
                currentSpeed = .normal
            }
            
            self.lastSpeedOffset = currentOffset
            self.lastSpeedOffsetCaptureTime = currentTime
        }
        
        let extremes = self.scrollView.firstAndLastVisibleTags()
        
        if extremes.lowest != Int.max || extremes.highest != Int.min {
            let startingPoint = self.scrollDirection == .up ? extremes.lowest : extremes.highest
            let endingPoint = self.scrollDirection == .up ? extremes.highest : extremes.lowest
            let edgeCondition = self.scrollDirection == .up ? T2GViewTags.cellConstant : self.scrollView.totalCellCount() + T2GViewTags.cellConstant - 1
            
            let startingPointIndexPath = self.scrollView.indexPathForCell(extremes.lowest)
            let endingPointIndexPath = self.scrollView.indexPathForCell(extremes.highest)
            
            self.insertDelimiterForSection(self.scrollView.layoutMode, section: (startingPointIndexPath as NSIndexPath).section)
            self.insertDelimiterForSection(self.scrollView.layoutMode, section: (endingPointIndexPath as NSIndexPath).section)
            
            if let cell = scrollView.viewWithTag(endingPoint) as? T2GCell , !scrollView.bounds.intersects(cell.frame) {
                cell.removeFromSuperview()
            }
            
            if let edgeCell = scrollView.viewWithTag(startingPoint) as? T2GCell {
                if scrollView.bounds.intersects(edgeCell.frame) && startingPoint != edgeCondition {
                    let firstAddedTag = self.addRowsWhileScrolling(self.scrollDirection, startTag: startingPoint)
                    if (currentSpeed == .fast || currentSpeed == .normal) && firstAddedTag != edgeCondition {
                        let secondAddedTag = self.addRowsWhileScrolling(self.scrollDirection, startTag: firstAddedTag)
                        if (currentSpeed == .fast) && secondAddedTag != edgeCondition {
                            let thirdAddedTag = self.addRowsWhileScrolling(self.scrollDirection, startTag: secondAddedTag)
                            if (currentSpeed == .fast || self.scrollView.layoutMode == .collection) && thirdAddedTag != edgeCondition {
                                let fourthAddedTag = self.addRowsWhileScrolling(self.scrollDirection, startTag: secondAddedTag)
                            }
                        }
                    }
                }
            } else {
                self.displayMissingCells()
            }
        } else {
            self.displayMissingCells()
        }
    }
    
    /**
    Checks and displays all cells that should be displayed.
    
    - parameter mode: T2GLayoutMode for which the supposedly displayed cells should be calculated. Optional value - if nothing is passed, current layout is used.
    */
    func displayMissingCells(_ mode: T2GLayoutMode? = nil) {
        let m = mode ?? self.scrollView.layoutMode
        
        let indices = self.scrollView.indicesForVisibleCells(m)
        for index in indices {
            _ = self.insertRowWithTag(index + T2GViewTags.cellConstant, animated: true)
        }
    }
    
    /**
    Adds rows while scrolling. Handles edge situations.
    
    - parameter direction: T2GScrollDirection defining which way is the scrollView being scrolled.
    - parameter startTag: Integer value representing the starting tag from which the next should be calculated - if direction is Up it is the TOP cell, if Down it is the BOTTOM cell in the scrollView.
    - returns: Integer value of the last added tag to the scrollView.
    */
    func addRowsWhileScrolling(_ direction: T2GScrollDirection, startTag: Int) -> Int {
        let multiplier = direction == .up ? -1 : 1
        let firstTag = startTag + (1 * multiplier)
        let secondTag = startTag + (2 * multiplier)
        let thirdTag = startTag + (3 * multiplier)
        
        let firstAdditionalCondition = direction == .up ? secondTag - T2GViewTags.cellConstant > 0 : secondTag - T2GViewTags.cellConstant < (self.scrollView.totalCellCount() - 1)
        let secondAdditionalCondition = direction == .up ? thirdTag - T2GViewTags.cellConstant > 0 : thirdTag - T2GViewTags.cellConstant < (self.scrollView.totalCellCount() - 1)
        
        var lastTag = self.insertRowWithTag(firstTag)
        
        if self.scrollView.layoutMode == .collection {
            if firstAdditionalCondition {
                lastTag = self.insertRowWithTag(secondTag)
                
                if secondAdditionalCondition {
                    lastTag = self.insertRowWithTag(thirdTag)
                }
            }
        }
        
        return lastTag
    }
    
    //MARK: - T2GCell delegate
    
    /**
    Closes other cell in case it was open before this cell started being swiped.
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag: Integer value representing the tag of the currently swiped cell.
    */
    func cellStartedSwiping(_ tag: Int) {
        if self.openCellTag != -1 && self.openCellTag != tag {
            let cell = self.view.viewWithTag(self.openCellTag) as? T2GCell
            cell?.closeCell()
        }
    }
    
    /**
    Redirects the call to the delegate to handle the event of cell selection.
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag: Integer value representing the tag of the selected cell.
    */
    func didSelectCell(_ tag: Int) {
        self.delegate.didSelectCellAtIndexPath(self.scrollView.indexPathForCell(tag))
    }
    
    /**
    Sets the tag for the currently open cell to be able to close it when another cell gets swiped.
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag: Integer value representing the tag of the opened cell.
    */
    func didCellOpen(_ tag: Int) {
        self.openCellTag = tag
    }
    
    /**
    Resets the tag for currently open cell to default (-1) value.
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag:
    */
    func didCellClose(_ tag: Int) {
        self.openCellTag = -1
    }
    
    /**
    Redirects the call to the delegate to handle the event of drawer button selection.
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag: Integer value representing the tag of the cell where the drawer button has been selected.
    - parameter index: Integer value representing the index of the button that has been selected.
    */
    func didSelectButton(_ tag: Int, index: Int) {
        self.delegate.didSelectDrawerButtonAtIndex(self.scrollView.indexPathForCell(tag), buttonIndex: index)
    }
    
    /**
    Saves the total index of the selected cell so it can reproduce the selection when the scrollView's content is long and gets deleted/added again (dynamic loading). Also serves as the full list of cells to be acted upon when toolbar button gets pressed (currently only delete).
    
    For description of the function header, see T2GCellDelegate protocol definition in T2GCell class.
    
    - parameter tag: Integer value representing the tag value of the cell whose checkbox has been pressed.
    - parameter selected: Boolean value representing whether the checkbox is selected or not.
    */
    func didSelectMultipleChoiceButton(_ tag: Int, selected: Bool) {
        self.editingModeSelection[tag - T2GViewTags.cellConstant] = selected
    }
    
    //MARK: - T2GCellDragAndDrop delegate
    
    /**
    Helper method finding the biggest overlapping subview to given CGRect.
    
    - parameter excludedTag: Integer value of the tag representing the dragged view to leave it out of the equation.
    - parameter frame: CGRect object representing the view to which an overlapping view is desired to be found.
    - returns: Optional UIView object if an eligible one has been found that is overlapping with the given frame.
    */
    func findBiggestOverlappingView(_ excludedTag: Int, frame: CGRect) -> UIView? {
        var winningView: UIView?
        
        var winningRect: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        
        for view in self.scrollView.subviews {
            if let c = view as? T2GCell , c.tag != excludedTag {
                if frame.intersects(c.frame) {
                    if winningView == nil {
                        winningView = c
                        winningRect = winningView!.frame
                    } else {
                        if (c.frame.size.height * c.frame.size.width) > (winningRect.size.height * winningRect.size.width) {
                            winningView!.alpha = 1.0
                            winningView = c
                            winningRect = winningView!.frame
                        } else {
                            c.alpha = 1.0
                        }
                    }
                } else {
                    c.alpha = 1.0
                }
            }
        }
        
        return winningView
    }
    
    /**
    Gets called when T2GDragAndDropView gets moved. Highlights the most overlapping view and determines whether the scrollView should be automatically scrolled up or down (top/bottom of the screen).
    
    - parameter tag: Integer value of the given cell.
    - parameter frame: CGRect object representing the frame of the dragged T2GDragAndDropView.
    */
    func didMove(_ tag: Int, frame: CGRect) {
        let height: CGFloat = 30.0
        
        let frameInView = self.scrollView.convert(frame, to: self.view)
        
        var topOrigin = self.scrollView.convert(CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y), to: self.view)
        if let navigationBar = self.navigationController {
            topOrigin.y += navigationBar.navigationBar.frame.origin.y + navigationBar.navigationBar.frame.size.height
        }
        let topStrip = CGRect(x: 0, y: topOrigin.y, width: self.scrollView.frame.size.width, height: height)
        
        if topStrip.intersects(frameInView) {
            let subview = self.view.viewWithTag(tag)
            let isFirstEncounter = subview?.superview is UIScrollView
            self.view.addSubview(subview!)
            
            if isFirstEncounter {
                let speedCoefficient = self.scrollView.coefficientForOverlappingFrames(topStrip, overlapping: frameInView) * -1
                self.scrollView.scrollContinously(speedCoefficient, stationaryFrame: topStrip, overlappingView: subview, navigationController: self.navigationController)
            }
        }
        
        let bottomOrigin = self.scrollView.convert(CGPoint(x: 0, y: self.scrollView.contentOffset.y + self.scrollView.frame.size.height - height), to: self.view)
        let bottomStrip = CGRect(x: 0, y: bottomOrigin.y, width: self.scrollView.frame.size.width, height: height)
        
        if bottomStrip.intersects(frameInView) {
            let subview = self.view.viewWithTag(tag)
            let isFirstEncounter = subview?.superview is UIScrollView
            self.view.addSubview(subview!)
            
            if isFirstEncounter {
                let speedCoefficient = self.scrollView.coefficientForOverlappingFrames(bottomStrip, overlapping: frameInView)
                self.scrollView.scrollContinously(speedCoefficient, stationaryFrame: bottomStrip, overlappingView: subview, navigationController: self.navigationController)
            }
        }
        
        let winningView = self.findBiggestOverlappingView(tag, frame: frame)
        winningView?.alpha = 0.3
    }
    
    /**
    Gets called when T2GDragAndDropView gets dropped. Determines where exactly it was dropped and calls the delegate method to handle whether or not will the destination accept it.
    
    - parameter view: T2GDragAndDropView that got dropped.
    */
    func didDrop(_ view: T2GDragAndDropView) {
        self.scrollView.performSubviewCleanup()
        
        if let win = self.findBiggestOverlappingView(view.tag, frame: view.frame) as? T2GCell {
            win.alpha = 1.0
            
            self.dropDelegate?.didDropCell(view as! T2GCell, onCell: win, completion: { () -> Void in
                UIView.animate(withDuration: 0.1, animations: { () -> Void in
                    let transform = CGAffineTransform(scaleX: 1.07, y: 1.07)
                    win.transform = transform
                    
                    view.center = win.center
                    
                    let transform2 = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    view.transform = transform2
                }, completion: { (_) -> Void in
                    view.removeFromSuperview()
                        
                    UIView.animate(withDuration: 0.15, animations: { () -> Void in
                        let transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                        win.transform = transform
                    }, completion: { (_) -> Void in
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            for v in self.scrollView.subviews {
                                if let c = v as? T2GCell {
                                    if c.tag > view.tag {
                                        let newFrame = self.scrollView.frameForCell(indexPath: self.scrollView.indexPathForCell(c.tag - 1))
                                        c.frame = newFrame
                                        c.tag = c.tag - 1
                                        self.delegate.updateCellForIndexPath(c, indexPath: self.scrollView.indexPathForCell(c.tag))
                                    }
                                } else if let delimiter = v as? T2GDelimiterView {
                                    let frame = self.scrollView.frameForDelimiter(section: delimiter.tag - 1)
                                    delimiter.frame = frame
                                }
                            }
                        }, completion: { (_) -> Void in
                            UIView.animate(withDuration: 0.3, animations: { () -> Void in
                                self.scrollView.adjustContentSize()
                            }, completion: { (_) -> Void in
                                self.displayMissingCells()
                            })
                        })
                    })
                })
            }, failure: { () -> Void in
                UIView.animate(withDuration: 0.3, animations: {
                    view.frame = CGRect(x: view.origin.x, y: view.origin.y, width: view.frame.size.width, height: view.frame.size.height)
                }) 
            })
            
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                view.frame = CGRect(x: view.origin.x, y: view.origin.y, width: view.frame.size.width, height: view.frame.size.height)
            }) 
        }
    }
}
