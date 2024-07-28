import UIKit



class BaseViewController: UIViewController, ButtonCollectionCellDelegate {
    
    func didTapFirstButton() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        let menuVC = MenuViewController()
        menuVC.modalPresentationStyle = .overFullScreen
        
        let backgroundView = UIView(frame: window.bounds)
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backgroundView.alpha = 0
        backgroundView.tag = 100
        window.addSubview(backgroundView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        backgroundView.addGestureRecognizer(tapGesture)
        
        let width = window.frame.width * 0.75
        let topInset = window.safeAreaInsets.top
        let bottomInset = window.safeAreaInsets.bottom
        menuVC.view.frame = CGRect(x: -width, y: topInset, width: width, height: window.frame.height - topInset - bottomInset)
        window.addSubview(menuVC.view)
        addChild(menuVC)
        menuVC.didMove(toParent: self)
        
        UIView.animate(withDuration: 0.3, animations: {
            menuVC.view.frame = CGRect(x: 0, y: topInset, width: width, height: window.frame.height - topInset - bottomInset)
            backgroundView.alpha = 1
        })
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        if let menuVC = children.first(where: { $0 is MenuViewController }) as? MenuViewController {
            let width = UIApplication.shared.windows.first?.frame.width ?? 0 * 0.75
            let topInset = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
            UIView.animate(withDuration: 0.3, animations: {
                menuVC.view.frame = CGRect(x: -width, y: topInset, width: width, height: UIApplication.shared.windows.first?.frame.height ?? 0 - topInset - (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
                if let backgroundView = UIApplication.shared.windows.first?.viewWithTag(100) {
                    backgroundView.alpha = 0
                }
            }, completion: { _ in
                menuVC.view.removeFromSuperview()
                menuVC.removeFromParent()
                if let backgroundView = UIApplication.shared.windows.first?.viewWithTag(100) {
                    backgroundView.removeFromSuperview()
                }
            })
        }
    }
    
    var navButtonItemsModel: NavButtonItemsModel!
    
    
    var vcType: ViewControllerType?
    
    init(vcType: ViewControllerType) {
        self.vcType = vcType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    let buttonTitles = [" 📍 ", "全部", "音樂", "遊戲", "合輯", "直播中", "動畫", "寵物", "最新上傳", "讓你耳目一新的影片", "提供意見"]
    
    // 可以在這裡定義和配置你的 ButtonCollectionViewCell
    lazy var buttonCollectionViewCell: ButtonCollectionViewCell = {
        let cell = ButtonCollectionViewCell(frame: .zero)
        cell.delegate = self
        // 在這裡設置額外的配置，例如 cell 的位置和大小等
        return cell
    }()
    
    
    // 定義一個 UIImageView 用於顯示播放器符號
    lazy var playerSymbolImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "play.circle")
        imageView.tintColor = UIColor.systemBlue
        imageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal) // 設置內容壓縮抗壓縮性
        return imageView
    }()
    
