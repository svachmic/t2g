//
//  T2GCell.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 20/03/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import Foundation
import UIKit

/**
Protocol for handling the events of cell - selection, swiping the cell to open drawer or button press.
*/
protocol T2GCellDelegate {
    /**
    Gets called when swiping gesture began.
    
    - parameter tag: The tag of the swiped cell.
    */
    func cellStartedSwiping(_ tag: Int)
    
    /**
    Gets called when cell was selected.
    
    - parameter tag: The tag of the swiped cell.
    */
    func didSelectCell(_ tag: Int)
    
    /**
    Gets called when cell was opened.
    
    - parameter tag: The tag of the swiped cell.
    */
    func didCellOpen(_ tag: Int)
    
    /**
    Gets called when cell was closed.
    
    - parameter tag: The tag of the swiped cell.
    */
    func didCellClose(_ tag: Int)
    
    /**
    Gets called when drawer button has been pressed.
    
    - parameter tag: The tag of the swiped cell.
    - parameter index: Index of the button - indexed from right to left starting with 0.
    */
    func didSelectButton(_ tag: Int, index: Int)
    
    /**
    Gets called when the cells are in edit mode (multiple selection with checkboxes) and the checkbox's state changes.
    
    - parameter tag: The tag of the swiped cell.
    - parameter selected: Flag indicating if the checkbox is selected or not.
    */
    func didSelectMultipleChoiceButton(_ tag: Int, selected: Bool)
}

/**
Enum defining scrolling direction. Used for recognizing whether the cell should be closed or opened after the swiping gesture has ended half way through.
*/
private enum T2GCellSwipeDirection {
    case right
    case left
}

/**
Base class for cells in T2GScrollView (can be overriden). Has all drag and drop functionality thanks to inheritance. Implements drawer feature - swipe to reveal buttons for more interaction.
*/
class T2GCell: T2GDragAndDropView, UIScrollViewDelegate, T2GDragAndDropOwnerDelegate {
    var delegate: T2GCellDelegate?
    
    var highlighted: Bool = false {
        didSet {
            if let backgroundButton = self.backgroundView?.viewWithTag(T2GViewTags.cellBackgroundButton) as? UIButton {
                backgroundButton.isHighlighted = self.highlighted
            }
        }
    }
    
    var scrollView: T2GCellDrawerScrollView?
    var backgroundView: UIView?
    var imageView: UIImageView?
    var headerLabel: UILabel?
    var detailLabel: UILabel?
    
    var buttonCount: Int = 0
    
    fileprivate var swipeDirection: T2GCellSwipeDirection = .left
    fileprivate var lastContentOffset: CGFloat = 0
    
