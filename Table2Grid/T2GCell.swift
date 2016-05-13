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
    
    :param: tag The tag of the swiped cell.
    */
    func cellStartedSwiping(tag: Int)
    
    /**
    Gets called when cell was selected.
    
    :param: tag The tag of the swiped cell.
    */
    func didSelectCell(tag: Int)
    
    /**
    Gets called when cell was opened.
    
    :param: tag The tag of the swiped cell.
    */
    func didCellOpen(tag: Int)
    
    /**
    Gets called when cell was closed.
    
    :param: tag The tag of the swiped cell.
    */
    func didCellClose(tag: Int)
    
    /**
    Gets called when drawer button has been pressed.
    
    :param: tag The tag of the swiped cell.
    :param: index Index of the button - indexed from right to left starting with 0.
    */
    func didSelectButton(tag: Int, index: Int)
    
    /**
    Gets called when the cells are in edit mode (multiple selection with checkboxes) and the checkbox's state changes.
    
    :param: tag The tag of the swiped cell.
    :param: selected Flag indicating if the checkbox is selected or not.
    */
    func didSelectMultipleChoiceButton(tag: Int, selected: Bool)
}

/**
Enum defining scrolling direction. Used for recognizing whether the cell should be closed or opened after the swiping gesture has ended half way through.
*/
private enum T2GCellSwipeDirection {
    case Right
    case Left
}

enum ImageType {
    case Icon
    case Picture
}

/**
Base class for cells in T2GScrollView (can be overriden). Has all drag and drop functionality thanks to inheritance. Implements drawer feature - swipe to reveal buttons for more interaction.
*/
class T2GCell: T2GDragAndDropView, UIScrollViewDelegate/*, T2GDragAndDropOwnerDelegate */{
    var delegate: T2GCellDelegate?
    
    var highlighted: Bool = false {
        didSet {
            if let backgroundButton = self.backgroundView.viewWithTag(T2GViewTags.cellBackgroundButton) as? UIButton {
                backgroundButton.highlighted = self.highlighted
            }
        }
    }
    var mode: T2GLayoutMode = .Collection

    var header: String = ""
    var detail: String = ""
    var imageType: ImageType = .Icon
    var isBookmarked: Bool = false
    var isShared: Bool = false
    var isSynced: Bool = false
    
    
    // Common attribute
    var scrollView: T2GCellDrawerScrollView = T2GCellDrawerScrollView()
    var backgroundView: UIView = UIView()
    var backgroundViewButton: T2GColoredButton = T2GColoredButton()
    
    
    var iconView: UIView = UIView()
    var imageView: UIImageView = UIImageView()
    var headerLabel: UILabel = UILabel()
    var detailLabel: UILabel = UILabel()
    
    var infoView: UIView = UIView()
    var bookmarkImageView: UIImageView = UIImageView()
    var shareImageView: UIImageView = UIImageView()
    var syncImageView: UIImageView = UIImageView()
    var moreImageButton: UIButton = UIButton(type: UIButtonType.Custom)// as UIButton

    // Collection attribute
    var whiteFooter: UIView = UIView()
    
    var buttonCount: Int = 0
    
    private var swipeDirection: T2GCellSwipeDirection = .Right
    private var lastContentOffset: CGFloat = 0
    
    /**
    Convenience initializer to initialize the cell with given parameters.
    
    - WARNING! To change the frame, do not use direct access to frame property. Use changeFrameParadigm instead (for rearranging all subviews).
    
    :param: header Main text line.
    :param: detail Detail text line.
    :param: frame Frame for the cell.
    :param: mode Which mode the cell is in (T2GLayoutMode).
    */
    convenience init(header: String, detail: String, frame: CGRect, mode: T2GLayoutMode) {
        self.init(frame: frame)
        
        self.header = header
        self.detail = detail
        self.mode = mode

        self.renderCell()
    }
    
