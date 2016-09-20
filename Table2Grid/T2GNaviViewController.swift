//
//  T2GNaviViewController.swift
//  Table2Grid Framework
//
//  Created by Michal Švácha on 13/04/15.
//  Copyright (c) 2015 Michal Švácha. All rights reserved.
//

import UIKit

/**
Extension of UINavigationController to support completion handler when popped to view controller.
*/
extension UINavigationController {
    
    /**
    Pops to given viewController in transaction and performs given closure when popping has ended.
    
    - parameter vc: View controller to be popped to.
    - parameter handler: Optional handler to be performed after popping has ended.
    */
    func popToViewControllerWithHandler(_ vc: UIViewController, handler: (() -> Void)?) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(handler)
        self.popToViewController(vc, animated: true)
        CATransaction.commit()
    }
}

/**
Extension of UIViewController to obtain completion handler when popped to the view controller.
*/
extension UIViewController {
    
    /**
    Returns completion closure to be performed.
    
    - returns: Optional closure.
    */
    func completionHandlerWhenAppeared() -> (() -> Void)? {
        return nil
    }
}

/**
Protocol for path view controller setup - prependable content and icons for view controllers. Does not need to be implemented to fully function. Serves for esthetical reasons.
*/
protocol T2GNaviPathDelegate {
    
    /**
    Gets called when path is being built to know how many items should be prepended.
    
    - returns: Number of items to be prepended.
    */
    func pathPrependableItemCount() -> Int
    
    /**
    Gets called after the pathPrependableItemCount method in a for cycle from 0 to n to obtain attributes for all prependable items.
    
    - DISCUSSION: Could be made as returning optional, since Swift doesn't provide optional protocol methods. But then again, this method doesn't get called if the count is 0, so it can be implemented with a one-liner `{ return ("", "") }`
    
    - parameter index: Index of the prependable item.
    - returns: Tuple with the name and the image name to use.
    */
    func pathPrependableItemAttributes(_ index: Int) -> (name: String, image: String)
    
    /**
    Gets called when prepended item is selected. In some cases it could be desirable to pop all the way to the root and sometimes not - that's when this method comes in. Is called every time any prependable index is selected.
    
    - parameter index: Index of the prependable item.
    - returns: Boolean flag stating whether or not should the view hierarchy should be popped to its root.
    */
    func shouldPopToRootWhenPrependedIndexIsSelected(_ index: Int) -> Bool
    
    /**
    Gets called when path is being built to know what icon to use for the given view controller.
    
    - parameter viewController: UIViewController on the stack of viewControllers in UINavigationController.
    - returns: Image asset name.
    */
    func pathImageForViewController(_ viewController: UIViewController) -> String
    
    /**
    Gets called when prependable item on given index got selected.
    
    - parameter index: Index of the prepended item.
    */
    func didSelectPrependableIndex(_ index: Int)
}

/**
Custom UINavigationController that enables slight delay between segues (for enter/exit animation) and that adds status bar background on top of the navigation bar (settable).
*/
class T2GNaviViewController: UINavigationController, UIPopoverPresentationControllerDelegate, T2GPathViewControllerDelegate {
    /// Default value is 0 - no delay.
    var segueDelay: Double = 0.0
    var statusBarBackgroundView: UIView?
    var menuDelegate: T2GNavigationBarMenuDelegate?
    var pathDelegate: T2GNaviPathDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
    Adds status bar view behind the status bar for graphical effect.
    
