import Foundation
import UIKit

enum ViewControllerType: String {
    case home, subscribe, content, shorts, player
}

class VideoModel: Decodable {
    var title: String
    var thumbnailURL: String
    var channelTitle: String
    var videoID: String
    var viewCount: String?
    var daysSinceUpload: String?
    var accountImageURL: String
    
    init(title: String, thumbnailURL: String, channelTitle: String, videoID: String, viewCount: String? = nil, daysSinceUpload: String? = nil, accountImageURL: String) {
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.channelTitle = channelTitle
        self.videoID = videoID
        self.viewCount = viewCount
        self.daysSinceUpload = daysSinceUpload
        self.accountImageURL = accountImageURL
    }
}

class VideoViewModel {
    
    var data: Observable<[VideoModel]> = Observable([])
    var dataLoadedCallback: (([VideoModel]) -> Void)?
    private var dataTask: URLSessionDataTask?
    weak var viewController: BaseViewController?
    private let apiKey = "AIzaSyCvZYsFx7oIjm2mBOhVCHLJjzoqFo8GzCU"
    
    func cancelSearch() {
        dataTask?.cancel()
    }
    
    deinit {
        cancelSearch()
    }
    
    func searchYouTube<T: Decodable>(query: String, maxResults: Int, responseType: T.Type, completion: @escaping (T?, [String]?) -> Void) {
        let baseURL = "https://www.googleapis.com/youtube/v3/search"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            print("Invalid URL")
            completion(nil, nil)
            return
        }
        
        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(String(describing: error))")
                completion(nil, nil)
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                let videoIDs = (decodedResponse as? SearchResponse)?.items.map { $0.id.videoID } ?? []
                completion(decodedResponse, videoIDs)
            } catch {
                print("JSON decoding error: \(error)")
                completion(nil, nil)
            }
        }
        dataTask?.resume()
    }
    
    func loadShortsCell(withQuery query: String, for viewControllerType: ViewControllerType) {
        let maxResults: Int
        switch viewControllerType {
        case .home: maxResults = 4
        case .subscribe: maxResults = 18
        case .content: maxResults = 16
        case .shorts: maxResults = 8
        default: maxResults = 0
        }
        
        searchYouTube(query: query, maxResults: maxResults, responseType: SearchResponse.self) { [weak self] searchResponse, videoIDs in
            guard let self = self else { return }
            if let searchResponse = searchResponse {
                DispatchQueue.main.async {
                    self.handleSearchResponse(searchResponse, for: viewControllerType)
                }
                print("Video IDs: \(videoIDs ?? [])")
            } else {
                print("No results for query \(query)")
            }
        }
    }
    
    func fetchVideoDetails(for ids: [String], maxResults: Int, for viewControllerType: ViewControllerType) {
        let idsString = ids.joined(separator: ",")
        let baseURL = "https://www.googleapis.com/youtube/v3/videos"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,statistics"),
            URLQueryItem(name: "id", value: idsString),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            print("Invalid URL")
            return
        }
        
        dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(String(describing: error))")
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(VideosResponse.self, from: data)
                DispatchQueue.main.async {
                    self.handleVideosResponse(decodedResponse, for: viewControllerType)
                }
            } catch {
                print("JSON decoding error: \(error)")
            }
        }
        dataTask?.resume()
    }
    
    private func handleVideosResponse(_ response: VideosResponse, for viewControllerType: ViewControllerType) {
        guard let viewController = self.viewController else { return }
        
        let maxResults = (viewControllerType == .home || viewControllerType == .subscribe) ? 5 : 0
        let videoModels = response.items.prefix(maxResults).map { item in
            VideoModel(
                title: item.snippet.title,
                thumbnailURL: item.snippet.thumbnails.high.url,
                channelTitle: item.snippet.channelTitle,
                videoID: item.id,
                viewCount: item.statistics?.viewCount,
                daysSinceUpload: item.snippet.publishedAt,
                accountImageURL: item.snippet.thumbnails.thumbnailsDefault.url
            )
        }
        
        viewController.videoViewModel.data.value = videoModels
        viewController.videoViewModel.dataLoadedCallback?(videoModels)
    }
    
    func loadVideoView(withQuery query: String, for viewControllerType: ViewControllerType) {
        let maxResults = (viewControllerType == .home || viewControllerType == .subscribe || viewControllerType == .player) ? 5 : 0
        
        searchYouTube(query: query, maxResults: maxResults, responseType: SearchResponse.self) { [weak self] searchResponse, videoIDs in
            guard let self = self else { return }
            if let videoIDs = videoIDs {
                print("Video IDs: \(videoIDs)")
                self.fetchVideoDetails(for: videoIDs, maxResults: maxResults, for: viewControllerType)
            } else {
                print("No results for query \(query)")
            }
        }
    }
    
    private func handleSearchResponse(_ response: SearchResponse, for viewControllerType: ViewControllerType) {
        switch viewControllerType {
        case .home:
            handleCollectionViewResult(response, collectionView: viewController?.shortsFrameCollectionView)
        case .subscribe:
            handleCollectionViewResult(response, collectionView: viewController?.subscribeHoriCollectionView)
        case .content, .shorts, .player:
            handleContentSearchResult(response)
        }
    }
    
    private func handleContentSearchResult(_ response: SearchResponse) {
        let videoModels = response.items.map { item in
            VideoModel(
                title: item.snippet.title,
                thumbnailURL: item.snippet.thumbnails.high.url,
                channelTitle: item.snippet.channelTitle,
                videoID: item.id.videoID,
                accountImageURL: item.snippet.thumbnails.high.url
            )
        }
        
        DispatchQueue.main.async {
            self.data.value = videoModels
            self.dataLoadedCallback?(videoModels)
        }
    }
    
    private func handleCollectionViewResult(_ response: SearchResponse, collectionView: UICollectionView?) {
        guard let collectionView = collectionView else { return }
        
        let videoContents = response.items.map { item in
            VideoModel(
                title: item.snippet.title,
                thumbnailURL: item.snippet.thumbnails.high.url,
                channelTitle: item.snippet.channelTitle,
                videoID: item.id.videoID,
                accountImageURL: item.snippet.thumbnails.thumbnailsDefault.url
            )
        }
        
        if let shortsCollectionView = collectionView as? ShortsFrameCollectionView {
            shortsCollectionView.videoContents = videoContents
        } else if let subscribeCollectionView = collectionView as? SubscribeHoriCollectionView {
            subscribeCollectionView.subVideoContents = videoContents
        }
        
        collectionView.reloadData()
    }
}