    func renderCell() {
        if self.mode == .Table {
            self.backgroundColor = T2GStyle.Node.Table.backgroundColor
            self.detailLabel.hidden = false
            self.whiteFooter.hidden = true
        } else {
            self.backgroundColor = T2GStyle.Node.Collection.backgroundColor
            self.detailLabel.hidden = true
            self.whiteFooter.hidden = false
        }
        
        self.cellSetScrollView()
        self.addSubview(self.scrollView)
        if self.mode == .Collection {
            self.cellSetWhiteFooter()
            self.addSubview(self.whiteFooter)
        }
        
        if self.scrollView.contentOffset.x != 0 {
            self.moveButtonsInHierarchy(true)
            self.scrollView.contentOffset.x = 0
        }
        
        self.backgroundView.bringSubviewToFront(backgroundViewButton)
        if self.mode == .Table {
            self.backgroundView.bringSubviewToFront(self.moreImageButton)
            self.bringSubviewToFront(backgroundView)
        }
        self.rearrangeButtons(self.mode)
    }
    
    func cellSetScrollView() {
        if self.mode == .Table {
            self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)
            self.scrollView.scrollEnabled = true
        } else {
            self.scrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height / 5 * 4)
            self.scrollView.contentSize = CGSize(width: self.frame.size.width, height: self.frame.size.height / 5 * 4)
            self.scrollView.scrollEnabled = false
        }
        self.scrollView.backgroundColor = T2GStyle.Node.nodeScrollViewBackgroundColor
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.bounces = false
        self.scrollView.delegate = self
        self.scrollView.delaysContentTouches = false
        self.cellSetBackgroundView()
        self.scrollView.addSubview(self.backgroundView)
    }
    
    func cellSetWhiteFooter() {
        self.whiteFooter.frame = CGRectMake(0, frame.height / 5 * 4, frame.width, frame.height / 5)
        self.whiteFooter.backgroundColor = T2GStyle.Node.Collection.whiteFooterBackgroundColor
        self.cellSetMoreImageButton()
        self.cellSetHeaderLabel()
        self.whiteFooter.addSubview(self.moreImageButton)
        self.whiteFooter.addSubview(self.headerLabel)
    }
    
    
    func cellSetBackgroundView() {
        self.backgroundView.backgroundColor = T2GStyle.Node.nodeBackgroundViewBackgroundColor
        self.backgroundView.frame = self.scrollView.frame
        if self.mode == .Table {
            self.cellSetHeaderLabel()
            self.cellSetDetailLabel()
            self.cellSetMoreImageButton()
            
            self.backgroundView.addSubview(self.headerLabel)
            self.backgroundView.addSubview(self.detailLabel)
            self.backgroundView.addSubview(self.moreImageButton)
        }
        self.cellSetBackgroundViewButton()
        self.cellSetIconView()
        self.backgroundView.addSubview(self.backgroundViewButton)
        // View must be added to hierarchy before setting constraints.
        self.backgroundViewButton.translatesAutoresizingMaskIntoConstraints = false
        let views = ["background": self.backgroundView, "button": backgroundViewButton]
        let constH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[button]|", options: .AlignAllCenterY, metrics: nil, views: views)
        self.backgroundView.addConstraints(constH)
        let constW = NSLayoutConstraint.constraintsWithVisualFormat("V:|[button]|", options: .AlignAllCenterX, metrics: nil, views: views)
        self.backgroundView.addConstraints(constW)
        self.backgroundView.addSubview(self.iconView)
    }
    
    func cellSetBackgroundViewButton() {
        self.backgroundViewButton.frame = self.backgroundView.bounds
        self.backgroundViewButton.tag = T2GViewTags.cellBackgroundButton
        self.backgroundViewButton.normalBackgroundColor = .clearColor()
        self.backgroundViewButton.highlightedBackgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        self.backgroundViewButton.addTarget(self, action: #selector(T2GCell.backgroundViewButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }

    
    
    func cellSetIconView() {
        if self.mode == .Table {
            self.iconView.frame = CGRectMake(0, 0, self.frame.height, self.frame.height)
        } else {
            self.iconView.frame = self.scrollView.frame
        }
        self.iconView.backgroundColor = T2GStyle.Node.nodeIconViewBackgroundColor
        self.cellSetImageView()
        self.cellSetInfoView()
        self.iconView.addSubview(self.imageView)
        self.iconView.addSubview(self.infoView)
    }
    
    func cellSetImageView() {
        //self.imageView.frame = self.iconView.frame
        //self.imageView.center = CGPoint(x: self.frame.height / 2, y: self.frame.height / 2)
        self.imageView.contentMode = UIViewContentMode.ScaleAspectFill
        self.imageView.clipsToBounds = true
        if self.imageType == .Icon {
            self.imageView.frame.size = CGSizeMake(30, 30)
            self.imageView.center = self.iconView.center
        } else {
            self.imageView.frame = self.iconView.frame
        }
    }
    
    func cellSetInfoView() {
        self.infoView.frame = CGRectMake(0, self.iconView.frame.height - 15, self.iconView.frame.height, 15)
        self.shareImageView.frame = CGRectMake(0, 0, self.infoView.frame.height, self.infoView.frame.height)
        self.shareImageView.image = UIImage(named: "share_annotation")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.shareImageView.tintColor = UIColor(named: .PYDMarine)
        self.shareImageView.hidden = true
        self.bookmarkImageView.frame = CGRectMake(0, 0, self.infoView.frame.height, self.infoView.frame.height)
        self.bookmarkImageView.image = UIImage(named: "bookmark_annotation")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.bookmarkImageView.tintColor = UIColor(named: .PYDBlue)
        self.bookmarkImageView.hidden = true
        self.syncImageView.frame = CGRectMake(0, 0, self.infoView.frame.height, self.infoView.frame.height)
        self.syncImageView.image = UIImage(named: "sync_annotation")?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.syncImageView.tintColor = UIColor(named: .PYDOrange)
        self.syncImageView.hidden = true

        self.infoView.addSubview(self.shareImageView)
        self.infoView.addSubview(self.bookmarkImageView)
        self.infoView.addSubview(self.syncImageView)
    }
    
    func cellSetMoreImageButton() {
        let imageButton = UIImage(named: "dots_vertical")
        self.moreImageButton.setImage(imageButton, forState: .Normal)

        self.moreImageButton.alpha = 0.3
        self.moreImageButton.addTarget(self, action: #selector(T2GCell.moreButtonImagePressed(_:)), forControlEvents: .TouchUpInside)
        self.moreImageButton.imageEdgeInsets = UIEdgeInsetsMake(30, 30, 30, 30)
        
        if self.mode == .Table {
            self.moreImageButton.frame = CGRectMake(self.frame.width - self.frame.height, 0, self.frame.height, self.frame.height)
        } else {
            self.moreImageButton.frame = CGRectMake(self.frame.width - self.whiteFooter.frame.height, 0, self.whiteFooter.frame.height, self.whiteFooter.frame.height)
        }
    }
    
    func cellSetHeaderLabel() {
        
        if self.mode == .Table {
            let labelDimensions = self.framesForLabels(frame)
            self.headerLabel.frame = labelDimensions.header
        } else {
            self.headerLabel.frame = CGRectMake(self.whiteFooter.frame.height / 2, 0, self.frame.width - self.moreImageButton.frame.width - self.whiteFooter.frame.height / 2, self.whiteFooter.frame.height)
        }
        self.headerLabel.backgroundColor = .clearColor()
        self.headerLabel.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
        self.headerLabel.font = T2GStyle.Node.nodeTitleFont
        self.headerLabel.textColor = T2GStyle.Node.nodeTitleColor
        self.headerLabel.text = self.header
    }
    
    func cellSetDetailLabel() {
        let labelDimensions = self.framesForLabels(frame)
        self.detailLabel.frame = labelDimensions.detail
        self.detailLabel.backgroundColor = .clearColor()
        self.detailLabel.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
        self.detailLabel.font = T2GStyle.Node.nodeDescriptionFont
        self.detailLabel.textColor = T2GStyle.Node.nodeDescriptionColor
        self.detailLabel.text = self.detail
        self.backgroundView.addSubview(self.detailLabel)
    }
    
    /**
     Define the style of the image view deping if the node has a thumbnail.
     
     :param: node PYDNode concerned
     */
    func cellSetImage(node: PYDNode){
        if let thumb = node.loadThumbnailImageData(), img = UIImage(data: thumb) {
            self.imageView.frame = self.iconView.frame
            self.imageView.image = img
            self.imageType = .Picture
        } else {
            let image = UIImage(named: node.loadIcon()!) ?? UIImage(named: "mime_empty.png")!
            self.imageView.frame.size = CGSizeMake(30, 30)
            self.imageView.center = self.iconView.center
            self.imageView.image = image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            self.imageView.tintColor = T2GStyle.Node.nodeImageViewTintColor
            self.imageType = .Icon
        }
    }
    
    // TODO: Suite a une discussion avec Charles, il faut que je regarde dans le registre ou toutes les associations doivent se trouver.
    func cellSetImage(node: PYDOfflineNode) {
        let nodeIcon = node.loadIcon()
        
        if nodeIcon == "image.png" {
            self.imageView.frame = self.iconView.frame
            self.imageView.image = UIImage(contentsOfFile: node.loadNodeAbsolutePath()!)
            self.imageType = .Picture
        } else {
            let image: UIImage = UIImage(named: nodeIcon)!
            
            self.imageView.frame.size = CGSizeMake(30, 30)
            self.imageView.center = self.iconView.center
            self.imageView.image = image.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
            self.imageView.tintColor = T2GStyle.Node.nodeImageViewTintColor
            self.imageType = .Icon
        }
    }
    
    func cellSetIsSynced(node: PYDOfflineNode) {
        let margin = self.infoView.frame.width - 5.0 - self.infoView.frame.height

        if node.loadIsSynced() {
            self.syncImageView.frame = CGRectMake(margin, 0, self.infoView.frame.height, self.infoView.frame.height)
            self.isSynced = true
            self.syncImageView.hidden = false
        } else {
            self.isShared = false
            self.syncImageView.hidden = true
        }
    }
    
    
    /**
     Set annotations to the cell for the given node.
     
     :param: node PYDNode concerned
     */
    func cellSetAnnotations(node: PYDNode) {
        var margin = self.infoView.frame.width - 5.0 - self.infoView.frame.height
        
        if node.loadIsBookmarked() {
            self.bookmarkImageView.frame = CGRectMake(margin, 0, self.infoView.frame.height, self.infoView.frame.height)
            self.isBookmarked = true
            self.bookmarkImageView.hidden = false
            margin = margin - 5 - self.bookmarkImageView.frame.width
        } else {
            self.isBookmarked = false
            self.bookmarkImageView.hidden = true
        }
        if node.loadIsShared() {
            self.shareImageView.frame = CGRectMake(margin, 0, self.infoView.frame.height, self.infoView.frame.height)
            self.isShared = true
            self.shareImageView.hidden = false
            margin = margin - 5 - self.shareImageView.frame.width
        } else {
            self.isShared = false
            self.shareImageView.hidden = true
        }
        if node.loadIsSynced() {
            self.syncImageView.frame = CGRectMake(margin, 0, self.infoView.frame.height, self.infoView.frame.height)
            self.isSynced = true
            self.syncImageView.hidden = false
        } else {
            self.isShared = false
            self.syncImageView.hidden = true
        }
    }
    
    /**
    Gets called when the cell has been pressed (standard tap gesture). Forwards the action to the delegate.
    
    :param: sender The button that initiated the action (that is a subview of backgroundView property).
    */
    func backgroundViewButtonPressed(sender: UIButton) {
        self.delegate?.didSelectCell(self.tag)
    }
    
    /**
    Changes frame of the cell. Should be used for any resizing or transforming of the cell. Handles resizing of all the subviews.
    
    :param: mode T2GLayoutMode in which the T2GScrollView is.
    :param: frame Frame to which the cell should resize.
    */
    func changeFrameParadigm(mode: T2GLayoutMode, frame: CGRect) {
        self.frame = frame
        self.mode = mode
        self.renderCell()
    }
    
    /**
    Sets up buttons in drawer.
    
    :param: images Array of images to be set as the buttons' backgrounds. Also used to inform how many buttons to set up.
    :param: mode T2GLayoutMode in which the T2GScrollView is.
    */
    func setupButtons(buttonsInfo: [(normalImage: String, selectedImage: String, optionalText: String?)], mode: T2GLayoutMode) {
        let count = buttonsInfo.count
        self.buttonCount = count
        
        let coordinateData = self.coordinatesForButtons(count, mode: mode)
        let origins = coordinateData.frames
        
        for index in 0..<count {
            let point = origins[index]
            let view = T2GCellDrawerButton(frame: point)
            view.tag = T2GViewTags.cellDrawerButtonConstant + index
            
            if var img = UIImage(named: buttonsInfo[index].normalImage) {
                img = img.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
                view.tintColor = T2GStyle.Node.nodeImageViewTintColor
                view.backgroundColor = .clearColor()
                view.setBackgroundImage(img, forState: UIControlState.Normal)
                
                if let img2 = UIImage(named: buttonsInfo[index].selectedImage) {
                    view.setBackgroundImage(img2, forState: UIControlState.Selected)
                    view.setBackgroundImage(img2, forState: UIControlState.Highlighted)
                }
            } else {
                view.normalBackgroundColor = .blackColor()
                view.highlightedBackgroundColor = .lightGrayColor()
                
                if let title = buttonsInfo[index].optionalText {
                    view.setTitle(title, forState: UIControlState.Normal)
                } else {
                    view.setTitle("\(view.tag - T2GViewTags.cellDrawerButtonConstant + 1)", forState: UIControlState.Normal)
                }
            }
            
            view.addTarget(self, action: #selector(T2GCell.buttonSelected(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            self.addSubview(view)
            self.sendSubviewToBack(view)
        }
        
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width * 2 - self.frame.size.height, self.frame.size.height)
    }
    
    /**
    Closes the drawer if it's opened.
    */
    func closeCell() {
        self.moveButtonsInHierarchy(true)
        self.swipeDirection = .Right
        self.handleScrollEnd(self.scrollView)
    }
    
    /**
    Gets called when T2GCellDrawerButton has been pressed. Redirects the action to the delegate.
    
    :param: sender T2GCellDrawerButton that has been pressed.
    */
    func buttonSelected(sender: T2GCellDrawerButton) {
        self.delegate?.didSelectButton(self.tag, index: sender.tag - T2GViewTags.cellDrawerButtonConstant)
    }
    
    //MARK: - Multiple choice toggle
    
    /**
    Transforms the view to edit mode - adds checkbox for multiple selection.
    
    :param: flag Flag indicating whether it is TO (true) or FROM (false).
    :param: mode T2GLayoutMode in which the T2GScrollView is.
    :param: selected Flag indicating if created checkbox should be selected.
    :param: animated Flag indicating if the whole transformation process should be animated (desired for initial transformation, but maybe not so much while scrolling).
    */
    func toggleMultipleChoice(flag: Bool, mode: T2GLayoutMode, selected: Bool, animated: Bool) {
        if mode == .Collection {
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
    
    :param: selected Flag indicating if created checkbox should be selected.
    :param: animated Flag indicating if the whole transformation process should be animated.
    */
    func buildLayoutForEditInCollection(selected: Bool, animated: Bool) {
        let duration_1 = animated ? 0.2 : 0.0
        let duration_2 = animated ? 0.15 : 0.0
        
        let frame = CGRectMake(-1, -1, self.frame.size.width + 2, self.frame.size.width + 2)
        let whiteOverlay = UIView(frame: frame)
        whiteOverlay.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
        whiteOverlay.tag = 22222
        
        let size = frame.size.height * 0.35
        let x = frame.size.width - size - 5.0
        let y = frame.size.height - size - 5.0
        
        let originSize: CGFloat = 2.0
        let originX = x + CGFloat((size - originSize) / CGFloat(2.0))
        let originY = y + CGFloat((size - originSize) / CGFloat(2.0))
        
        let buttonFrame = CGRectMake(originX, originY, originSize, originSize)
        
        let button = T2GCheckboxButton(frame: buttonFrame)
        button.wasSelected = selected
        button.addTarget(self, action: #selector(T2GCell.multipleChoiceButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.tag = T2GViewTags.checkboxButton
        
        whiteOverlay.alpha = 0.0
        self.addSubview(whiteOverlay)
        
        UIView.animateWithDuration(duration_1, animations: { () -> Void in
            whiteOverlay.alpha = 1.0
            whiteOverlay.addSubview(button)
        }, completion: { (_) -> Void in
            UIView.animateWithDuration(duration_2, animations: { () -> Void in
                button.alpha = 1.0
                button.setNeedsDisplay()
                button.frame = CGRectMake(x, y, size, size)
            })
        })
    }
    
    /**
    Helper method for transforming the view to normal from edit mode - when T2GLayoutMode is set to Collection.
    
    :param: animated Flag indicating if the whole transformation process should be animated.
    */
    func clearLayoutForEditInCollection(animated: Bool) {
        let duration_1 = animated ? 0.15 : 0.0
        let duration_2 = animated ? 0.2 : 0.0
        
        if let whiteOverlay = self.viewWithTag(22222) {
            UIView.animateWithDuration(duration_1, animations: { () -> Void in
                if let button = self.viewWithTag(T2GViewTags.checkboxButton) {
                    
                    let size = button.frame.size.width
                    let originSize: CGFloat = 2.0
                    let x = button.frame.origin.x + CGFloat((size - originSize) / CGFloat(2.0))
                    let y = button.frame.origin.y + CGFloat((size - originSize) / CGFloat(2.0))
                    
                    button.frame = CGRectMake(x, y, originSize, originSize)
                }
            }, completion: { (_) -> Void in
                if let button = self.viewWithTag(T2GViewTags.checkboxButton) as? T2GCheckboxButton {
                    button.removeFromSuperview()
                }
                    
                UIView.animateWithDuration(duration_2, animations: { () -> Void in
                    whiteOverlay.alpha = 0.0
                }, completion: { (_) -> Void in
                    whiteOverlay.removeFromSuperview()
                })
            })
        }
    }
    
    /**
    Helper method for transforming the view from/to edit mode - when T2GLayoutMode is set to Table.
    
    :param: flag Flag indicating whether it is TO (true) or FROM (false).
    :param: selected Flag indicating if created checkbox should be selected.
    :param: animated Flag indicating if the whole transformation process should be animated.
    */
    func layoutForEditInTable(flag: Bool, selected: Bool, animated: Bool) {
        let duration = animated ? 0.3 : 0.0
        
        if flag {
            self.backgroundColor = .clearColor()
        }
        
        UIView.animateWithDuration(duration, animations: { () -> Void in
            let diff: CGFloat = flag ? 50.0 : -50.0
            
            let moveClosure = { () -> Void in
                for v in self.subviews {
                    let uiview: UIView? = v
                    
                    if let v2 = uiview {
                        let frame = CGRectMake(v.frame.origin.x + diff, v.frame.origin.y, v.frame.size.width, v.frame.size.height)
                        v2.frame = frame
                    }
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
                self.backgroundColor = .grayColor()
            }
        })
    }
    
    /**
    Adds checkbox (T2GCheckboxButton) when going to edit mode.
    
    :param: selected Flag indicating if created checkbox should be selected.
    */
    func addMultipleChoiceButton(selected: Bool) {
        let size = self.frame.size.height * 0.5
        let x = CGFloat(0.0)
        let y = (self.frame.size.height - size) / 2
        let frame = CGRectMake(x, y, size, size)
        
        let button = T2GCheckboxButton(frame: frame)
        button.wasSelected = selected
        button.addTarget(self, action: #selector(T2GCell.multipleChoiceButtonPressed(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        button.tag = T2GViewTags.checkboxButton
        button.alpha = 0.0
        self.addSubview(button)
        self.sendSubviewToBack(button)
        
        UIView.animateWithDuration(0.15, animations: { () -> Void in
            button.alpha = 1.0
            }, completion: { (_) -> Void in
                self.bringSubviewToFront(button)
        })
    }
    
    /**
    Gets called when checkbox (T2GCheckboxButton) is pressed in edit mode. Marks the checkbox accordingly and redirects the action to the delegate.
    
    :param: sender T2GCheckboxButton that has been pressed.
    */
    func multipleChoiceButtonPressed(sender: T2GCheckboxButton) {
        sender.wasSelected = !sender.wasSelected
        self.delegate?.didSelectMultipleChoiceButton(self.tag, selected: sender.wasSelected)
    }
    
    //MARK: - Helper methods
    
    /**
    Calculates coordinates for buttons in the drawer.
    
    :param: count Number of buttons.
    :param: mode T2GLayoutMode in which the T2GScrollView is.
    :returns: Tuple (frames: [CGRect], offsetMultiplier: CGFloat) - array of frames for the buttons and multipler for how wide the content view of the scrollView needs to be to open as far as it is necessary.
    */
    func coordinatesForButtons(count: Int, mode: T2GLayoutMode) -> (frames: [CGRect], offsetMultiplier: CGFloat) {
        let buttonSize: CGFloat = 12.0
        var coords: [CGRect] = []
        var multiplier: CGFloat = 1.0
        
        if mode == .Table {
            let m = (self.frame.size.width - self.frame.size.height) / 4
            let margin = self.frame.height + m/2 - buttonSize / 2
            let y = (self.frame.size.height - CGFloat(buttonSize)) / 2.0
            
            for index in 0..<count {
                let x = margin + (m * CGFloat(index))
                coords.append(CGRectMake(x, y, buttonSize, buttonSize))
                multiplier = 1 + (1 - self.frame.height/self.frame.width)
            }
        } else {
            let padding = self.iconView.frame.height / 4
            let imgPadding = buttonSize / 2
            
            switch self.buttonCount {
            case 1...4:
                coords.append(CGRectMake(padding + imgPadding, padding + imgPadding, buttonSize, buttonSize))
                fallthrough
            case 2...4:
                coords.append(CGRectMake(padding * 3 - imgPadding, padding + imgPadding, buttonSize, buttonSize))
                fallthrough
            case 3,4:
                coords.append(CGRectMake(padding + imgPadding, padding * 3 - imgPadding, buttonSize, buttonSize))
                fallthrough
            case 4:
                coords.append(CGRectMake(padding * 3 - imgPadding, padding * 3 - imgPadding, buttonSize, buttonSize))
                fallthrough
            default: break
            }
            multiplier = count == 0 ? 1.0 : 2.0
        }
        return (coords, multiplier)
    }
    
    /**
    Helper method to rearrange buttons when changeFrameParadigm method gets called.
    
    :param: mode T2GLayoutMode in which the T2GScrollView is.
    */
    func rearrangeButtons(mode: T2GLayoutMode) {
        let coordinateData = self.coordinatesForButtons(self.buttonCount, mode: mode)
        let origins = coordinateData.frames
        
        for index in 0..<self.buttonCount {
            if let view = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                let frame = origins[index]
                view.minOriginCoord = frame.origin
                view.frame = frame
            }
        }
        
        self.scrollView.contentSize = CGSizeMake(self.frame.size.width * coordinateData.offsetMultiplier, self.frame.size.height)
    }
    
    /**
    Proportionally calculates the frames of main title and detail title.
    
    :param: frame The frame to use for the calculations.
    :returns: Tuple (header: CGRect, detail: CGRect) - header for main title frame and detail for detail frame.
    */
    private func framesForLabels(frame: CGRect) -> (header: CGRect, detail: CGRect) {
        let headerHeight = frame.size.height * 0.25
        let detailHeight = frame.size.height * 0.15
        let headerWidth = frame.size.width - (frame.size.height + 10) - 100
        let detailWidth = headerWidth * 0.75
        
        let headerMargin = (frame.size.height - headerHeight - detailHeight) / 2 - 5
        let headerFrame = CGRectMake(frame.size.height + 20, headerMargin, headerWidth, headerHeight)
        let detailFrame = CGRectMake(frame.size.height + 20, headerMargin + headerHeight + 5, detailWidth, detailHeight)
        
        return (headerFrame, detailFrame)
    }
    
    
    
    
    
    func moreButtonImagePressed(sender: UIButton) {
//        self.delegate?.cellStartedSwiping(self.tag)
//        self.moveButtonsInHierarchy(true)
        if self.swipeDirection == .Left {
            self.closeCell()
        } else if swipeDirection == .Right {
            self.swipeDirection = .Left
            self.handleScrollEnd(self.scrollView)
        }
    }
    
    //MARK: - Scroll view delegate methods
    
    /**
    Helper method that handles the end of scroll motion - closes or opens the drawer.
    
    :param: scrollView The UIScrollView where scrolling motion happened.
    */
    func handleScrollEnd(scrollView: UIScrollView) {
        var x: CGFloat = 0
        if self.mode == .Table {
            x = self.swipeDirection == .Right ? 0 : self.frame.size.width - self.iconView.frame.size.width
        } else {
            x = self.swipeDirection == .Right ? 0 : self.frame.size.width
        }
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        }, completion: { (_) -> Void in
            if self.swipeDirection == .Right {
                self.delegate?.didCellClose(self.tag)
            } else {
                self.delegate?.didCellOpen(self.tag)
                self.moveButtonsInHierarchy(false)
            }
        })
    }
    
    /**
    Helper method that sends drawer buttons to front/back in the view hierarchy while the scrollView gets scrolled.
    
    :param: shouldHide Flag determining whether the scrollView is getting closed or opened.
    */
    func moveButtonsInHierarchy(shouldHide: Bool) {
        for index in 0...3 {
            if let view = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                if shouldHide {
                    self.sendSubviewToBack(view)
                } else {
                    self.bringSubviewToFront(view)
                }
            }
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate when the scroll view is about to start scrolling the content.
    
    Informs the delegate that swiping motion began and moves buttons in hierarchy so they can be tapped.
    
    :param: scrollView The scroll-view object that is about to scroll the content view.
    */
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.delegate?.cellStartedSwiping(self.tag)
        self.moveButtonsInHierarchy(true)
    }
    
    /**
    Default Cocoa API - Tells the delegate when dragging ended in the scroll view.
    
    If dragging stopped by user (= no deceleration), handleScrollEnd gets called (open/close so it doesn't stay half-way open).
    
    :param: scrollView The scroll-view object that finished scrolling the content view.
    :param: decelerate True if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
    */
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.handleScrollEnd(scrollView)
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate that the scroll view is starting to decelerate the scrolling movement.
    
    Method handleScrollEnd gets called (open/close so it doesn't stay half-way open).
    
    :param: scrollView The scroll-view object that is decelerating the scrolling of the content view.
    */
    func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.handleScrollEnd(scrollView)
    }
    
    /**
    Default Cocoa API - Tells the delegate when a scrolling animation in the scroll view concludes.
    
    Shows buttons if the drawer was opened.
    
    :param: scrollView The scroll-view object that is performing the scrolling animation.
    */
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if self.swipeDirection == .Left {
            self.moveButtonsInHierarchy(false)
        }
    }
    
    /**
    Default Cocoa API - Tells the delegate when the user scrolls the content view within the receiver.
    
    Animates buttons while scrollView gets scrolled (bigger while opening, smaller while closing). Also determines direction of the swipe.
    
    :param: scrollView The scroll-view object in which the scrolling occurred.
    */
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let tailPosition = -scrollView.contentOffset.x + self.backgroundView.frame.size.width
        let sizeDifference = scrollView.contentOffset.x - self.lastContentOffset
        
        for index in 0..<self.buttonCount {
            if let button = self.viewWithTag(T2GViewTags.cellDrawerButtonConstant + index) as? T2GCellDrawerButton {
                button.resize(tailPosition, sizeDifference: sizeDifference)
            }
        }
        
        if self.lastContentOffset < scrollView.contentOffset.x {
            self.swipeDirection = .Left
        } else {
            self.swipeDirection = .Right
        }
        
        self.lastContentOffset = scrollView.contentOffset.x
    }
    
    //MARK: - T2GDragAndDropOwner delegate methods
    
    /**
    Adds long press gesture to the scrollView of the cell. It has to be done this way, because swiping is superior to long press. By this, the swiping gesture is always performed when user wants it to be performed.
    
    :param: recognizer Long press gesture created when draggable flag is set to true.
    */
//    func addGestureRecognizerToView(recognizer: UILongPressGestureRecognizer) {
//        self.scrollView?.addGestureRecognizer(self.longPressGestureRecognizer!)
//    }
}
