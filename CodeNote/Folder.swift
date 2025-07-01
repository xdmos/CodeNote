//
//  Folder.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Note.folder)
    var notes: [Note] = []
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
    
    var noteCount: Int {
        notes.count
    }
}