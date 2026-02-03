import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - Properties
    private var searchBar: UISearchBar!
    private var collectionView: UICollectionView!
    private var allStickers: [StickerItem] = []
    private var filteredStickers: [StickerItem] = []
    private var stickerCache: [String: MSSticker] = [:]
    
    struct StickerItem {
        let url: URL
        let name: String
        let searchableName: String
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStickers()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateLayout()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Search bar
        searchBar = UISearchBar()
        searchBar.placeholder = "Search bufo stickers..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Collection view layout
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        
        // Collection view
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: "StickerCell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.keyboardDismissMode = .onDrag
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateLayout() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        let itemsPerRow: CGFloat = presentationStyle == .compact ? 4 : 5
        let padding: CGFloat = 8
        let totalPadding = padding * (itemsPerRow + 1)
        let availableWidth = collectionView.bounds.width - totalPadding
        let itemSize = floor(availableWidth / itemsPerRow)
        
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.invalidateLayout()
    }
    
    // MARK: - Sticker Loading
    private func loadStickers() {
        guard let stickersPath = Bundle.main.resourcePath?.appending("/Stickers") else {
            print("Could not find Stickers folder")
            return
        }
        
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: stickersPath)
            let stickerFiles = files.filter { $0.hasSuffix(".png") || $0.hasSuffix(".gif") }
            
            allStickers = stickerFiles.compactMap { filename -> StickerItem? in
                let url = URL(fileURLWithPath: stickersPath).appendingPathComponent(filename)
                let name = filename
                    .replacingOccurrences(of: ".png", with: "")
                    .replacingOccurrences(of: ".gif", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                
                return StickerItem(url: url, name: name, searchableName: name.lowercased())
            }
            
            // Sort alphabetically
            allStickers.sort { $0.name < $1.name }
            filteredStickers = allStickers
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
            print("Loaded \(allStickers.count) stickers")
        } catch {
            print("Error loading stickers: \(error)")
        }
    }
    
    private func getSticker(for item: StickerItem) -> MSSticker? {
        if let cached = stickerCache[item.url.path] {
            return cached
        }
        
        do {
            let sticker = try MSSticker(contentsOfFileURL: item.url, localizedDescription: item.name)
            stickerCache[item.url.path] = sticker
            return sticker
        } catch {
            print("Error creating sticker: \(error)")
            return nil
        }
    }
    
    // MARK: - Search
    private func filterStickers(with searchText: String) {
        if searchText.isEmpty {
            filteredStickers = allStickers
        } else {
            let searchTerms = searchText.lowercased().split(separator: " ").map { String($0) }
            filteredStickers = allStickers.filter { sticker in
                searchTerms.allSatisfy { term in
                    sticker.searchableName.contains(term)
                }
            }
        }
        collectionView.reloadData()
    }
    
    // MARK: - Presentation Style
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        updateLayout()
    }
}

// MARK: - UISearchBarDelegate
extension MessagesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterStickers(with: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionViewDataSource
extension MessagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCell", for: indexPath) as! StickerCell
        let item = filteredStickers[indexPath.item]
        
        if let sticker = getSticker(for: item) {
            cell.configure(with: sticker)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MessagesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = filteredStickers[indexPath.item]
        
        if let sticker = getSticker(for: item) {
            activeConversation?.insert(sticker) { error in
                if let error = error {
                    print("Error inserting sticker: \(error)")
                }
            }
        }
    }
}

// MARK: - Sticker Cell
class StickerCell: UICollectionViewCell {
    private var stickerView: MSStickerView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }
    
    private func setupCell() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    func configure(with sticker: MSSticker) {
        stickerView?.removeFromSuperview()
        
        let view = MSStickerView(frame: contentView.bounds, sticker: sticker)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        contentView.addSubview(view)
        stickerView = view
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stickerView?.removeFromSuperview()
        stickerView = nil
    }
}
