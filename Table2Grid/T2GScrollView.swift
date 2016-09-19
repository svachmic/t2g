//
//  T2GScrollView.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 14/04/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Enum defining the state of the T2GScrollView. Table by default if not stated otherwise.
*/
enum T2GLayoutMode {
    case table
    case collection
    
    init() {
        self = .table
    }
}

/**
Protocol for scrollView delegate defining all key dimensional methods to be able to render all the cells precisely.
*/
protocol T2GScrollViewDataDelegate {
    /**
    Returns the number of sections in the datasource.
    
    - returns: Integer value defining number of sections.
    */
    func numberOfSections() -> Int
    
    /**
    Returns the number of cells in given section.
    
    - parameter section: Integer value representing the section, indexed from 0.
    - returns: Integer value defining number of cells in given section.
    */
    func numberOfCellsInSection(_ section: Int) -> Int
    
    /**
    Returns the dimensions for the cell in given layout mode.
    
    - parameter mode: T2GLayoutMode for which dimensions should be calculated.
    - returns: Tuple of width, height and padding for the cell.
    */
    func dimensionsForCell(_ mode: T2GLayoutMode) -> (width: CGFloat, height: CGFloat, padding: CGFloat)
    
    /**
    Returns the dimensions for the section header.
    
    - DISCUSSION: Will be most likely renamed to heightForSectionHeader, because the width is left out and is stretched to the full width.
    
    - returns: CGSize object defining width and height.
    */
    func dimensionsForSectionHeader() -> CGSize
}

/**
Custom UIScrollView class that takes care of all the T2GCell objects and displays them.
*/
class T2GScrollView: UIScrollView {
    var dataDelegate: T2GScrollViewDataDelegate?
    var customRefreshControl: UIControl? {
        didSet {
            self.addSubview(self.customRefreshControl!)
        }
    }
    var layoutMode: T2GLayoutMode = T2GLayoutMode()
    
    /**
    Helps not to delay the touchUpInside event on a UIButton that could possibly be a subview.
    
    - DISCUSSION: referenced from: http://stackoverflow.com/questions/3642547/uibutton-touch-is-delayed-when-in-uiscrollview

    override func touchesShouldCancelInContentView(view: UIView!) -> Bool {
        if view is T2GCell {
            return true
        }
        
        return  super.touchesShouldCancelInContentView(view)
    }
    */
    
    /**
    Returns the number of cells per line in given mode.
    
    - parameter mode: T2GLayoutMode for which the line cell count should be calculated.
    - returns: Integer value representing the number of cells for given mode.
    */
    func itemCountPerLine(_ mode: T2GLayoutMode) -> Int {
        if mode == .collection {
            let dimensions = self.dataDelegate!.dimensionsForCell(.collection)
            return Int(floor(self.frame.size.width / dimensions.width))
        } else {
            return 1
        }
    }
    
    /**
    Returns the number of cells that SHOULD be visible at the moment for the given mode.
    
    - parameter mode: T2GLayoutMode for which the count should be calculated. Optional value - if nothing is passed, current layout is used.
    - returns:
    */
    func visibleCellCount(_ mode: T2GLayoutMode? = nil) -> Int {
        let m = mode ?? self.layoutMode
        
        let dimensions = self.dataDelegate!.dimensionsForCell(self.layoutMode)
        var count = 0
        
        if m == .table {
            count = Int(ceil(self.frame.size.height / (dimensions.height + dimensions.padding)))
            if count == 0 {
                if let superframe = self.superview?.frame {
                    count = Int(ceil(superframe.size.height / (dimensions.height + dimensions.padding)))
                }
                
                count = count == 0 ? 10 : count
            }
        } else {
            count = Int(ceil(self.frame.size.height / (dimensions.height + dimensions.padding))) * self.itemCountPerLine(.collection)
            count = count == 0 ? 20 : count
        }
        
        return count
    }
    
