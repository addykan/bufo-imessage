import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController {

    private var searchBar: UISearchBar!
    private var collectionView: UICollectionView!
    private var hintLabel: UILabel!
    private var allStickerNames: [String] = []
    private var filteredStickerNames: [String] = []
    private let stickerExtensions = ["png", "gif"]
    private let cellReuseId = "StickerCell"
    private let inset: CGFloat = 12
    private let columns: CGFloat = 3
    private var stickersDirectoryURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bufo Stickers"
        view.backgroundColor = .systemBackground

        loadStickerList()
        filteredStickerNames = allStickerNames

        searchBar = UISearchBar()
        searchBar.placeholder = "Search stickers…"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.searchBarStyle = .minimal
        view.addSubview(searchBar)

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = inset
        layout.minimumLineSpacing = inset
        layout.sectionInset = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: cellReuseId)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.contentInsetAdjustmentBehavior = .always
        view.addSubview(collectionView)

        hintLabel = UILabel()
        hintLabel.text = "Tap a sticker to copy it, then paste in WhatsApp, Messages, or any app."
        hintLabel.font = .preferredFont(forTextStyle: .footnote)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.heightAnchor.constraint(equalToConstant: 56),

            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -8),

            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func loadStickerList() {
        // Main app bundle gets "Stickers" at root when folder is in Copy Bundle Resources
        let candidates = ["Stickers", "MessagesExtension/Stickers"]
        for subpath in candidates {
            let dirURL: URL? = Bundle.main.url(forResource: subpath, withExtension: nil)
                ?? Bundle.main.resourceURL?.appendingPathComponent(subpath)
            if let url = dirURL, FileManager.default.fileExists(atPath: url.path) {
                allStickerNames = listStickerFiles(in: url)
                if !allStickerNames.isEmpty {
                    stickersDirectoryURL = url
                    break
                }
            }
        }
        if allStickerNames.isEmpty, let resourceURL = Bundle.main.resourceURL {
            let dirURL = resourceURL.appendingPathComponent("Stickers")
            if FileManager.default.fileExists(atPath: dirURL.path) {
                allStickerNames = listStickerFiles(in: dirURL)
                stickersDirectoryURL = dirURL
            }
        }
        allStickerNames.sort()
    }

    private func listStickerFiles(in directory: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        var names: [String] = []
        for case let fileURL as URL in enumerator {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { continue }
            let ext = fileURL.pathExtension.lowercased()
            if stickerExtensions.contains(ext) {
                names.append(fileURL.lastPathComponent)
            }
        }
        return names
    }

    private func stickerURL(for name: String) -> URL? {
        if let base = stickersDirectoryURL {
            let url = base.appendingPathComponent(name)
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        for subpath in ["Stickers", "MessagesExtension/Stickers"] {
            if let base = Bundle.main.url(forResource: subpath, withExtension: nil)
                ?? Bundle.main.resourceURL?.appendingPathComponent(subpath) {
                let candidate = base.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            }
        }
        return Bundle.main.resourceURL?.appendingPathComponent("Stickers").appendingPathComponent(name)
    }

    private func copyStickerToClipboard(name: String) {
        guard let url = stickerURL(for: name) else { return }
        let ext = url.pathExtension.lowercased()
        guard let data = try? Data(contentsOf: url) else { return }

        if ext == "gif" {
            UIPasteboard.general.setData(data, forPasteboardType: UTType.gif.identifier)
        } else {
            if let image = UIImage(data: data), let pngData = image.pngData() {
                UIPasteboard.general.setData(pngData, forPasteboardType: UTType.png.identifier)
            }
        }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()
        showCopiedBanner()
    }

    private func showCopiedBanner() {
        let banner = UILabel()
        banner.text = "Copied!"
        banner.font = .boldSystemFont(ofSize: 17)
        banner.textColor = .white
        banner.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        banner.textAlignment = .center
        banner.layer.cornerRadius = 10
        banner.clipsToBounds = true
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            banner.widthAnchor.constraint(equalToConstant: 140),
            banner.heightAnchor.constraint(equalToConstant: 44),
        ])
        banner.alpha = 0
        UIView.animate(withDuration: 0.2, animations: { banner.alpha = 1 })
        UIView.animate(withDuration: 0.25, delay: 1.2, options: [], animations: { banner.alpha = 0 }) { _ in
            banner.removeFromSuperview()
        }
    }

    private func filterStickers(query: String) {
        if query.isEmpty {
            filteredStickerNames = allStickerNames
        } else {
            let lower = query.lowercased()
            filteredStickerNames = allStickerNames.filter { $0.lowercased().contains(lower) }
        }
        collectionView.reloadData()
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterStickers(query: searchText)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredStickerNames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseId, for: indexPath) as! StickerCell
        let name = filteredStickerNames[indexPath.item]
        cell.configure(name: name, stickerURL: stickerURL(for: name))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalInsets = inset * (columns + 1)
        let width = (collectionView.bounds.width - totalInsets) / columns
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let name = filteredStickerNames[indexPath.item]
        copyStickerToClipboard(name: name)
    }
}

// MARK: - Cell

private final class StickerCell: UICollectionViewCell {
    private let imageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(name: String, stickerURL: URL?) {
        imageView.image = nil
        imageView.animationImages = nil
        imageView.stopAnimating()
        guard let url = stickerURL else { return }
        let ext = url.pathExtension.lowercased()
        if ext == "gif" {
            loadGif(url: url)
        } else {
            loadStaticImage(url: url)
        }
    }

    private func loadStaticImage(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.imageView.image = image }
        }
    }

    private func loadGif(url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: url),
                  let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }
            let count = CGImageSourceGetCount(source)
            var images: [UIImage] = []
            var totalDuration: Double = 0
            for i in 0..<count {
                guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
                var delay = 0.1
                if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gif = props[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                    delay = unclamped > 0 ? unclamped : (gif[kCGImagePropertyGIFDelayTime as String] as? Double ?? 0.1)
                }
                totalDuration += delay
                images.append(UIImage(cgImage: cgImage))
            }
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.imageView.animationImages = images.isEmpty ? nil : images
                self.imageView.animationDuration = max(0.1, totalDuration)
                self.imageView.animationRepeatCount = 0
                if let first = images.first {
                    self.imageView.image = first
                }
                self.imageView.startAnimating()
            }
        }
    }
}
