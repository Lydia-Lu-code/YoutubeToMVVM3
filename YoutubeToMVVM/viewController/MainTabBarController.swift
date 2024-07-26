import UIKit

class MainTabBarController: UITabBarController {
    
//    let menuViewController = MenuViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setViewControllers()
 
    }
    
//    @objc func showMenu() {
//        // 將 MenuViewController 視圖疊加在當前視圖控制器的視圖上
//        addChild(menuViewController)
//        view.addSubview(menuViewController.view)
//        menuViewController.didMove(toParent: self)
//
//    }
//    
//    func didSelect(menuItem: MenuViewController.MenuOptions) {
//        // 處理選單選項的選擇
//        print("選擇了選項: \(menuItem.rawValue)")
//        menuViewController.view.removeFromSuperview()
//        menuViewController.removeFromParent()
//    }

    private func setViewControllers() {
        // HomeVC
        let homeVC = HomeViewController(vcType: .home)
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: nil, tag: 0)
        
        // ShortsVC
        let shortsVC = ShortsTableViewController()
        let shortsNav = UINavigationController(rootViewController: shortsVC)
        shortsNav.tabBarItem = UITabBarItem(title: "Shorts", image: nil, tag: 1)
        
        // AddVC
        let addVC = AddVC()
        let addNav = UINavigationController(rootViewController: addVC)
        addNav.tabBarItem = UITabBarItem(title: "Add", image: nil, tag: 2)
        
        // SubscribeVC
        let subscribeVC = SubscribeViewController(vcType: .subscribe)
        let subscribeNav = UINavigationController(rootViewController: subscribeVC)
        subscribeNav.tabBarItem = UITabBarItem(title: "Subscribe", image: nil, tag: 3)
        
        // ContentVC
        let contentTableViewController = ContentTableViewController()
        let contentNav = UINavigationController(rootViewController: contentTableViewController)
        contentNav.tabBarItem = UITabBarItem(title: "Content", image: nil, tag: 4)
        
        // 設置標籤欄控制器的所有子視圖控制器
        self.viewControllers = [homeNav, shortsNav, addNav, subscribeNav, contentNav]
    }
}