    /**
    Returns the exact frame for cell at given indexPath.
    
    - parameter mode: T2GLayoutMode for which the cell frame should be calculated. Optional value - if nothing is passed, current layout is used.
    - parameter indexPath: NSIndexPath object for the given cell.
    - returns: CGRect object with origin and size parameters filled and ready to be used on the T2GCell view.
    */
    func frameForCell(_ mode: T2GLayoutMode? = nil, indexPath: IndexPath) -> CGRect {
        let m = mode ?? self.layoutMode
        
        let superviewFrame = self.superview!.frame
        let dimensions = self.dataDelegate!.dimensionsForCell(m)
        
        if m == .collection {
            /// Assuming that the collection is square of course
            let count = self.itemCountPerLine(.collection)
            let gap = (self.frame.size.width - (CGFloat(count) * dimensions.width)) / CGFloat(count + 1)
            
            var xCoords: [CGFloat] = []
            for index in 0..<count {
                let x = CGFloat(index) * (gap + dimensions.width) + gap
                xCoords.append(x)
            }
            
            var yCoord = dimensions.padding + (CGFloat((indexPath as NSIndexPath).row / xCoords.count) * (dimensions.height + dimensions.padding)) + self.dataDelegate!.dimensionsForSectionHeader().height
            for section in 0..<(indexPath as NSIndexPath).section {
                yCoord += (self.dataDelegate!.dimensionsForSectionHeader().height + (CGFloat(ceil(CGFloat(self.dataDelegate!.numberOfCellsInSection(section)) / CGFloat(xCoords.count))) * (dimensions.height + dimensions.padding)))
            }
            
            let frame = CGRect(x: CGFloat(xCoords[(indexPath as NSIndexPath).row % xCoords.count]), y: yCoord, width: dimensions.width, height: dimensions.height)
            
            return frame
            
        } else {
            let viewX = (superviewFrame.size.width - dimensions.width) / 2
            
            var ypsilon = viewX + (CGFloat((indexPath as NSIndexPath).row) * (dimensions.height + dimensions.padding)) + self.dataDelegate!.dimensionsForSectionHeader().height
            
            for section in 0..<(indexPath as NSIndexPath).section {
                ypsilon += (self.dataDelegate!.dimensionsForSectionHeader().height + (CGFloat(self.dataDelegate!.numberOfCellsInSection(section)) * (dimensions.height + dimensions.padding)))
            }
            
            return CGRect(x: viewX, y: ypsilon, width: dimensions.width, height: dimensions.height)
        }
    }
    
