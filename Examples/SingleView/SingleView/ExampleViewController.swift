//
//  ViewController.swift
//  SingleView - T2G Example
//
//  Created by Michal Švácha on 20/03/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

class ExampleViewController: T2GViewController, T2GViewControllerDelegate, T2GDropDelegate, T2GScrollViewDataDelegate, T2GNavigationBarMenuDelegate {
    
    var modelArray: [Int] = []
    var modelArray2: [Int] = []
    var modelArray3: [Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        for index in 0..<10 {
            modelArray.append(index)
            modelArray2.append(index)
            modelArray3.append(index)
        }
        
        let rightButton_menu: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self.navigationController!, action: #selector(T2GNaviViewController.toggleBarMenuSelector))
        self.navigationItem.rightBarButtonItems = [rightButton_menu]
        
        self.isHidingEnabled = true
        
        if let navCtr = self.navigationController as? T2GNaviViewController {
            self.statusBarBackgroundView = navCtr.addStatusBarBackgroundView()
            
            navCtr.menuDelegate = self
            navCtr.navigationBar.barTintColor = UIColor(named: .pydOrange)
            navCtr.navigationBar.tintColor = .white
            
            if self.title == nil {
                self.title = "Root"
            }
            
            let text = self.title!
            let titleWidth = navCtr.navigationBar.frame.size.width * 0.57
            let titleView = T2GNavigationBarTitle(frame: CGRect(x: 0.0, y: 0.0, width: titleWidth, height: 42.0), text: text, shouldHighlightText: true)
            titleView.addTarget(self.navigationController, action: #selector(T2GNaviViewController.showPathPopover(_:)), for: UIControlEvents.touchUpInside)
            
            self.navigationItem.titleView = titleView
        }
        
        self.scrollView.customRefreshControl = UIRefreshControl()
        self.scrollView.customRefreshControl!.addTarget(self, action: #selector(ExampleViewController.handlePullToRefresh(sender:)), for: UIControlEvents.valueChanged)
        self.scrollView.customRefreshControl!.tag = T2GViewTags.customRefreshControl
    }
    
    /**
    */
    func titleViewPressed() {
        print("Title pressed")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.delegate == nil {
            self.scrollView.dataDelegate = self
            self.delegate = self
            self.dropDelegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handlePullToRefresh(sender: UIRefreshControl) {
        //sender.attributedTitle = NSAttributedString(string: "\n Refreshing")
        
        /*
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0).asynchronously(DispatchQueue.globalexecute: {
            Thread.sleepForTimeInterval(1.5)
            dispatch_get_main_queue().asynchronously(DispatchQueue.mainexecute: {
                let formatter = DateFormatter()
                formatter.dateStyle = .MediumStyle
                let lastUpdate = String(format:"Last updated on %@", formatter.stringFromDate(NSDate()))
                sender.attributedTitle = NSAttributedString(string: lastUpdate)
                self.automaticSnapStatus = .WillSnap
                
                self.reloadScrollView()
                sender.endRefreshing()
            });
        });
        */
    }
    
    //MARK: T2GViewController delegate methods
    
    /// Datasource methods
    
    func cellForIndexPath(_ indexPath: IndexPath, frame: CGRect) -> T2GCell {
        var view: T2GCell?
        
        var buttonsInfo: [(normalImage: String, selectedImage: String, optionalText: String?)] = []
        buttonsInfo.append((normalImage: "", selectedImage: "", optionalText: nil))
        buttonsInfo.append((normalImage: "", selectedImage: "", optionalText: nil))
        buttonsInfo.append((normalImage: "", selectedImage: "", optionalText: nil))
        buttonsInfo.append((normalImage: "", selectedImage: "", optionalText: nil))
        
        switch(indexPath.section) {
        case 0:
            view = T2GCell(header: "R: \(self.modelArray[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons(buttonsInfo, mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        case 1:
            view = T2GCell(header: "R: \(self.modelArray2[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons(buttonsInfo, mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        case 2:
            view = T2GCell(header: "R: \(self.modelArray3[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons(buttonsInfo, mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        default:
            view = T2GCell(header: "", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons(buttonsInfo, mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        }
        
        return view!
    }
    
    func numberOfSections() -> Int {
        return 3
    }
    
    func numberOfCellsInSection(_ section: Int) -> Int {
        switch(section) {
        case 0:
            return self.modelArray.count
        case 1:
            return self.modelArray2.count
        case 2:
            return self.modelArray3.count
        default:
            return 0
        }
    }
    
    func titleForHeaderInSection(_ section: Int) -> String? {
        return "Section #\(section + 1)"
    }
    
    func updateCellForIndexPath(_ cell: T2GCell, indexPath: IndexPath) {
        switch(indexPath.section) {
        case 0:
            cell.headerLabel?.text = "R: \(self.modelArray[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        case 1:
            cell.headerLabel?.text = "R: \(self.modelArray2[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        case 2:
            cell.headerLabel?.text = "R: \(self.modelArray3[indexPath.row]) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        default:
            break
        }
    }
    
    /// View methods
    
    func cellPadding(mode: T2GLayoutMode) -> CGFloat {
        return 12.0
    }
    
    func dimensionsForCell(_ mode: T2GLayoutMode) -> (width: CGFloat, height: CGFloat, padding: CGFloat) {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        
        if mode == T2GLayoutMode.collection {
            width = 98.0
            height = 98.0
        } else {
            width = self.scrollView.frame.size.width * 0.9
            height = 64.0
        }
        
        return (width, height, 12.0)
    }
    
    func dimensionsForSectionHeader() -> CGSize {
        return CGSize(width: 300, height: 32.0)
    }
    
    func willSelectCellAtIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func didSelectCellAtIndexPath(_ indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let newVC: ExampleViewController = (storyboard.instantiateViewController(withIdentifier: "ExampleVC") as! ExampleViewController)
        newVC.title = "R: \(indexPath.row) | S: \(indexPath.section) | T: \(self.scrollView.indexForIndexPath(indexPath as IndexPath) + T2GViewTags.cellConstant)"
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func willDeselectCellAtIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func didDeselectCellAtIndexPath(_ indexPath: IndexPath) {
        //
    }
    
    func didSelectDrawerButtonAtIndex(_ indexPath: IndexPath, buttonIndex: Int) {
        if buttonIndex == 0 {
            switch(indexPath.section) {
            case 0:
                self.modelArray.remove(at: indexPath.row)
                break
            case 1:
                self.modelArray2.remove(at: indexPath.row)
                break
            case 2:
                self.modelArray3.remove(at: indexPath.row)
                break
            default:
                break
            }
            
            self.removeRowsAtIndexPaths([indexPath as IndexPath])
        } else if buttonIndex == 1 {
            switch(indexPath.section) {
            case 0:
                self.modelArray.insert(42, at: indexPath.row + 1)
                break
            case 1:
                self.modelArray2.insert(42, at: indexPath.row + 1)
                break
            case 2:
                self.modelArray3.insert(42, at: indexPath.row + 1)
                break
            default:
                break
            }
            
            let indexPath = IndexPath(row: indexPath.row + 1, section: indexPath.section)
            self.insertRowAtIndexPath(indexPath)
        } else {
            self.toggleEdit()
        }
    }
    
    func willRemoveCellAtIndexPath(_ indexPath: IndexPath) {
        switch(indexPath.section) {
        case 0:
            self.modelArray.remove(at: indexPath.row)
            break
        case 1:
            self.modelArray2.remove(at: indexPath.row)
            break
        case 2:
            self.modelArray3.remove(at: indexPath.row)
            break
        default:
            break
        }
    }
    
    //MARK: T2GDrop delegate methods
    
    func didDropCell(_ cell: T2GCell, onCell: T2GCell, completion: () -> Void, failure: () -> Void) {
        if onCell.tag % 2 != 0 {
            failure()
        } else {
            let indexPath = self.scrollView.indexPathForCell(cell.tag)
            
            switch(indexPath.section) {
            case 0:
                self.modelArray.remove(at: indexPath.row)
                break
            case 1:
                self.modelArray2.remove(at: indexPath.row)
                break
            case 2:
                self.modelArray3.remove(at: indexPath.row)
                break
            default:
                break
            }
            
            completion()
        }
    }
    
    //MARK: - T2GNavigationBarMenu delegate method

    func heightForMenu() -> CGFloat {
        return 48.0 * 2.0
    }

    func numberOfCells() -> Int {
        return 2
    }
    
    func viewForCell(_ index: Int, size: CGSize) -> UIView {
        let view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let ivSize = size.height * 0.7
        let imageView = UIImageView(frame: CGRect(x: 15.0, y: (size.height - ivSize) / CGFloat(2.0), width: ivSize, height: ivSize))
        imageView.backgroundColor = .black
        view.addSubview(imageView)
        
        let x = imageView.frame.origin.x + imageView.frame.size.width + 25.0
        let label = UILabel(frame: CGRect(x: x, y: imageView.frame.origin.y, width: view.frame.size.width - x - 25.0, height: imageView.frame.size.height))
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14.0)
        view.addSubview(label)
        
        switch(index) {
        case 0:
            label.text = "Transform view"
            break
        case 1:
            label.text = "Edit content"
            break
        default:
            break
        }
        
        return view
    }
    
    func didSelectButton(_ index: Int) {
        switch(index) {
        case 0:
            self.transformView()
            break
        case 1:
            self.toggleEdit()
            break
        default:
            break
        }
        
        if let navCtr = self.navigationController as? T2GNaviViewController {
            navCtr.toggleBarMenu(true)
        }
    }
}

