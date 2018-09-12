//
//  CoreDataImporter.swift
//  JournalCoreData
//
//  Created by Andrew R Madsen on 9/10/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataImporter {
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func sync(entries: [EntryRepresentation], completion: @escaping (Error?) -> Void = { _ in }) {
        print("Syncing starting...")
        self.context.perform {
            let identifiers = entries.compactMap { $0.identifier }
            
            let existingEntries = self.getAllExistingEntries(identifiers: identifiers)
            let existingEntryIdentifiers = existingEntries.compactMap { $0.identifier }
            let existingEntriesDict = Dictionary(uniqueKeysWithValues: existingEntries.map{ ($0.identifier, $0) })
            
            for entryRep in entries {
                guard let identifier = entryRep.identifier else { continue }
                
                if existingEntryIdentifiers.contains(identifier) {
                    guard let entry = existingEntriesDict[identifier] else { continue }
                    self.update(entry: entry, with: entryRep)
                } else {
                    _ = Entry(entryRepresentation: entryRep, context: self.context)
                }
            }
            completion(nil)
        }
        print("Syncing finished!")
    }
    
    private func getAllExistingEntries(identifiers: [String]) -> [Entry] {
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiers)
        
        var results: [Entry] = []
        do {
            results = try context.fetch(fetchRequest)
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return results
    }
    
    private func update(entry: Entry, with entryRep: EntryRepresentation) {
        entry.title = entryRep.title
        entry.bodyText = entryRep.bodyText
        entry.mood = entryRep.mood
        entry.timestamp = entryRep.timestamp
        entry.identifier = entryRep.identifier
    }
    
    private func fetchSingleEntryFromPersistentStore(with identifier: String?, in context: NSManagedObjectContext) -> Entry? {
        
        guard let identifier = identifier else { return nil }
        
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)
        
        var result: Entry? = nil
        do {
            result = try context.fetch(fetchRequest).first
        } catch {
            NSLog("Error fetching single entry: \(error)")
        }
        return result
    }
    
    let context: NSManagedObjectContext
}
