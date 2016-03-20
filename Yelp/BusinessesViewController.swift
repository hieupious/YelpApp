//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit
import MBProgressHUD

class BusinessesViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var searchBar: UISearchBar!
    var loadingMoreView:InfiniteScrollActivityView?
    var businesses: [Business]!
    var searchTerm = ""
    var isMoreDataLoading = false
    var limitedResultsNumber = 20
    var loadingTimes = 0
    var offset: Int {
        get {
            return loadingTimes * limitedResultsNumber
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorInset = UIEdgeInsetsZero
        
        // Set up Infinite Scroll loading indicator
        let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.hidden = true
        tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset;
        insets.bottom += InfiniteScrollActivityView.defaultHeight;
        tableView.contentInset = insets
        
        // search bar
        searchBar = UISearchBar()
        searchBar.sizeToFit()
        searchBar.placeholder = "foods, drinks or anything"
        searchBar.tintColor = UIColor.whiteColor()
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        navigationController?.navigationBar.barTintColor = UIColor(colorLiteralRed: 0.769, green: 0.071, blue: 0, alpha: 1)

        doSearch()

// Example of Yelp search with more search options specified
//        let filters = YelpFilters.instance.parameters 
//        Business.searchWithTerm("", offset: offset, sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
//            self.businesses = businesses
//            self.tableView.reloadData()
//            for business in businesses {
//                print(business.name!)
//                print(business.address!)
//            }
//        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
//        if segue.destinationViewController is UINavigationController {
//            let navigationController = segue.destinationViewController as! UINavigationController {
//                if navigationController.viewControllers[0] is FiltersViewController {
//                    let controller = navigationController.viewControllers[0] as! FiltersViewController
//                    controller.delegate = self
//                }
//            }
//        }
        if segue.destinationViewController is FiltersViewController {
                let controller = segue.destinationViewController as! FiltersViewController
                controller.delegate = self
            }
    }


    func doSearch() {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        Business.searchWithTerm(searchTerm, offset:offset, additionalParams: getParameters(), completion: { (businesses: [Business]!, error: NSError!) -> Void in
            if self.loadingTimes > 0 {
                self.businesses.appendContentsOf(businesses)
            } else {
                self.businesses = businesses
            }
            if (businesses.count < self.limitedResultsNumber) {
                self.isMoreDataLoading = false
            } else {
                self.isMoreDataLoading = true
            }

            print("number of business: \(self.businesses.count)")
            // Stop the loading indicator
            self.loadingMoreView!.stopAnimating()
            self.tableView.reloadData()
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        })
    }
    
    func getParameters() -> Dictionary<String, String>? {
        var parameters: Dictionary<String, String>?
        if YelpFilters.instance.parameters.count > 0 {
            parameters = [:]
            for (key, value) in YelpFilters.instance.parameters {
                parameters![key] = value
            }
        }
        return parameters
    }
}

extension BusinessesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        cell.business = businesses[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return businesses?.count ?? 0
    }
}

extension BusinessesViewController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true;
    }
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(false, animated: true)
        return true;
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = ""
        searchTerm = ""
        loadingTimes = 0
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //searchSettings.searchString = searchBar.text
        //        searchSettings.minStars
        searchBar.resignFirstResponder()
        searchTerm = searchBar.text ?? ""
        loadingTimes = 0
        doSearch()
    }
}

extension BusinessesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if(isMoreDataLoading) {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging) {
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRectMake(0, tableView.contentSize.height, tableView.bounds.size.width, InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()
               isMoreDataLoading = false
                loadingTimes++
                doSearch()
                // ... Code to load more results ...
            }
        }
    }
}

extension BusinessesViewController: FiltersViewControlerDelegate {
    func onFiltersDone(controller: FiltersViewController) {
        self.loadingTimes = 0
        self.businesses = []
        doSearch()
        
    }
}