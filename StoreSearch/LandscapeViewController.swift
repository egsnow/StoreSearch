//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Eric Snow on 7/21/19.
//  Copyright © 2019 Eric Snow. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var pageControl: UIPageControl!
    
    deinit {
        print("deinit \(self)")
        for task in downloads {
            task.cancel()
        }
    }
    
    var search: Search!
    private var firstTime = true
    private var downloads = [URLSessionDownloadTask]()
    
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.center = CGPoint(x: scrollView.bounds.midX + 0.5, y: scrollView.bounds.midY + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    private func tileButtons(_ searchResults: [SearchResult]) {
        var columnsPerPage = 6
        var rowsPerPage = 3
        var itemWidth: CGFloat = 94
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 2
        var marginY: CGFloat = 20
        var row = 0
        var column = 0
        var x = marginX
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        let viewWidth = scrollView.bounds.size.width
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        scrollView.contentSize = CGSize(width: CGFloat(numPages) * viewWidth, height: scrollView.bounds.size.height)
        for (index, result) in searchResults.enumerated() {
            let button = UIButton(type: .custom)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
            button.setTitle("\(index)", for: .normal)
            button.frame = CGRect(x: x + paddingHorz, y: marginY + CGFloat(row)*itemHeight + paddingVert, width: buttonWidth, height: buttonHeight)
            button.tag = 2000 + index
            button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
            scrollView.addSubview(button)
            downloadImage(for: result, andPlaceOn: button)
            row += 1
            if row == rowsPerPage {
                row = 0; x += itemWidth; column += 1
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                }
            }
        }
        switch viewWidth {
        case 568:
            break
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
            marginX = 0
        case 724:
            columnsPerPage = 8
            rowsPerPage = 3
            itemWidth = 90
            itemHeight = 98
            marginX = 2
            marginY = 29
        default:
            break
        }
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        print("Number of pages: \(numPages)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                let searchResult = list[(sender as! UIButton).tag - 2000]
                detailViewController.searchResult = searchResult
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        view.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        pageControl.numberOfPages = 0
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        scrollView.frame = safeFrame
        pageControl.frame = CGRect(x: safeFrame.origin.x, y: safeFrame.size.height - pageControl.frame.size.height, width: safeFrame.size.width, height: pageControl.frame.size.height)
        if firstTime {
            firstTime = false
            switch search.state {
            case .notSearchedYet:
                break
            case .loading:
                showSpinner()
            case .noResults:
                showNothingFoundLabel()
            case .results(let list):
                tileButtons(list)
            }
        }
        
        private func hideSpinner() {
            view.viewWithTag(1000)?.removeFromSuperview()
        }
        
        func searchResultsReceived() {
            hideSpinner()
            switch search.state {
            case .notSearchedYet, .loading, .noResults:
                break
            case .results(let list):
                tileButtons(list)
            }
        }
        
        private func showNothingFoundLabel() {
            let label = UILabel(frame: CGRect.zero)
            label.text = "Nothing Found"
            label.textColor = UIColor.white
            label.backgroundColor = UIColor.clear
            label.sizeToFit()
            var rect = label.frame
            rect.size.width = ceil(rect.size.width/2) * 2
            rect.size.height = ceil(rect.size.height/2) * 2  // make even
            label.frame = rect
            label.center = CGPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY)
                                   view.addSubview(label)
        }
        
        @IBAction func pageChanged(_ sender: UIPageControl) {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
                self.scrollView.contentOffset = CGPoint(x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0)
            },
                           completion: nil)
        }
        

        private func downloadImage(for searchResult: SearchResult, andPlaceOn button: UIButton) {
            if let url = URL(string: searchResult.imageSmall) {
                let task = URLSession.shared.downloadTask(with: url) {
                    [weak button] url, response, error in
                    if error == nil, let url = url,
                        let data = try? Data(contentsOf: url),
                        let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            if let button = button {
                                button.setImage(image, for: .normal)
                            }
                        }
                    }
                }
                task.resume()
                downloads.append(task)
            }
        }
    }
}
    
extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let page = Int((scrollView.contentOffset.x + width / 2) / width)
        pageControl.currentPage = page
    }
}
