import UIKit
import Foundation

enum SetNavBtnItems: CaseIterable {
    case search
    case notifications
    case display

    var systemName: String {
        switch self {
        case .search:
            return "magnifyingglass"
        case .notifications:
            return "bell"
        case .display:
            return "display"
        }
    }
}

class NavButtonItemsModel {
    weak var viewController: UIViewController?

    init(viewController: UIViewController) {
        self.viewController = viewController
        updateThemeAppearance(for: viewController.traitCollection.userInterfaceStyle)
    }
    
    func updateThemeAppearance(for interfaceStyle: UIUserInterfaceStyle) {
        if let navigationController = viewController?.navigationController {
            let navigationBarAppearance = UINavigationBarAppearance()
            if interfaceStyle == .dark {
                navigationBarAppearance.backgroundColor = .black
            } else {
                navigationBarAppearance.backgroundColor = .white
            }
            navigationController.navigationBar.standardAppearance = navigationBarAppearance
            if #available(iOS 15.0, *) {
                navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
            }
        }
    }
    
    func setNavBtnItems() {
        var barButtonItems: [UIBarButtonItem] = []
        for (index, item) in SetNavBtnItems.allCases.enumerated() {
            let barButtonItem = UIBarButtonItem(image: UIImage(systemName: item.systemName),
                                                style: .plain,
                                                target: self,
                                                action: #selector(topButtonTapped(_:)))
            barButtonItem.tag = index
            barButtonItems.append(barButtonItem)
        }
        viewController?.navigationItem.setRightBarButtonItems(barButtonItems, animated: true)
    }

    @objc func topButtonTapped(_ sender: UIBarButtonItem) {
        guard let itemType = SetNavBtnItems.allCases[safe: sender.tag] else { return }
        switch itemType {
        case .search:
            presentSearchViewController()
        case .notifications:
            navigateToNotificationLogViewController()
        case .display:
            presentAlertController(title: "選取裝置", message: nil)
        }
    }


    func presentAlertController(title: String, message: String?) {
        guard let viewController = viewController else { return }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = NSTextAlignment.left
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: [NSAttributedString.Key.paragraphStyle: titleParagraphStyle])
        alertController.setValue(titleAttributedString, forKey: "attributedTitle")
        
        alertController.addAction(UIAlertAction(title: "透過電視代碼連結", style: .default, handler: { (_) in
            // buttonLeft 的處理代碼
        }))
        
        alertController.addAction(UIAlertAction(title: "了解詳情", style: .default, handler: { (_) in
            // buttonMid 的處理代碼
        }))
        
        for action in alertController.actions {
            action.setValue(NSTextAlignment.left.rawValue, forKey: "titleTextAlignment")
        }
        
        viewController.present(alertController, animated: true, completion: nil)
    }

    func navigateToNotificationLogViewController() {
        guard let viewController = viewController else { return }
        let notificationLogVC = NotificationLogVC()
        notificationLogVC.title = "通知"
        viewController.navigationController?.pushViewController(notificationLogVC, animated: true)
    }
    
    func presentSearchViewController() {
        guard let viewController = viewController else { return }
        let searchVC = SearchViewController()
        searchVC.title = viewController.navigationItem.searchController?.searchBar.text ?? ""
        viewController.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func handleTraitCollectionChange(previousTraitCollection: UITraitCollection?) {
        guard let viewController = viewController else { return }
        if previousTraitCollection?.userInterfaceStyle != viewController.traitCollection.userInterfaceStyle {
            updateThemeAppearance(for: viewController.traitCollection.userInterfaceStyle)
            updateTabBarAppearance(for: viewController.traitCollection.userInterfaceStyle)
        }
    }

    func updateTabBarAppearance(for interfaceStyle: UIUserInterfaceStyle) {
        if let tabBar = viewController?.tabBarController?.tabBar {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            
            if interfaceStyle == .dark {
                tabBarAppearance.backgroundColor = .black
            } else {
                tabBarAppearance.backgroundColor = .white
            }
            
            tabBar.standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}

