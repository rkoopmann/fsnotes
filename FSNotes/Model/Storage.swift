//
//  NotesCollection.swift
//  FSNotes
//
//  Created by Oleksandr Glushchenko on 8/9/17.
//  Copyright © 2017 Oleksandr Glushchenko. All rights reserved.
//

import Foundation

class Storage {
    static let instance = Storage()
    
    var noteList = [Note]()
    var i: Int = 0
    static var pinned: Int = 0
    
    func loadFiles() {
        var markdownFiles = readDocuments()

        if (markdownFiles.count == 0) {
            copyInitialNote()
            markdownFiles.append("Hello world.md")
        }
        
        let existNotes = CoreDataManager.instance.fetchNotes()
        
        for markdownPath in markdownFiles {
            let url = UserDefaultsManagement.storageUrl.appendingPathComponent(markdownPath)
            let name = url
                .deletingPathExtension()
                .pathComponents
                .last!
                .replacingOccurrences(of: ":", with: "/")
            
            if (url.pathComponents.count == 0) {
                continue
            }
            
            var note: Note
            
            if !existNotes.contains(where: { $0.name == name }) {
                note = CoreDataManager.instance.createNote()
                note.name = name
                note.type = url.pathExtension
                CoreDataManager.instance.saveContext()
                print("saved \(note.name)")
            } else {
                note = existNotes.first(where: { $0.name == name })!
            }

            note.url = url
            note.extractUrl()
            note.load()
            note.id = i
            
            if note.isPinned {
                Storage.pinned += 1
            }
            
            i += 1
            
            noteList.append(note)
        }
    }
    
    func readDocuments() -> Array<String> {
        let urlArray = [String]()
        let directory = UserDefaultsManagement.storageUrl
        
        if let urlArray = try? FileManager.default.contentsOfDirectory(at: directory,
                                                                       includingPropertiesForKeys: [.contentModificationDateKey],
                                                                       options:.skipsHiddenFiles) {
            
            let allowedExtensions = [
                "md",
                "markdown",
                "txt",
                "rtf",
                UserDefaultsManagement.storageExtension
            ]
            
            let markdownFiles = urlArray.filter {
                allowedExtensions.contains($0.pathExtension)
            }
            
            return markdownFiles.map { url in
                (
                    url.lastPathComponent,
                    (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast)
                }
                .sorted(by: { $0.1 > $1.1 })
                .map { $0.0 }
        }
        
        return urlArray
    }
    
    func add(note: Note) {
        noteList.append(note)
    }
    
    func remove(id: Int) {
        noteList[id].isRemoved = true
    }
    
    func getNextId() -> Int {
        return noteList.count
    }
    
    func copyInitialNote() {
        let initialDoc = Bundle.main.url(forResource: "Hello world", withExtension: "md")
        var destination = UserDefaultsManagement.storageUrl
        destination.appendPathComponent("Hello world.md")
        
        do {
            let manager = FileManager.default
            try manager.copyItem(at: initialDoc!, to: destination)
        } catch {
            print("Initial copy error: \(error)")
        }
    }
    
    func getOrCreateNote(name: String) -> Note {
        let list = Storage.instance.noteList.filter() {
            return ($0.name == name)
        }
        if list.count > 0 {
            return list.first!
        }
        
        let note = CoreDataManager.instance.createNote()
        add(note: note)
        return note
    }
    
    func getModifiedLatestThen() -> [Note] {
        return
            Storage.instance.noteList.filter() {
                return (
                    !$0.isSynced
                )
        }
    }

}