    - returns: The status bar background view.
    */
    func addStatusBarBackgroundView() -> UIView {
        if let view = self.view.viewWithTag(T2GViewTags.statusBarBackgroundView) {
            return view
        } else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 20))
            view.tag = T2GViewTags.statusBarBackgroundView
            view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.07)
            self.view.addSubview(view)
            return view
        }
    }
    
    /**
    Pops current view controller. In case previous view controller in the stack has isHidingEnabled flag set to true, it shows the bar so it doesn't mess up with the UI while animating the cells on the way back.
    
    - parameter animated: Default Cocoa API behavior - Set this value to YES to animate the transition.
    - returns: The view controller that was popped from the stack.
    */
    override func popViewController(animated: Bool) -> UIViewController? {
        self.toggleBarMenu(true)
        
        let poppedViewController = super.popViewController(animated: animated)
        if let visibleViewController = self.visibleViewController as? T2GViewController {
            if visibleViewController.isHidingEnabled {
                visibleViewController.showBar(UIDeviceOrientationIsLandscape(UIDevice.current.orientation))
            }
            
            visibleViewController.scrollView.animateSubviewCells(false)
            
            if let mDelegate = visibleViewController as? T2GNavigationBarMenuDelegate {
                self.menuDelegate = mDelegate
            }
        }
        return poppedViewController
    }
    
    /**
    Pushes new view controller on the stack with delay. The delay serves to create a gap to let exit animation be more visible.
    
    - parameter viewController: The view controller to push onto the stack.
    - parameter animated: Default Cocoa API behavior - Specify YES to animate the transition or NO if you do not want the transition to be animated.
    */
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        self.toggleBarMenu(true)
        
        if let vc = self.visibleViewController as? T2GViewController {
            if vc.isHidingEnabled {
                vc.showBar(UIDeviceOrientationIsLandscape(UIDevice.current.orientation))
            }
            
            vc.scrollView.animateSubviewCells(true)
        }
        
        self.delay(self.segueDelay, closure: { () -> Void in
            self.performPush(viewController, animated: animated)
        })
    }
    
    /**
    Helper method to perform delay dispatch (unable to call the same method inside dispatch_after) of push.
    
    - parameter viewController: The view controller to push onto the stack.
    - parameter animated: Default Cocoa API behavior - Specify YES to animate the transition or NO if you do not want the transition to be animated.
    */
    func performPush(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: animated)
    }
    
    /**
    Helper method that dispatches method after certain time passes.
    
    - parameter delay: Time to wait before closure is called.
    - parameter closure: Closure to be performed after the delay time passes.
    */
    func delay(_ delay: Double, closure:@escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    /**
    Proxy function of toggleBarMenu(forceClose) for UIBarButtonItem action call.
    */
    func toggleBarMenuSelector() {
        self.toggleBarMenu(false)
    }
    
    /**
    Opens/collapses navigation bar menu which slides below from the top of the navigation bar. Works like a switch on default, but is able to accept flag forcing the menu to disappear (handy to use when VC is about to be rotated and it is not desired to have a menu opened).
    
    - parameter forceClose: Boolean flag indicating whether toggle should be automatic or forced close only.
    */
    func toggleBarMenu(_ forceClose: Bool) {
        if let height: CGFloat = self.menuDelegate?.heightForMenu() {
            let dismissClosure = { () -> Bool in
                if let menu = self.view.viewWithTag(T2GViewTags.navigationBarMenu) {
                    let triangle = self.view.viewWithTag(T2GViewTags.navigationBarTriangle)
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        triangle?.frame = CGRect(x: triangle!.frame.origin.x, y: triangle!.frame.origin.y, width: triangle!.frame.size.width, height: 0)
                        menu.frame = CGRect(x: 0, y: self.navigationBar.frame.size.height - height, width: self.navigationBar.frame.size.width, height: height)
                    }, completion: { (_) -> Void in
                        triangle?.removeFromSuperview()
                        menu.removeFromSuperview()
                    })
                    return true
                } else {
                    return false
                }
            }
            
            if forceClose {
                _ = dismissClosure()
            } else {
                if !dismissClosure() {
                    let statusBarOffset: CGFloat = UIApplication.shared.isStatusBarHidden ? 0 : 20
                    
                    let menu = T2GNavigationBarMenu(frame: CGRect(x: 0, y: self.navigationBar.frame.size.height - height, width: self.navigationBar.frame.size.width, height: height), delegate: self.menuDelegate)
                    menu.tag = T2GViewTags.navigationBarMenu
                    menu.backgroundColor = UIColor.white
                    menu.layer.masksToBounds = false
                    menu.layer.shadowOffset = CGSize(width: 0, height: 6)
                    menu.layer.shadowRadius = 2.0
                    menu.layer.shadowOpacity = 0.45
                    self.view.insertSubview(menu, belowSubview: self.navigationBar)
                    
                    let triangle = T2GTriangleView(frame: CGRect(x: (menu.frame.size.width - 32.0) / CGFloat(2), y: self.navigationBar.frame.size.height + statusBarOffset, width: 32.0, height: 0.0))
                    triangle.tag = T2GViewTags.navigationBarTriangle
                    triangle.backgroundColor = self.navigationBar.barTintColor
                    triangle.alpha = self.navigationBar.isTranslucent ? 0.85 : 1.0
                    self.view.insertSubview(triangle, aboveSubview: self.navigationBar)
                    
                    UIView.animate(withDuration: 0.3, animations: { () -> Void in
                        menu.frame = CGRect(x: 0, y: self.navigationBar.frame.size.height + statusBarOffset, width: self.navigationBar.frame.size.width, height: height)
                        triangle.frame = CGRect(x: triangle.frame.origin.x, y: triangle.frame.origin.y, width: triangle.frame.size.width, height: 12.0)
                    })
                }
            }
        }
    }
    
    //MARK: - UIPopover controller methods
    
    /**
    Instantiates and shows PathView controller as UIPopover.
    
    - parameter sender: UIButton from which the PathView controller will be shown.
    */
    func showPathPopover(_ sender: UIButton) {
        self.toggleBarMenu(true)
        
        let pathViewController = T2GPathViewController()
        pathViewController.modalPresentationStyle = .popover
        pathViewController.preferredContentSize = CGSize(width: self.view.frame.width * 0.8, height: 256)
        pathViewController.path = self.buildPath()
        pathViewController.prependedItemCount = self.pathDelegate?.pathPrependableItemCount() ?? 0
        pathViewController.pathDelegate = self
        
        let popoverMenuViewController = pathViewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .any
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = sender
        
        popoverMenuViewController?.sourceRect = CGRect(x: sender.frame.size.width / 2, y: sender.frame.size.height - 5, width: 1, height: 1)
        self.present(pathViewController, animated: true, completion: nil)
    }
    
    /**
    Helper method for when PathView controller gets presented as UIPopover.
    
    - parameter controller: Default Cocoa API - The presentation controller that is managing the size change.
    - returns: Default Cocoa API - The new presentation style, which must be either UIModalPresentationFullScreen or UIModalPresentationOverFullScreen.
    */
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    /**
    Builds path comprising of all ViewControllers on the stack.
    
    - returns: Array of Dictionary objects containing name and image to be displayed.
    */
    func buildPath() -> [[String : String]] {
        var path = [[String : String]]()
        
        if let prependableCount = self.pathDelegate?.pathPrependableItemCount() {
            for index in 0..<prependableCount {
                let attributes = self.pathDelegate!.pathPrependableItemAttributes(index)
                path.append(["name" : attributes.name, "image" : attributes.image])
            }
        }
        
        for vc in (self.viewControllers ) {
            let image = self.pathDelegate?.pathImageForViewController(vc) ?? ""
            path.append(["name" : vc.title!, "image" : image])
        }
        
        return path
    }
    
    //MARK: T2GPathViewController delegate methods
    
    /**
    Redirects to pathDelegate.
    
    - returns: Boolean flag indicating whether to pop or not - if pathDelegate is nil, returns false.
    */
    func shouldPopToRootWhenPrependedIndexIsSelected(_ index: Int) -> Bool {
        return self.pathDelegate?.shouldPopToRootWhenPrependedIndexIsSelected(index) ?? false
    }
    
    /**
    Redirects to pathDelegate.
    
    - parameter index: Index of the prepended item.
    */
    func didSelectPrependedIndex(_ index: Int) {
        self.pathDelegate?.didSelectPrependableIndex(index)
    }
    
    /**
    Pops to selected ViewController on the stack.
    
    - parameter index: Index of the selected ViewController.
    */
    func didSelectViewController(_ index: Int, completion: (() -> Void)?) {
        self.toggleBarMenu(true)
        let vc = self.viewControllers[index] 
        
        if let t2gVC = vc as? T2GViewController {
            if t2gVC.isHidingEnabled {
                t2gVC.showBar(UIDeviceOrientationIsLandscape(UIDevice.current.orientation))
            }
            
            t2gVC.scrollView.animateSubviewCells(false)
            
            if let mDelegate = t2gVC as? T2GNavigationBarMenuDelegate {
                self.menuDelegate = mDelegate
            }
        }
        
        self.popToViewControllerWithHandler(vc, handler: completion)
    }
    
    /**
    Returns closure to be performed when root view controller appears.
    
    - returns: Optional closure.
    */
    func completionHandlerAfterRootViewControllerAppears() -> (() -> Void)? {
        if self.viewControllers.count > 0 {
            return self.viewControllers[0].completionHandlerWhenAppeared()
        }
        
        return nil
    }
}