    // 定義一個 UILabel 用於顯示 "Shorts" 文字
    lazy var shortsLbl: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Shorts"
        label.textAlignment = .left
        label.textColor = .systemGray
        label.font = UIFont.boldSystemFont(ofSize: 18) // 設置粗體 18PT
        label.setContentCompressionResistancePriority(.required, for: .horizontal) // 設置內容壓縮抗壓縮性
        return label
    }()
    
    // 定義一個 StackView 用於將播放器符號和 "Shorts" 文字放在一起
    public lazy var shortsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8 // 設置元件間距
        stackView.distribution = .fill // 將分佈設置為填充
        stackView.alignment = .center // 將對齊方式設置為居中對齊
        stackView.addArrangedSubview(playerSymbolImageView)
        stackView.addArrangedSubview(shortsLbl)
        stackView.backgroundColor = .systemBackground
        return stackView
    }()
    
    var singleVideoFrameView = VideoFrameView()
    var otherVideoFrameViews: [VideoFrameView] = []
    var videoFrameView = VideoFrameView()
    var showItems: [String] = []
    var viewCount = ""
    var subscribeSecItemView = SubscribeSecItemView()
    
    lazy var shortsFrameCollectionView: ShortsFrameCollectionView = {
        let collectionView = ShortsFrameCollectionView()
        return collectionView
    }()
    
    lazy var subscribeHoriCollectionView: SubscribeHoriCollectionView = {
        let collectionView = SubscribeHoriCollectionView()
        return collectionView
    }()
    
    var totalHeight: CGFloat = 0
    var videoViewModel: VideoViewModel!
    
    var clickedVideoID: String?
    var clickedTitle: String?
    var clickedChannelTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.isScrollEnabled = true
        totalHeight = calculateTotalHeight()
        
        setViews()
        setLayout()
        navButtonItemsModel = NavButtonItemsModel(viewController: self)
        navButtonItemsModel.setNavBtnItems()
        
        // 將 scrollView 的 contentSize 設置為 contentView 的大小，確保能夠正確上下滾動
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: totalHeight)
        
        // 初始化 VideoViewModel 并加载数据
        videoViewModel = VideoViewModel()
        videoViewModel.viewController = self
        
        buttonCollectionViewCell.delegate = self
        
        // 根据视图控制器类型加载不同的数据
        if let vcType = vcType {
            loadData(for: vcType)
        }
        
        videoViewModel.dataLoadedCallback = { [weak self] videoModels in
            guard let self = self else { return }
            self.handleVideoModelsLoaded(videoModels)
        }
        
        // 添加点击手势识别器
        let shortsTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleShortsTap))
        shortsFrameCollectionView.addGestureRecognizer(shortsTapGesture)
        
        let subscribeTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSubscribeTap))
        subscribeHoriCollectionView.addGestureRecognizer(subscribeTapGesture)
        
        let singleVideoTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleVideoTap))
        singleVideoFrameView.addGestureRecognizer(singleVideoTapGesture)
        
        otherVideoFrameViews.forEach { videoFrameView in
            let otherVideoTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleOtherVideoTap(_:)))
            videoFrameView.addGestureRecognizer(otherVideoTapGesture)
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 調用 NavButtonItemsModel 的更新方法
        // 切換深淺模式的時候，即時切換
        navButtonItemsModel.handleTraitCollectionChange(previousTraitCollection: previousTraitCollection)
    }
    
    
    @objc func handleShortsTap() {
        if let videoID = shortsFrameCollectionView.accessibilityIdentifier {
            clickedVideoID = videoID
            loadAndNavigateToShortsTableViewController(with: videoID)
        }
        print("BaseVC.handleShortsTap().clickedVideoID == \(clickedVideoID ?? "")")
    }
    
    @objc func handleSubscribeTap() {
        if let videoID = subscribeHoriCollectionView.accessibilityIdentifier {
            clickedVideoID = videoID
            loadAndNavigateToShortsTableViewController(with: videoID)
        }
        print("BaseVC.handleSubscribeTap().clickedVideoID == \(clickedVideoID ?? "")")
    }
    
    @objc func handleSingleVideoTap() {
        if let videoID = singleVideoFrameView.accessibilityIdentifier {
            clickedVideoID = videoID
            loadAndNavigateToShortsTableViewController(with: videoID)
        }
        print("BaseVC.handleSingleVideoTap().clickedVideoID == \(clickedVideoID ?? "")")
    }
    
    @objc func handleOtherVideoTap(_ sender: UITapGestureRecognizer) {
        if let videoFrameView = sender.view, let videoID = videoFrameView.accessibilityIdentifier {
            clickedVideoID = videoID
            loadAndNavigateToShortsTableViewController(with: videoID)
        }
        print("BaseVC.handleOtherVideoTap().clickedVideoID == \(clickedVideoID ?? "")")
    }
    
    func loadAndNavigateToShortsTableViewController(with videoID: String) {
        let playerViewController = PlayerViewController()
        playerViewController.selectedVideoID = videoID // 传递 videoID
        
        // Hide back button in the navigation bar
        playerViewController.navigationItem.hidesBackButton = true
        playerViewController.navigationItem.leftBarButtonItem = nil
        
        navigationController?.pushViewController(playerViewController, animated: true)
    }
    
    func handleVideoModelsLoaded(_ videoModels: [VideoModel]) {
        for (index, videoModel) in videoModels.enumerated() {
            let title = videoModel.title
            let thumbnailURL = videoModel.thumbnailURL
            let channelTitle = videoModel.channelTitle
            let videoID = videoModel.videoID
            let viewCount = videoModel.viewCount ?? "沒"
            let daysSinceUpload = videoModel.daysSinceUpload ?? "沒"
            let accountImageURL = videoModel.accountImageURL
            
            if index == 0 {
                singleVideoFrameView.accessibilityIdentifier = videoID // 保存 singleVideoFrameView 的 videoID
                loadDataVideoFrameView(withTitle: title, thumbnailURL: thumbnailURL, channelTitle: channelTitle, accountImageURL: accountImageURL, viewCount: viewCount, daysSinceUpload: daysSinceUpload, atIndex: index)
            } else {
                let videoFrameView = otherVideoFrameViews[index - 1]
                videoFrameView.accessibilityIdentifier = videoID // 保存 otherVideoFrameViews 的 videoID
                loadDataVideoFrameView(withTitle: title, thumbnailURL: thumbnailURL, channelTitle: channelTitle, accountImageURL: accountImageURL, viewCount: viewCount, daysSinceUpload: daysSinceUpload, atIndex: index)
            }
        }
    }
    
    func loadData(for vcType: ViewControllerType) {
        switch vcType {
        case .home:
            videoViewModel.loadShortsCell(withQuery: "txt Dance shorts", for: .home)
            videoViewModel.loadVideoView(withQuery: "TODO EP.", for: .home)
        case .subscribe:
            videoViewModel.loadShortsCell(withQuery: "IVE Dance shorts, newJeans Dance shorts", for: .subscribe)
            videoViewModel.loadVideoView(withQuery: "TXT T:Time", for: .subscribe)
        default:
            break
        }
    }
    
    func updateContentSize() {
        contentView.layoutIfNeeded()
        scrollView.contentSize = contentView.frame.size
    }
    
    func setViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(buttonCollectionViewCell)
        contentView.addSubview(singleVideoFrameView)
        contentView.addSubview(shortsStackView)
        
        if vcType == .home {
            contentView.addSubview(shortsFrameCollectionView)
        } else if vcType == .subscribe {
            contentView.addSubview(subscribeSecItemView)
            contentView.addSubview(subscribeHoriCollectionView)
        }
    }
    
    func calculateTotalHeight() -> CGFloat {
        switch vcType {
        case .home:
            return 1080 + 300 * 4 + 40 // home类型时增加4个视频框架和间距的高度
        case .subscribe:
            return 840 + 300 * 4 + 40 // subscribe类型时增加4个视频框架和间距的高度
        default:
            return 0
        }
    }
    
    func setLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        subscribeSecItemView.translatesAutoresizingMaskIntoConstraints = false
        singleVideoFrameView.translatesAutoresizingMaskIntoConstraints = false
        shortsStackView.translatesAutoresizingMaskIntoConstraints = false
        shortsFrameCollectionView.translatesAutoresizingMaskIntoConstraints = false
        subscribeHoriCollectionView.translatesAutoresizingMaskIntoConstraints = false
        buttonCollectionViewCell.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalToConstant: totalHeight)
        ])
        
        if vcType == .home {
            NSLayoutConstraint.activate([
                
                buttonCollectionViewCell.topAnchor.constraint(equalTo: contentView.topAnchor),
                buttonCollectionViewCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                buttonCollectionViewCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                buttonCollectionViewCell.heightAnchor.constraint(equalToConstant: 60),
                
                singleVideoFrameView.topAnchor.constraint(equalTo: buttonCollectionViewCell.bottomAnchor),
                singleVideoFrameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                singleVideoFrameView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                singleVideoFrameView.heightAnchor.constraint(equalToConstant: 300),
                
                shortsStackView.topAnchor.constraint(equalTo: singleVideoFrameView.bottomAnchor),
                shortsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                shortsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                shortsStackView.heightAnchor.constraint(equalToConstant: 60),
                
                shortsFrameCollectionView.topAnchor.constraint(equalTo: shortsStackView.bottomAnchor),
                shortsFrameCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                shortsFrameCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                shortsFrameCollectionView.heightAnchor.constraint(equalToConstant: 660),
            ])
        } else if vcType == .subscribe {
            NSLayoutConstraint.activate([
                subscribeSecItemView.topAnchor.constraint(equalTo: contentView.topAnchor),
                subscribeSecItemView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                subscribeSecItemView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                subscribeSecItemView.heightAnchor.constraint(equalToConstant: 90),
                
                buttonCollectionViewCell.topAnchor.constraint(equalTo: subscribeSecItemView.bottomAnchor),
                buttonCollectionViewCell.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                buttonCollectionViewCell.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                buttonCollectionViewCell.heightAnchor.constraint(equalToConstant: 60),
                
                singleVideoFrameView.topAnchor.constraint(equalTo: buttonCollectionViewCell.bottomAnchor),
                singleVideoFrameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                singleVideoFrameView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                singleVideoFrameView.heightAnchor.constraint(equalToConstant: 300),
                
                shortsStackView.topAnchor.constraint(equalTo: singleVideoFrameView.bottomAnchor),
                shortsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                shortsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                shortsStackView.heightAnchor.constraint(equalToConstant: 60),
                
                subscribeHoriCollectionView.topAnchor.constraint(equalTo: shortsStackView.bottomAnchor),
                subscribeHoriCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                subscribeHoriCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                subscribeHoriCollectionView.heightAnchor.constraint(equalToConstant: 330),
            ])
        }
        
        // 添加其他 VideoFrameView 并设置约束
        var videoFrameViews: [VideoFrameView] = []
        
        let firstVideoFrameView = VideoFrameView()
        firstVideoFrameView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(firstVideoFrameView)
        videoFrameViews.append(firstVideoFrameView)
        
        if vcType == .home {
            NSLayoutConstraint.activate([
                firstVideoFrameView.topAnchor.constraint(equalTo: shortsFrameCollectionView.bottomAnchor, constant: 10),
            ])
        } else if vcType == .subscribe {
            NSLayoutConstraint.activate([
                firstVideoFrameView.topAnchor.constraint(equalTo: subscribeHoriCollectionView.bottomAnchor, constant: 10),
            ])
        }
        NSLayoutConstraint.activate([
            firstVideoFrameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            firstVideoFrameView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            firstVideoFrameView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        var previousView: UIView = firstVideoFrameView
        
        for _ in 1..<4 {
            let videoFrameView = VideoFrameView()
            videoFrameView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(videoFrameView)
            videoFrameViews.append(videoFrameView)
            
            NSLayoutConstraint.activate([
                videoFrameView.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: 10),
                videoFrameView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                videoFrameView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                videoFrameView.heightAnchor.constraint(equalToConstant: 300)
            ])
            
            previousView = videoFrameView
        }
        
        otherVideoFrameViews = videoFrameViews
    }
    
    
}

