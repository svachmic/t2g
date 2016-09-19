//
//  ViewController.swift
//  TabSplitView - T2G Example
//
//  Created by Michal Švácha on 20/03/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Custom ExampleView controller. Is embedded in UINavigation controller in the storyboard.
*/
class ExampleViewController: T2GViewController, T2GViewControllerDelegate, T2GDropDelegate, T2GScrollViewDataDelegate, T2GNavigationBarMenuDelegate {
    
    var detailViewController: DetailViewController? = nil
    
    var modelArray: [Int] = []
    var modelArray2: [Int] = []
    var modelArray3: [Int] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            if controllers.count > 1 {
                let ctr = controllers[controllers.count - 1]
                print(ctr)
                self.detailViewController = (controllers[controllers.count - 1] as! UINavigationController).topViewController as? DetailViewController
            }
        }
        
        for index in 0..<10 {
            modelArray.append(index)
            modelArray2.append(index)
            modelArray3.append(index)
        }

        var rightButton_menu: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self.navigationController!, action: "toggleBarMenu")
        self.navigationItem.rightBarButtonItems = [rightButton_menu]
        
        self.isHidingEnabled = false
        
        if let navCtr = self.navigationController as? T2GNaviViewController {
            navCtr.menuDelegate = self
            navCtr.navigationBar.barTintColor = UIColor(named: .pydOrange)
            navCtr.navigationBar.tintColor = .white
            
            if self.title == nil {
                self.title = "Root"
            }
            
            let text = self.title!
            let titleWidth = navCtr.navigationBar.frame.size.width * 0.57
            let titleView = T2GNavigationBarTitle(frame: CGRect(x: 0.0, y: 0.0, width: titleWidth, height: 42.0), text: text, shouldHighlightText: true)
            titleView.addTarget(self.navigationController, action: "showPathPopover:", for: UIControlEvents.touchUpInside)
            
            self.navigationItem.titleView = titleView
        }
        
        self.scrollView.customRefreshControl = UIRefreshControl()
        self.scrollView.customRefreshControl!.addTarget(self, action: #selector(ExampleViewController.handlePullToRefresh(_:)), for: UIControlEvents.valueChanged)
        self.scrollView.customRefreshControl!.tag = T2GViewTags.customRefreshControl
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.delegate == nil {
            self.scrollView.dataDelegate = self
            self.delegate = self
            self.dropDelegate = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.scrollView.alignVisibleCells()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func handlePullToRefresh(_ sender: UIRefreshControl) {
        //sender.attributedTitle = NSAttributedString(string: "\n Refreshing")
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            Thread.sleep(forTimeInterval: 1.5)
            DispatchQueue.main.async(execute: {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let lastUpdate = String(format:"Last updated on %@", formatter.string(from: Date()))
                sender.attributedTitle = NSAttributedString(string: lastUpdate)
                self.automaticSnapStatus = .willSnap
                
                self.reloadScrollView()
                sender.endRefreshing()
            });
        });
    }
    
    //MARK: T2GViewController delegate methods
    
    /// Datasource methods
    
    func cellForIndexPath(_ indexPath: IndexPath, frame: CGRect) -> T2GCell {
        var view: T2GCell?
        switch((indexPath as NSIndexPath).section) {
        case 0:
            view = T2GCell(header: "R: \(self.modelArray[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons([], mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        case 1:
            view = T2GCell(header: "R: \(self.modelArray2[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons([], mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        case 2:
            view = T2GCell(header: "R: \(self.modelArray3[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons([], mode: self.scrollView.layoutMode)
            view!.draggable = true
            view!.draggableDelegate = self
            break
        default:
            view = T2GCell(header: "", detail: "\(indexPath)", frame: frame, mode: self.scrollView.layoutMode)
            view!.setupButtons([], mode: self.scrollView.layoutMode)
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
        switch((indexPath as NSIndexPath).section) {
        case 0:
            cell.headerLabel?.text = "R: \(self.modelArray[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        case 1:
            cell.headerLabel?.text = "R: \(self.modelArray2[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        case 2:
            cell.headerLabel?.text = "R: \(self.modelArray3[(indexPath as NSIndexPath).row]) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)"
            cell.detailLabel?.text = "\(indexPath)"
            break
        default:
            break
        }
    }
    
    /// View methods
    
    func dimensionsForCell(_ mode: T2GLayoutMode) -> (width: CGFloat, height: CGFloat, padding: CGFloat) {
        var width: CGFloat = 0.0
        var height: CGFloat = 0.0
        
        if mode == .collection {
            width = 94.0
            height = 94.0
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
        if (indexPath as NSIndexPath).row%2 == 0 {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let newVC: ExampleViewController = storyboard.instantiateViewController(withIdentifier: "ExampleVC") as! ExampleViewController
            newVC.title = "R: \((indexPath as NSIndexPath).row) | S: \((indexPath as NSIndexPath).section) | T: \(self.scrollView.indexForIndexPath(indexPath) + T2GViewTags.cellConstant)"
            self.navigationController?.pushViewController(newVC, animated: true)
        } else {
            self.tabBarController?.performSegue(withIdentifier: "showDetail", sender: nil)
        }
    }
    
    func willDeselectCellAtIndexPath(_ indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func didDeselectCellAtIndexPath(_ indexPath: IndexPath) {
        //
    }
    
    func didSelectDrawerButtonAtIndex(_ indexPath: IndexPath, buttonIndex: Int) {
        if buttonIndex == 0 {
            switch((indexPath as NSIndexPath).section) {
            case 0:
                self.modelArray.remove(at: (indexPath as NSIndexPath).row)
                break
            case 1:
                self.modelArray2.remove(at: (indexPath as NSIndexPath).row)
                break
            case 2:
                self.modelArray3.remove(at: (indexPath as NSIndexPath).row)
                break
            default:
                break
            }
            
            self.removeRowsAtIndexPaths([indexPath])
        } else if buttonIndex == 1 {
            switch((indexPath as NSIndexPath).section) {
            case 0:
                self.modelArray.insert(42, at: (indexPath as NSIndexPath).row + 1)
                break
            case 1:
                self.modelArray2.insert(42, at: (indexPath as NSIndexPath).row + 1)
                break
            case 2:
                self.modelArray3.insert(42, at: (indexPath as NSIndexPath).row + 1)
                break
            default:
                break
            }
            
            let indexPath = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: (indexPath as NSIndexPath).section)
            self.insertRowAtIndexPath(indexPath)
        } else {
            self.toggleEdit()
        }
    }
    
    func willRemoveCellAtIndexPath(_ indexPath: IndexPath) {
        switch((indexPath as NSIndexPath).section) {
        case 0:
            self.modelArray.remove(at: (indexPath as NSIndexPath).row)
            break
        case 1:
            self.modelArray2.remove(at: (indexPath as NSIndexPath).row)
            break
        case 2:
            self.modelArray3.remove(at: (indexPath as NSIndexPath).row)
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
            
            switch((indexPath as NSIndexPath).section) {
            case 0:
                self.modelArray.remove(at: (indexPath as NSIndexPath).row)
                break
            case 1:
                self.modelArray2.remove(at: (indexPath as NSIndexPath).row)
                break
            case 2:
                self.modelArray3.remove(at: (indexPath as NSIndexPath).row)
                break
            default:
                break
            }
            
            completion()
        }
    }
    
    //MARK: - T2GNavigationBarMenu delegate method
    
    func heightForMenu() -> CGFloat {
        return 48.0 * 5.0
    }
    
    func numberOfCells() -> Int {
        return 5
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
            label.text = "Sort"
            break
        case 1:
            label.text = "Transform view"
            break
        case 2:
            label.text = "Bookmark folder"
            break
        case 3:
            label.text = "Add ..."
            break
        case 4:
            label.text = "Edit folder contents"
            break
        default:
            break
        }
        
        return view
    }
    
    func didSelectButton(_ index: Int) {
        switch(index) {
        case 0:
            print("Sort not implemented yet.")
            break
        case 1:
            self.transformView()
            break
        case 2:
            print("Bookmarking not implemented yet.")
            break
        case 3:
            self.modelArray3.insert(42, at: 0)
            let indexPath = IndexPath(row: 0, section: 0)
            self.insertRowAtIndexPath(indexPath)
            break
        case 4:
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

