//
//  MainViewController.swift
//  médino
//
//  Created by Florian Reinhart on 14.05.18.
//

import UIKit

class MainViewController: UITableViewController, UISearchResultsUpdating {
    
    private let sections = DataManager.sections
    private var favorites = DataManager.favorites {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    private var searchResults: [Entry]? {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private func entry(for indexPath: IndexPath) -> Entry {
        let entry: Entry
        
        if let searchResults = self.searchResults {
            entry = searchResults[indexPath.row]
        } else {
            if indexPath.section == 0 {
                entry = self.favorites[indexPath.row]
            } else {
                entry = self.sections[indexPath.section - 1].entries[indexPath.row]
            }
        }
        
        return entry
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup search controller
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.autocapitalizationType = .none
        self.searchController.searchBar.autocorrectionType = .no
        self.navigationItem.searchController = self.searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        // Favorite changes
        NotificationCenter.default.addObserver(self, selector: #selector(favoritesChanged(_:)), name: .FavoritesChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchResults != nil {
            return 1
        } else {
            return self.sections.count + 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let searchResults = self.searchResults {
            return searchResults.count
        } else {
            if section == 0 {
                return self.favorites.count
            } else {
                return self.sections[section - 1].entries.count
            }
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.searchResults != nil {
            return nil
        } else {
            return ["♥︎"] + self.sections.map { $0.name }
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.searchResults != nil {
            return nil
        } else {
            if section == 0 {
                return "Favorites"
            } else {
                return self.sections[section - 1].name
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SubtitleCell", for: indexPath)

        // Get entry
        let entry = self.entry(for: indexPath)
        
        // Configure the cell
        cell.textLabel?.text = entry.abbreviation
        cell.detailTextLabel?.text = entry.term

        return cell
    }

    // MARK: - Search
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchTerm = searchController.searchBar.text?.lowercased() ?? ""
        
        if searchTerm.isEmpty {
            self.searchResults = nil
        } else {
            var searchResults = [Entry]()
            
            for section in self.sections {
                for entry in section.entries {
                    if entry.abbreviation.lowercased().contains(searchTerm) || entry.term.lowercased().contains(searchTerm) {
                        searchResults.append(entry)
                    }
                }
            }
            
            self.searchResults = searchResults
        }
    }
    
    // MARK: - Favorites
    
    @objc private func favoritesChanged(_ notification: Notification) {
        self.favorites = DataManager.favorites
    }
    
    // MARK: - New entry
    
    @IBAction private func createdNewEntry(_ sender: UIStoryboardSegue) {
        self.updateSearchResults(for: self.searchController)
        self.tableView.reloadData()
    }
    
    @IBAction private func canceledEntryCreation(_ sender: UIStoryboardSegue) {
        // Nothing to do
    }
    
    // MARK: - Details
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show",
            let cell = sender as? UITableViewCell,
            let indexPath = self.tableView.indexPath(for: cell) {
            
                // Get entry
                let entry = self.entry(for: indexPath)
            
                let detailViewController = segue.destination as! DetailViewController
                detailViewController.entry = entry
        }
    }
}