    /**
    Returns the exact frame for delimiter for given section.
    
    - parameter mode: T2GLayoutMode for which the delimiter frame should be calculated. Optional value - if nothing is passed, current layout is used.
    - parameter section: Integer value representing the section.
    - returns: CGRect object with origin and size parameters filled and ready to be used on the T2GDelimiter view.
    */
    func frameForDelimiter(_ mode: T2GLayoutMode? = nil, section: Int) -> CGRect {
        let m = mode ?? self.layoutMode
        
        let x: CGFloat = 0.0
        var y: CGFloat = 0.0
        
        let dimensions = self.dataDelegate!.dimensionsForSectionHeader()
        let height: CGFloat = dimensions.height
        let width: CGFloat = self.frame.size.width
        
        let cellDimensions = self.dataDelegate!.dimensionsForCell(m)
        
        if section != 0 {
            let count = self.itemCountPerLine(m)
            
            if m == .collection {
                y = cellDimensions.padding
            } else {
                y = (self.superview!.frame.size.width - cellDimensions.width) / 2
            }
            
            for idx in 0..<section {
                let lineCount = CGFloat(ceil(CGFloat(self.dataDelegate!.numberOfCellsInSection(idx)) / CGFloat(count)))
                y += (height + (lineCount * (cellDimensions.height + cellDimensions.padding)))
            }
            
            y -= (CGFloat(cellDimensions.padding / 2.0))
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /**
    Adjusts the content size of the scrollView depending on the number of cells.
    
    - parameter mode: T2GLayoutMode for which the content size should be calculated. Optional value - if nothing is passed, current layout is used.
    */
    func adjustContentSize(_ mode: T2GLayoutMode? = nil) {
        if let m = mode {
            self.contentSize = self.contentSizeForMode(m)
        } else {
            self.contentSize = self.contentSizeForMode(self.layoutMode)
        }
    }
    
    /**
    Aligns all the visible cells to make them be where they are (useful after rotation).
    */
    func alignVisibleCells() {
        for view in self.subviews {
            if let cell = view as? T2GCell {
                let frame = self.frameForCell(indexPath: self.indexPathForCell(cell.tag))
                if cell.frame.origin.x != frame.origin.x || cell.frame.origin.y != frame.origin.y || cell.frame.size.width != frame.size.width || cell.frame.size.height != frame.size.height {
                    cell.changeFrameParadigm(self.layoutMode, frame: frame)
                }
            } else {
                if let delimiter = view as? T2GDelimiterView {
                    let frame = self.frameForDelimiter(section: delimiter.tag - 1)
                    delimiter.frame = frame
                }
            }
        }
    }
    
    //MARK: - Animation methods
    
    /**
    Animates cells when the view controller owning the scrollView is going on/off screen.
    
    :params: isGoingOffscreen Boolean value defining whether the view is going offscreen or not.
    */
    func animateSubviewCells(_ isGoingOffscreen: Bool) {
        var delayCount: Double = 0.0
        let xOffset: CGFloat = isGoingOffscreen ? -150 : 150
        
        var tags = self.subviews.map({($0 ).tag})
        tags.sort(by: isGoingOffscreen ? {$0 < $1} : {$0 < $1})
        
        for tag in tags {
            if let view = self.viewWithTag(tag) as? T2GCell {
                let frame = self.frameForCell(indexPath: self.indexPathForCell(view.tag))
                
                if isGoingOffscreen || view.frame.origin.x != frame.origin.x {
                    delayCount += 1.0
                    let delay: Double = delayCount * 0.02
                    UIView.animate(withDuration: 0.2, delay: delay, options: [], animations: { () -> Void in
                        view.frame = CGRect(x: view.frame.origin.x + xOffset, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height)
                    }, completion: nil)
                }
            }
        }
    }
    
    /**
    Removes all the views that are not currently visible.
    */
    func performSubviewCleanup() {
        for view in self.subviews {
            if let cell = view as? T2GCell {
                if !self.bounds.intersects(cell.frame) || cell.alpha == 0 {
                    cell.removeFromSuperview()
                }
            } else if let delimiter = view as? T2GDelimiterView , !self.bounds.intersects(delimiter.frame) {
                delimiter.removeFromSuperview()
            }
        }
    }
    
    
    //MARK: - Helper methods
    
    /**
    Calculates the total index for given index path.
    
    - parameter indexPath: NSIndexPath object of the given cell.
    - returns: Integer value representing the total index.
    */
    func indexForIndexPath(_ indexPath: IndexPath) -> Int {
        var totalIndex = (indexPath as NSIndexPath).row
        for section in 0..<(indexPath as NSIndexPath).section {
            totalIndex += self.dataDelegate!.numberOfCellsInSection(section)
        }
        
        return totalIndex
    }
    
    /**
    Calculates the index path for given TAG of a cell.
    
    - DISCUSSION: Maybe it would be cleaner to already send an index instead of a TAG, but it is not anything that would be of a concern.
    
    - parameter tag: Integer value of the given cell.
    - returns: NSIndexPath object will full description (row and section) of the placement of the cell.
    */
    func indexPathForCell(_ tag: Int) -> IndexPath {
        let index = tag - T2GViewTags.cellConstant
        
        var row = 0
        var section = 0
        
        var currentMax = 0
        for sectionIndex in 0..<self.dataDelegate!.numberOfSections() {
            let cellsInSection = self.dataDelegate!.numberOfCellsInSection(sectionIndex)
            currentMax += cellsInSection
            if currentMax > index {
                row = index - (currentMax - cellsInSection)
                section = sectionIndex
                break
            }
        }
        
        return IndexPath(row: row, section: section)
    }
    
    /**
    Returns total count of all the cells in all the sections from the datasource.
    
    - returns: Integer value representing the number of cells.
    */
    func totalCellCount() -> Int {
        var total = 0
        for section in 0..<self.dataDelegate!.numberOfSections() {
            total += self.dataDelegate!.numberOfCellsInSection(section)
        }
        
        return total
    }

    /**
    Calculates the content size of the scrollView for the given mode based on current datasource status.
    
    - parameter mode: T2GLayoutMode for which the content size should be calculated.
    - returns: CGSize object to be set as the scrollView's contentSize.
    */
    func contentSizeForMode(_ mode: T2GLayoutMode) -> CGSize {
        var height: CGFloat = 0.0
        
        if let dimensions = self.dataDelegate?.dimensionsForCell(mode) {
            let viewX = mode == .collection ? dimensions.padding : (self.superview!.frame.size.width - dimensions.width) / 2
            let divisor = self.itemCountPerLine(mode)
            
            var lineCount = 0
            for section in 0..<self.dataDelegate!.numberOfSections() {
                lineCount += (Int(ceil(Double((self.dataDelegate!.numberOfCellsInSection(section) - 1) / divisor))) + 1)
            }
            lineCount -= 1
            
            let ypsilon = viewX + (CGFloat(lineCount) * (dimensions.height + dimensions.padding))
            height = ypsilon + dimensions.height + dimensions.padding + (CGFloat(self.dataDelegate!.numberOfSections()) * self.dataDelegate!.dimensionsForSectionHeader().height)
            height = height < self.bounds.height ? (self.bounds.height - 31.0) : height
        }
        
        return CGSize(width: self.superview!.frame.size.width, height: height)
    }
    
    /**
    Returns the highest and lowest tags of the visible cells.
    
    - DISCUSSION: Functional approach or for cycle?
    
    - returns: Tuple with two integer values representing the TAGs.
    */
    func firstAndLastVisibleTags() -> (lowest: Int, highest: Int) {
        /*
        let startValues = (lowest: Int.max, highest: Int.min)
        var minMax:(lowest: Int, highest: Int) = subviews.reduce(startValues) { prev, next in
        (next as? T2GCell).map {
        (min(prev.lowest, $0.tag), max(prev.highest, $0.tag))
        } ?? prev
        }
        */
        
        var lowest = Int.max
        var highest = Int.min
        
        for view in self.subviews {
            if let cell = view as? T2GCell {
                lowest = lowest > cell.tag ? cell.tag : lowest
                highest = highest < cell.tag ? cell.tag : highest
            }
        }
        
        return (lowest, highest)
    }
    
    /**
    Returns the indices of all the cells that SHOULD be visible for the given mode at the given contentOffset (self.bounds).
    
    - parameter mode: T2GLayoutMode for which the indices should be calculated.
    - returns: Array of integer values representing the total indices of the cells.
    */
    func indicesForVisibleCells(_ mode: T2GLayoutMode) -> [Int] {
        let frame = self.bounds
        var res = [Int]()
        
        if let dimensions = self.dataDelegate?.dimensionsForCell(mode) {
            if mode == .collection {
                let mult1 = ((frame.origin.y - dimensions.height) - (CGFloat(self.dataDelegate!.numberOfSections()) * self.dataDelegate!.dimensionsForSectionHeader().height))
                let mult2 = (dimensions.height + dimensions.padding)
                
                var firstIndex = Int(floor(mult1 / mult2)) * self.itemCountPerLine(.collection)
                if firstIndex < 0 {
                    firstIndex = 0
                }
                
                var lastIndex = firstIndex + 2 * self.visibleCellCount(.collection)
                if self.totalCellCount() - 1 < lastIndex {
                    lastIndex = self.totalCellCount() - 1
                }
                
                for index in firstIndex...lastIndex {
                    res.append(index)
                }
            } else {
                let mult1 = ((frame.origin.y - dimensions.height) - (CGFloat(self.dataDelegate!.numberOfSections()) * self.dataDelegate!.dimensionsForSectionHeader().height))
                let mult2 = (dimensions.height + dimensions.padding)
                
                var firstIndex = Int(floor(mult1 / mult2))
                if firstIndex < 0 {
                    firstIndex = 0
                }
                
                var lastIndex = firstIndex + self.visibleCellCount(.table)
                if self.totalCellCount() - 1 < lastIndex {
                    lastIndex = self.totalCellCount() - 1
                }
                
                if lastIndex != -1 {
                    for index in firstIndex...lastIndex {
                        res.append(index)
                    }
                }
            }
        }
        
        return res
    }
    
    //MARK: Continuous scroll
    
    /**
    Gets called when dragged view gets dragged to the bottom/top of the scrollView. This method then decides how and where should it scroll.
    
    - parameter speedCoefficient: CGFloat value defining how fast should the continuous scroll be.
    - parameter stationaryFrame: CGRect object defining top/bottom of the scrollView towards which the overlap is calculated.
    - parameter overlappingView: UIView being measured with the stationaryFrame, most likely a T2GDragAndDropView object.
    - parameter navigationController: Optional object that makes sure the stationaryFrame gets pulled lower in case navigation bar is present.
    */
    func scrollContinously(_ speedCoefficient: CGFloat, stationaryFrame: CGRect, overlappingView: UIView?, navigationController: UINavigationController?) {
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            var toMove = self.contentOffset.y + (32.0 * speedCoefficient)
            
            if speedCoefficient < 0 {
                var minContentOffset: CGFloat = 0.0
                if let navigationBar = navigationController?.navigationBar {
                    minContentOffset -= (navigationBar.frame.origin.y + navigationBar.frame.size.height)
                }
                
                if toMove < minContentOffset {
                    toMove = minContentOffset
                }
            } else {
                let maxContentOffset = self.contentSize.height - self.frame.size.height
                if toMove > maxContentOffset {
                    toMove = maxContentOffset
                }
            }
            
            self.contentOffset = CGPoint(x: self.contentOffset.x, y: toMove)
        }, completion: { (_) -> Void in
            if let overlappingCellView = overlappingView {
                    
                var shouldContinueScrolling = true
                if speedCoefficient < 0 {
                    var minContentOffset: CGFloat = 0.0
                    if let navigationBar = navigationController?.navigationBar {
                        minContentOffset -= (navigationBar.frame.origin.y + navigationBar.frame.size.height)
                    }
                        
                    if self.contentOffset.y == minContentOffset {
                        shouldContinueScrolling = false
                    }
                } else {
                    let maxContentOffset = self.contentSize.height - self.frame.size.height
                    if self.contentOffset.y == self.contentSize.height - self.frame.size.height {
                        shouldContinueScrolling = false
                    }
                }
                    
                let newOverlappingViewFrame = overlappingCellView.frame
                    
                if shouldContinueScrolling && stationaryFrame.intersects(newOverlappingViewFrame) {
                    let speedCoefficient2 = self.coefficientForOverlappingFrames(stationaryFrame, overlapping: newOverlappingViewFrame) * (speedCoefficient < 0 ? -1 : 1)
                    self.scrollContinously(speedCoefficient2, stationaryFrame: stationaryFrame, overlappingView: overlappingView, navigationController: navigationController)
                } else {
                    self.addSubview(overlappingCellView)
                }
            }
        })
    }
    
    /**
    Helper method calculating the speed of the continuous scroll. Calculates the ratio of overlapping of two frames.
    
    - parameter stationary: CGRect defining the stationary view.
    - parameter overlapping: CGRect defining the moving view.
    - returns: CGFloat with the value defining the speed.
    */
    func coefficientForOverlappingFrames(_ stationary: CGRect, overlapping: CGRect) -> CGFloat {
        let stationarySize = stationary.size.width * stationary.size.height
        let intersection = stationary.intersection(overlapping)
        let intersectionSize = intersection.size.height * intersection.size.width
        return intersectionSize / stationarySize
    }

}