extension BaseViewController {
    
    private func getVideoFrameView(at index: Int) -> VideoFrameView? {
        if index == 0 {
            return singleVideoFrameView
        } else if index >= 1 && index <= 4 {
            let adjustedIndex = index - 1
            if adjustedIndex < otherVideoFrameViews.count {
                return otherVideoFrameViews[adjustedIndex]
            }
        }
        return nil
    }
    
    func loadDataVideoFrameView(withTitle title: String,
                                thumbnailURL: String,
                                channelTitle: String,
                                accountImageURL: String,
                                viewCount: String,
                                daysSinceUpload: String,
                                atIndex index: Int) {
        print("BaseVC == \(title)")
        
        guard let videoFrameView = getVideoFrameView(at: index) else {
            print("No VideoFrameView at index \(index)")
            return
        }
        
        DispatchQueue.main.async {
            let videoModel = VideoModel(title: title,
                                        thumbnailURL: thumbnailURL,
                                        channelTitle: channelTitle,
                                        videoID: "",
                                        viewCount: viewCount,
                                        daysSinceUpload: daysSinceUpload,
                                        accountImageURL: accountImageURL)
            videoFrameView.configure(with: videoModel)
            print("Configured VideoFrameView at index \(index) with title \(title)")
        }
    }
    
    
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