    /**
    Convenience initializer to initialize the cell with given parameters.
    
    - WARNING! To change the frame, do not use direct access to frame property. Use changeFrameParadigm instead (for rearranging all subviews).
    
    - parameter header: Main text line.
    - parameter detail: Detail text line.
    - parameter frame: Frame for the cell.
    - parameter mode: Which mode the cell is in (T2GLayoutMode).
    */
    convenience init(header: String, detail: String, frame: CGRect, mode: T2GLayoutMode) {
        self.init(frame: frame)
        
        self.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
        
        self.scrollView = T2GCellDrawerScrollView(frame: CGRect(x: -1, y: -1, width: self.frame.size.width + 2, height: self.frame.size.height + 2))
        self.scrollView!.backgroundColor = .clear
        self.scrollView!.showsHorizontalScrollIndicator = false
        self.scrollView!.bounces = false
        self.scrollView!.delegate = self
        
        self.scrollView!.delaysContentTouches = false
        //self.scrollView!.canCancelContentTouches = true
        
        self.backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.size.width + 2, height: self.frame.size.height + 2))
        
        let backgroundViewButton = T2GColoredButton(frame: self.backgroundView!.frame)
        backgroundViewButton.tag = T2GViewTags.cellBackgroundButton
        backgroundViewButton.normalBackgroundColor = .clear
        backgroundViewButton.highlightedBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        backgroundViewButton.addTarget(self, action: #selector(T2GCell.backgroundViewButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        self.backgroundView!.addSubview(backgroundViewButton)
        
        // View must be added to hierarchy before setting constraints.
        backgroundViewButton.translatesAutoresizingMaskIntoConstraints = false
        let views = ["background": self.backgroundView!, "button": backgroundViewButton]
        
        let constH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[button]|", options: .alignAllCenterY, metrics: nil, views: views)
        self.backgroundView!.addConstraints(constH)
        
        let constW = NSLayoutConstraint.constraints(withVisualFormat: "V:|[button]|", options: .alignAllCenterX, metrics: nil, views: views)
        self.backgroundView!.addConstraints(constW)
        
        self.backgroundView!.backgroundColor = .white
        self.scrollView!.addSubview(self.backgroundView!)
        
        let imageFrame = CGRect(x: 0, y: 0, width: 64 + 2, height: 64 + 2)
        self.imageView = UIImageView(frame: imageFrame)
        self.imageView!.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.2)
        self.backgroundView!.addSubview(self.imageView!)
        
        let labelDimensions = self.framesForLabels(frame)
        
        self.headerLabel = UILabel(frame: labelDimensions.header)
        self.headerLabel!.backgroundColor = .clear//.blackColor()
        self.headerLabel!.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        self.headerLabel!.font = UIFont.boldSystemFont(ofSize: 13)
        self.headerLabel!.textColor = .black//.whiteColor()
        self.headerLabel!.text = header
        self.backgroundView!.addSubview(self.headerLabel!)
        
        self.detailLabel = UILabel(frame: labelDimensions.detail)
        self.detailLabel!.backgroundColor = .clear//.blackColor()
        self.detailLabel!.lineBreakMode = NSLineBreakMode.byTruncatingMiddle
        self.detailLabel!.font = UIFont.systemFont(ofSize: 11)
        self.detailLabel!.textColor = .black//.whiteColor()
        self.detailLabel!.text = detail
        self.backgroundView!.addSubview(self.detailLabel!)
        
        self.backgroundView!.bringSubview(toFront: backgroundViewButton)
        
        self.addSubview(self.scrollView!)
        
        self.ownerDelegate = self
        
        if mode == .collection {
            self.changeFrameParadigm(.collection, frame: self.frame)
        }
    }
    
    /**
    Gets called when the cell has been pressed (standard tap gesture). Forwards the action to the delegate.
    
    - parameter sender: The button that initiated the action (that is a subview of backgroundView property).
    */
    func backgroundViewButtonPressed(_ sender: UIButton) {
        self.delegate?.didSelectCell(self.tag)
    }
    
    /**
    Changes frame of the cell. Should be used for any resizing or transforming of the cell. Handles resizing of all the subviews.
    
    - parameter mode: T2GLayoutMode in which the T2GScrollView is.
    - parameter frame: Frame to which the cell should resize.
    */
    func changeFrameParadigm(_ mode: T2GLayoutMode, frame: CGRect) {
        if self.scrollView!.contentOffset.x != 0 {
            self.moveButtonsInHierarchy(true)
            self.scrollView!.contentOffset.x = 0
        }
        
        self.frame = frame
        self.scrollView!.frame = CGRect(x: -1, y: -1, width: frame.size.width + 2, height: frame.size.height + 2)
        self.backgroundView!.frame = CGRect(x: 0, y: 0, width: frame.size.width + 2, height: frame.size.height + 2)
        self.scrollView!.contentSize = CGSize(width: frame.size.width * 2, height: frame.size.height)
        
        self.rearrangeButtons(mode)
        
        if let image = self.imageView {
            if mode == .table {
                image.frame = CGRect(x: 0, y: 0, width: self.frame.height + 2, height: self.frame.height + 2)
                
                let dimensions = self.framesForLabels(frame)
                
                self.headerLabel!.frame = dimensions.header
                self.headerLabel!.font = UIFont.boldSystemFont(ofSize: 13)
                
                self.detailLabel!.frame = dimensions.detail
                self.detailLabel!.alpha = 1
            } else {
                let x = (self.frame.width - image.frame.width) / 2
                let y = frame.size.height - image.frame.height - 6
                image.frame = CGRect(x: x, y: y, width: image.frame.width, height: image.frame.height)
                
                let headerFrame = CGRect(x: 0, y: 0, width: frame.size.width + 2, height: y - 2)
                self.headerLabel!.frame = headerFrame
                self.headerLabel!.font = UIFont.boldSystemFont(ofSize: 11)
                
                self.detailLabel!.alpha = 0
            }
        }
        
        /// If in editing mode
        if let button = self.viewWithTag(T2GViewTags.checkboxButton) {
            if mode == .table {
                for v in self.subviews {
                    if v.tag != button.tag {
                        let frame = CGRect(x: v.frame.origin.x + 50.0, y: v.frame.origin.y, width: v.frame.size.width, height: v.frame.size.height)
                        v.frame = frame
                    }
                }
            }
        }
    }
    
    /**
    Sets up buttons in drawer.
    
    - parameter images: Array of images to be set as the buttons' backgrounds. Also used to inform how many buttons to set up.
    - parameter mode: T2GLayoutMode in which the T2GScrollView is.
    */
    func setupButtons(_ buttonsInfo: [(normalImage: String, selectedImage: String, optionalText: String?)], mode: T2GLayoutMode) {
        let count = buttonsInfo.count
        self.buttonCount = count
        
        let coordinateData = self.coordinatesForButtons(count, mode: mode)
        let origins = coordinateData.frames
        
        for index in 0..<count {
            let point = origins[index]
            let view = T2GCellDrawerButton(frame: point)
            view.tag = T2GViewTags.cellDrawerButtonConstant + index
            
            if let img = UIImage(named: buttonsInfo[index].normalImage) {
                view.backgroundColor = .clear
                view.setBackgroundImage(img, for: UIControlState())
                
                if let img2 = UIImage(named: buttonsInfo[index].selectedImage) {
                    view.setBackgroundImage(img2, for: UIControlState.selected)
                    view.setBackgroundImage(img2, for: UIControlState.highlighted)
                }
            } else {
                view.normalBackgroundColor = .black
                view.highlightedBackgroundColor = .lightGray
                
                if let title = buttonsInfo[index].optionalText {
                    view.setTitle(title, for: UIControlState())
                } else {
                    view.setTitle("\(view.tag - T2GViewTags.cellDrawerButtonConstant + 1)", for: UIControlState())
                }
            }
            
            view.addTarget(self, action: #selector(T2GCell.buttonSelected(_:)), for: UIControlEvents.touchUpInside)
            self.addSubview(view)
            self.sendSubview(toBack: view)
        }
        
        self.scrollView!.contentSize = CGSize(width: self.frame.size.width * coordinateData.offsetMultiplier, height: self.frame.size.height)
    }
    
    /**
    Closes the drawer if it's opened.
    */
    func closeCell() {
        self.moveButtonsInHierarchy(true)
        self.swipeDirection = .right
        self.handleScrollEnd(self.scrollView!)
    }
    
    /**
    Gets called when T2GCellDrawerButton has been pressed. Redirects the action to the delegate.
    
    - parameter sender: T2GCellDrawerButton that has been pressed.
    */
    func buttonSelected(_ sender: T2GCellDrawerButton) {
        self.delegate?.didSelectButton(self.tag, index: sender.tag - T2GViewTags.cellDrawerButtonConstant)
    }
    
    //MARK: - Multiple choice toggle
    
    /**
    Transforms the view to edit mode - adds checkbox for multiple selection.
    
    - parameter flag: Flag indicating whether it is TO (true) or FROM (false).
    - parameter mode: T2GLayoutMode in which the T2GScrollView is.
    - parameter selected: Flag indicating if created checkbox should be selected.
    - parameter animated: Flag indicating if the whole transformation process should be animated (desired for initial transformation, but maybe not so much while scrolling).
    */
    func toggleMultipleChoice(_ flag: Bool, mode: T2GLayoutMode, selected: Bool, animated: Bool) {
        if mode == .collection {
            if flag {
                self.buildLayoutForEditInCollection(selected, animated: animated)
            } else {
                self.clearLayoutForEditInCollection(animated)
            }
            
        } else {
            self.layoutForEditInTable(flag, selected: selected, animated: animated)
        }
    }
    
    /**
    Helper method for transforming the view to edit mode - when T2GLayoutMode is set to Collection.
    
    - parameter selected: Flag indicating if created checkbox should be selected.
    - parameter animated: Flag indicating if the whole transformation process should be animated.
    */
    func buildLayoutForEditInCollection(_ selected: Bool, animated: Bool) {
        let duration_1 = animated ? 0.2 : 0.0
        let duration_2 = animated ? 0.15 : 0.0
        
        let frame = CGRect(x: -1, y: -1, width: self.frame.size.width + 2, height: self.frame.size.width + 2)
        let whiteOverlay = UIView(frame: frame)
        whiteOverlay.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        whiteOverlay.tag = 22222
        
        let size = frame.size.height * 0.35
        let x = frame.size.width - size - 5.0
        let y = frame.size.height - size - 5.0
        
        let originSize: CGFloat = 2.0
        let originX = x + CGFloat((size - originSize) / CGFloat(2.0))
        let originY = y + CGFloat((size - originSize) / CGFloat(2.0))
        
        let buttonFrame = CGRect(x: originX, y: originY, width: originSize, height: originSize)
        
        let button = T2GCheckboxButton(frame: buttonFrame)
        button.wasSelected = selected
        button.addTarget(self, action: #selector(T2GCell.multipleChoiceButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        button.tag = T2GViewTags.checkboxButton
        
        whiteOverlay.alpha = 0.0
        self.addSubview(whiteOverlay)
        
        UIView.animate(withDuration: duration_1, animations: { () -> Void in
            whiteOverlay.alpha = 1.0
            whiteOverlay.addSubview(button)
        }, completion: { (_) -> Void in
            UIView.animate(withDuration: duration_2, animations: { () -> Void in
                button.alpha = 1.0
                button.setNeedsDisplay()
                button.frame = CGRect(x: x, y: y, width: size, height: size)
            })
        })
    }
    
    /**
    Helper method for transforming the view to normal from edit mode - when T2GLayoutMode is set to Collection.
    
    - parameter animated: Flag indicating if the whole transformation process should be animated.
    */
    func clearLayoutForEditInCollection(_ animated: Bool) {
        let duration_1 = animated ? 0.15 : 0.0
        let duration_2 = animated ? 0.2 : 0.0
        
        if let whiteOverlay = self.viewWithTag(22222) {
            UIView.animate(withDuration: duration_1, animations: { () -> Void in
                if let button = self.viewWithTag(T2GViewTags.checkboxButton) {
                    
                    let size = button.frame.size.width
                    let originSize: CGFloat = 2.0
                    let x = button.frame.origin.x + CGFloat((size - originSize) / CGFloat(2.0))
                    let y = button.frame.origin.y + CGFloat((size - originSize) / CGFloat(2.0))
                    
                    button.frame = CGRect(x: x, y: y, width: originSize, height: originSize)
                }
            }, completion: { (_) -> Void in
                if let button = self.viewWithTag(T2GViewTags.checkboxButton) as? T2GCheckboxButton {
                    button.removeFromSuperview()
                }
                    
                UIView.animate(withDuration: duration_2, animations: { () -> Void in
                    whiteOverlay.alpha = 0.0
                }, completion: { (_) -> Void in
                    whiteOverlay.removeFromSuperview()
                })
            })
        }
    }
    
    /**
    Helper method for transforming the view from/to edit mode - when T2GLayoutMode is set to Table.
    
    - parameter flag: Flag indicating whether it is TO (true) or FROM (false).
    - parameter selected: Flag indicating if created checkbox should be selected.
    - parameter animated: Flag indicating if the whole transformation process should be animated.
    */
    func layoutForEditInTable(_ flag: Bool, selected: Bool, animated: Bool) {
        let duration = animated ? 0.3 : 0.0
        
        if flag {
            self.backgroundColor = .clear
        }
        
        UIView.animate(withDuration: duration, animations: { () -> Void in
            let diff: CGFloat = flag ? 50.0 : -50.0
            
            let moveClosure = { () -> Void in
                for v in self.subviews {
                    let frame = CGRect(x: v.frame.origin.x + diff, y: v.frame.origin.y, width: v.frame.size.width, height: v.frame.size.height)
                    v.frame = frame
                }
            }
            
            if flag {
                moveClosure()
                self.addMultipleChoiceButton(selected)
            } else {
                if let button = self.viewWithTag(T2GViewTags.checkboxButton) {
                    button.removeFromSuperview()
                }
                moveClosure()
            }
        }, completion: { (_) -> Void in
            if !flag && self.viewWithTag(T2GViewTags.checkboxButton) == nil {
                self.backgroundColor = .gray
            }
        })
    }
    
    /**
    Adds checkbox (T2GCheckboxButton) when going to edit mode.
    
    - parameter selected: Flag indicating if created checkbox should be selected.
    */
    func addMultipleChoiceButton(_ selected: Bool) {
        let size = self.frame.size.height * 0.5
        let x = CGFloat(0.0)
        let y = (self.frame.size.height - size) / 2
        let frame = CGRect(x: x, y: y, width: size, height: size)
        
        let button = T2GCheckboxButton(frame: frame)
        button.wasSelected = selected
        button.addTarget(self, action: #selector(T2GCell.multipleChoiceButtonPressed(_:)), for: UIControlEvents.touchUpInside)
        button.tag = T2GViewTags.checkboxButton
        button.alpha = 0.0
        self.addSubview(button)
        self.sendSubview(toBack: button)
        
        UIView.animate(withDuration: 0.15, animations: { () -> Void in
            button.alpha = 1.0
            }, completion: { (_) -> Void in
                self.bringSubview(toFront: button)
        })
    }
    
    /**
    Gets called when checkbox (T2GCheckboxButton) is pressed in edit mode. Marks the checkbox accordingly and redirects the action to the delegate.
    
    - parameter sender: T2GCheckboxButton that has been pressed.
    */
    func multipleChoiceButtonPressed(_ sender: T2GCheckboxButton) {
        sender.wasSelected = !sender.wasSelected
        self.delegate?.didSelectMultipleChoiceButton(self.tag, selected: sender.wasSelected)
    }
    
    //MARK: - Helper methods
    
    /**
    Calculates coordinates for buttons in the drawer.
    
    - parameter count: Number of buttons.
    - parameter mode: T2GLayoutMode in which the T2GScrollView is.
    - returns: Tuple (frames: [CGRect], offsetMultiplier: CGFloat) - array of frames for the buttons and multipler for how wide the content view of the scrollView needs to be to open as far as it is necessary.
    */
    func coordinatesForButtons(_ count: Int, mode: T2GLayoutMode) -> (frames: [CGRect], offsetMultiplier: CGFloat) {
        let buttonSize: CGFloat = 16.0
        var coords: [CGRect] = []
        var multiplier: CGFloat = 1.0
        
        if mode == .table {
            let margin = (self.frame.size.width - CGFloat(4 * buttonSize)) / 5.0
            let y = (self.frame.size.height - CGFloat(buttonSize)) / 2.0
            
            for index in 0..<count {
                let x = self.frame.size.width - (CGFloat(index + 1) * (CGFloat(buttonSize) + margin))
                multiplier = 1 + (1 - ((x - (margin * 0.75))/self.frame.size.width))
                coords.append(CGRect(x: x, y: y, width: buttonSize, height: buttonSize))
            }
        } else {
            let squareSize = CGFloat(self.frame.size.width)
            
            switch buttonCount {
            case 1:
                let x = (squareSize - buttonSize) / 2
                let y = x
                coords.append(CGRect(x: CGFloat(x), y: CGFloat(y), width: buttonSize, height: buttonSize))
                break
            case 2:
                let y = (squareSize - buttonSize) / 2
                let x1 = (squareSize / 2) - (buttonSize * 2)
                coords.append(CGRect(x: CGFloat(x1), y: CGFloat(y), width: buttonSize, height: buttonSize))
                
                let x2 = squareSize - x1 - buttonSize
                coords.append(CGRect(x: CGFloat(x2), y: CGFloat(y), width: buttonSize, height: buttonSize))
                
                break
            case 3:
                let x1 = (squareSize / 2) - (buttonSize * 2)
                let y1 = x1
                coords.append(CGRect(x: CGFloat(x1), y: CGFloat(y1), width: buttonSize, height: buttonSize))
                
                let x2 = squareSize - x1 - buttonSize
                let y2 = y1
                coords.append(CGRect(x: CGFloat(x2), y: CGFloat(y2), width: buttonSize, height: buttonSize))
                
                let x3 = (squareSize - buttonSize) / 2
                let y3 = squareSize - (buttonSize * 2)
                coords.append(CGRect(x: CGFloat(x3), y: CGFloat(y3), width: buttonSize, height: buttonSize))
                
                break
            case 4:
                let x1 = (squareSize / 2) - (buttonSize * 2)
                let y1 = x1
                coords.append(CGRect(x: CGFloat(x1), y: CGFloat(y1), width: buttonSize, height: buttonSize))
                
                let x2 = squareSize - x1 - buttonSize
                let y2 = y1
                coords.append(CGRect(x: CGFloat(x2), y: CGFloat(y2), width: buttonSize, height: buttonSize))
                
                let x3 = x1
                let y3 = squareSize - (buttonSize * 2)
                coords.append(CGRect(x: CGFloat(x3), y: CGFloat(y3), width: buttonSize, height: buttonSize))
                
                let x4 = x2
                let y4 = y3
                coords.append(CGRect(x: CGFloat(x4), y: CGFloat(y4), width: buttonSize, height: buttonSize))
                
                break
            default:
                break
            }
            
            multiplier = count == 0 ? 1.0 : 2.0
        }
        
        return (coords, multiplier)
    }
    
    /**
    Helper method to rearrange buttons when changeFrameParadigm method gets called.
    
    - parameter mode: T2GLayoutMode in which the T2GScrollView is.
    */
    func rearrangeButtons(_ mode: T2GLayoutMode) {
        let coordinateData = self.coordinatesForButtons(self.buttonCount, mode: mode)
        let origins = coordinateData.frames
        
        for index in 0..<self.buttonCount {
            if let view = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                let frame = origins[index]
                view.minOriginCoord = frame.origin
                view.frame = frame
            }
        }
        
        self.scrollView!.contentSize = CGSize(width: self.frame.size.width * coordinateData.offsetMultiplier, height: self.frame.size.height)
    }
    
    /**
    Proportionally calculates the frames of main title and detail title.
    
    - parameter frame: The frame to use for the calculations.
    - returns: Tuple (header: CGRect, detail: CGRect) - header for main title frame and detail for detail frame.
    */
    fileprivate func framesForLabels(_ frame: CGRect) -> (header: CGRect, detail: CGRect) {
        // Vertical spacing should be like |--H--D--| -> three equal spaces
        
        let headerHeight = frame.size.height * 0.45
        let detailHeight = frame.size.height * 0.30
        let margin = (frame.size.height - (headerHeight + detailHeight)) / 3
        
        let headerWidth = frame.size.width - (frame.size.height + 10) - 10
        let detailWidth = headerWidth * 0.75
        
        let headerFrame = CGRect(x: frame.size.height + 10, y: margin, width: headerWidth, height: headerHeight)
        let detailFrame = CGRect(x: frame.size.height + 10, y: headerFrame.size.height + (2 * margin), width: detailWidth, height: detailHeight)
        
        return (headerFrame, detailFrame)
    }
    
    
    //MARK: - Scroll view delegate methods
    
    /**
    Helper method that handles the end of scroll motion - closes or opens the drawer.
    
    - parameter scrollView: The UIScrollView where scrolling motion happened.
    */
    func handleScrollEnd(_ scrollView: UIScrollView) {
        let x = self.swipeDirection == .right ? 0 : self.frame.size.width
        let frame = CGRect(x: x, y: 0, width: scrollView.frame.size.width, height: scrollView.frame.size.height)
        
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            scrollView.scrollRectToVisible(frame, animated: false)
        }, completion: { (_) -> Void in
            if self.swipeDirection == .right {
                self.delegate?.didCellClose(self.tag)
            } else {
                self.delegate?.didCellOpen(self.tag)
                self.moveButtonsInHierarchy(false)
            }
        })
    }
    
    /**
    Helper method that sends drawer buttons to front/back in the view hierarchy while the scrollView gets scrolled.
    
    - parameter shouldHide: Flag determining whether the scrollView is getting closed or opened.
    */
    func moveButtonsInHierarchy(_ shouldHide: Bool) {
        for index in 0...3 {
            if let view = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                if shouldHide {
                    self.sendSubview(toBack: view)
                } else {
                    self.bringSubview(toFront: view)
                }
            }
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate when the scroll view is about to start scrolling the content.
    
    Informs the delegate that swiping motion began and moves buttons in hierarchy so they can be tapped.
    
    - parameter scrollView: The scroll-view object that is about to scroll the content view.
    */
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegate?.cellStartedSwiping(self.tag)
        self.moveButtonsInHierarchy(true)
    }
    
    /**
    Default Cocoa API - Tells the delegate when dragging ended in the scroll view.
    
    If dragging stopped by user (= no deceleration), handleScrollEnd gets called (open/close so it doesn't stay half-way open).
    
    - parameter scrollView: The scroll-view object that finished scrolling the content view.
    - parameter decelerate: True if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
    */
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.handleScrollEnd(scrollView)
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate that the scroll view is starting to decelerate the scrolling movement.
    
    Method handleScrollEnd gets called (open/close so it doesn't stay half-way open).
    
    - parameter scrollView: The scroll-view object that is decelerating the scrolling of the content view.
    */
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.handleScrollEnd(scrollView)
    }
    
    /**
    Default Cocoa API - Tells the delegate when a scrolling animation in the scroll view concludes.
    
    Shows buttons if the drawer was opened.
    
    - parameter scrollView: The scroll-view object that is performing the scrolling animation.
    */
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if self.swipeDirection == .left {
            self.moveButtonsInHierarchy(false)
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate when the user scrolls the content view within the receiver.
    
    Animates buttons while scrollView gets scrolled (bigger while opening, smaller while closing). Also determines direction of the swipe.
    
    - parameter scrollView: The scroll-view object in which the scrolling occurred.
    */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let tailPosition = -scrollView.contentOffset.x + self.backgroundView!.frame.size.width
        let sizeDifference = scrollView.contentOffset.x - self.lastContentOffset
        
        for index in 0..<self.buttonCount {
            if let button = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                button.resize(tailPosition, sizeDifference: sizeDifference)
            }
        }
        
        if self.lastContentOffset < scrollView.contentOffset.x {
            self.swipeDirection = .left
        } else {
            self.swipeDirection = .right
        }
        
        self.lastContentOffset = scrollView.contentOffset.x
    }
    
    //MARK: - T2GDragAndDropOwner delegate methods
    
    /**
    Adds long press gesture to the scrollView of the cell. It has to be done this way, because swiping is superior to long press. By this, the swiping gesture is always performed when user wants it to be performed.
    
    - parameter recognizer: Long press gesture created when draggable flag is set to true.
    */
    func addGestureRecognizerToView(_ recognizer: UILongPressGestureRecognizer) {
        self.scrollView?.addGestureRecognizer(self.longPressGestureRecognizer!)
    }
}