class APIService {
    
    private let apiKey = "AIzaSyCvZYsFx7oIjm2mBOhVCHLJjzoqFo8GzCU"
    
    func getDataForVideoID(_ videoID: String, completion: @escaping (VideoModel?) -> Void) {
        let baseURL = "https://www.googleapis.com/youtube/v3/videos"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,statistics"),
            URLQueryItem(name: "id", value: videoID),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components.url else {
            print("Invalid URL")
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(String(describing: error))")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let items = json["items"] as? [[String: Any]],
                   let firstItem = items.first {
                    let snippet = firstItem["snippet"] as? [String: Any] ?? [:]
                    let statistics = firstItem["statistics"] as? [String: Any] ?? [:]
                    
                    let videoModel = VideoModel(
                        title: snippet["title"] as? String ?? "No Title",
                        thumbnailURL: ((snippet["thumbnails"] as? [String: Any])?["high"] as? [String: Any])?["url"] as? String ?? "",
                        channelTitle: snippet["channelTitle"] as? String ?? "Unknown Channel",
                        videoID: videoID,
                        viewCount: statistics["viewCount"] as? String ?? "View Count Unknown",
                        daysSinceUpload: snippet["publishedAt"] as? String ?? "Unknown Date",
                        accountImageURL: ((snippet["thumbnails"] as? [String: Any])?["high"] as? [String: Any])?["url"] as? String ?? ""
                    )
                    completion(videoModel)
                } else {
                    print("Failed to parse JSON")
                    completion(nil)
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(nil)
            }
        }
        
        task.resume()
    }
}

