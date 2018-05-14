//
//  Model.swift
//  Medical Terms
//
//  Created by Florian Reinhart on 14.05.18.
//

import Foundation

class Section: Codable {
    let name: String
    var entries: [Entry]
    
    fileprivate init(name: String, entries: [Entry] = []) {
        self.name = name
        self.entries = entries
    }
}

class Entry: Codable {
    var abbreviation: String
    var term: String
    var comment: String?
    var favorite: Bool? {
        didSet {
            NotificationCenter.default.post(name: .FavoritesChanged, object: nil)
        }
    }
    let custom: Bool?
    
    fileprivate init(abbreviation: String, term: String, comment: String?, favorite: Bool?) {
        self.abbreviation = abbreviation
        self.term = term
        self.comment = comment
        self.favorite = favorite
        self.custom = true
    }
}

extension Notification.Name {
    public static let FavoritesChanged = NSNotification.Name("FavoritesChanged")
}

class DataManager {
    
    private static let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("MedicalTerms.json")
    
    static var sections: [Section] = {
        let data = (try? Data(contentsOf: DataManager.url)) ?? (try! Data(contentsOf: Bundle.main.url(forResource: "MedicalTerms", withExtension: "json")!))
        
        let jsonDecoder = JSONDecoder()
        let sections = try! jsonDecoder.decode([Section].self, from: data)
        
        // Sort entries
        for section in sections {
            section.entries.sort { $0.abbreviation.lowercased() < $1.abbreviation.lowercased() }
        }
        
        return sections
    }()
    
    static var favorites: [Entry] {
        return self.sections.flatMap({ return $0.entries.filter({ $0.favorite == true }) })
    }
    
    @discardableResult
    static func createEntry(abbreviation: String, term: String, comment: String?, favorite: Bool?) -> Entry {
        let entry = Entry(abbreviation: abbreviation, term: term, comment: comment, favorite: favorite)
        
        // Find section
        var section = self.sections.first(where: { $0.name == "#" })!
        if let firstLetter = entry.abbreviation.first.flatMap(String.init(_:))?.lowercased() {
            if let matchedSection = self.sections.first(where: { $0.name.lowercased() == firstLetter }) {
                section = matchedSection
            }
        }
        
        section.entries.append(entry)
        section.entries.sort { $0.abbreviation.lowercased() < $1.abbreviation.lowercased() }
        
        // New entries are automatically favorited
        NotificationCenter.default.post(name: .FavoritesChanged, object: nil)
        
        return entry
    }
    
    static func deleteEntry(_ entry: Entry) {
        guard entry.custom == true else { return }
        
        for section in self.sections {
            var indexesToRemove = [Int]()
            
            for (index, currentEntry) in zip(0..., section.entries) {
                if currentEntry === entry {
                    indexesToRemove.append(index)
                }
            }
            
            for index in indexesToRemove {
                section.entries.remove(at: index)
            }
        }
        
        // Favorites might have changed
        NotificationCenter.default.post(name: .FavoritesChanged, object: nil)
    }
    
    static func save() {
        let jsonEncoder = JSONEncoder()
        let data = try! jsonEncoder.encode(self.sections)
        try! data.write(to: self.url, options: .atomic)
    }
}
