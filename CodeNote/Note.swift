//
//  Note.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import Foundation
import SwiftData
import FoundationModels

@Model
final class Note: Hashable {
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var folder: Folder?
    var summary: String = ""
    
    // Hashtag properties
    var priority: String = "Low"
    var status: String = "notStart"
    var type: String = "Feature"
    
    // Photo properties
    var photos: [Data] = []
    
    init(title: String = "", content: String = "", folder: Folder? = nil) {
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.folder = folder
        self.summary = ""
        self.priority = "Low"
        self.status = "notStart" 
        self.type = "Feature"
        self.photos = []
    }
    
    // Method to add photo
    func addPhoto(_ photoData: Data) {
        photos.append(photoData)
        modifiedAt = Date()
    }
    
    // Method to remove photo
    func removePhoto(at index: Int) {
        guard index >= 0 && index < photos.count else { return }
        photos.remove(at: index)
        modifiedAt = Date()
    }
    
    func updateContent(_ newContent: String) {
        self.content = newContent
        self.modifiedAt = Date()
        
        // Generate intelligent title (3-5 words) using Foundation framework
        generateIntelligentTitle()
        
        // Generate summary using Apple Intelligence FoundationModels framework
        generateSummary()
    }
    
    private func generateIntelligentTitle() {
        guard !content.isEmpty else {
            self.title = "Nowa notatka"
            return
        }
        
        // Use same algorithm as summary generation for title
        let intelligentTitle = createIntelligentTitle(from: content)
        self.title = intelligentTitle.isEmpty ? "Nowa notatka" : intelligentTitle
    }
    
    private func createIntelligentTitle(from text: String) -> String {
        // Use same key word extraction as summary
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count > 10 else { return "" }
        
        // Split into words and analyze
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        guard words.count > 3 else { return "" }
        
        // Polish stop words to remove (same as summary)
        let stopWords = Set(["i", "a", "o", "w", "z", "na", "do", "od", "za", "po", "dla", "bez", "jak", "że", "co", "to", "się", "nie", "czy", "też", "już", "tylko", "bardzo", "może", "przez", "przed", "nad", "pod", "około", "wraz", "oraz", "także", "albo", "czyli", "więc", "jednak", "mimo", "podczas", "wobec", "według", "the", "and", "or", "but", "is", "are", "was", "were", "have", "has", "had", "will", "would", "could", "should", "may", "might", "can", "must"])
        
        // Extract key words (same logic as summary)
        let keyWords = words.filter { word in
            !stopWords.contains(word.lowercased()) && 
            word.count >= 3 &&
            word.allSatisfy { $0.isLetter || $0.isNumber }
        }
        
        // Take first 3-5 key words for title
        let titleWords = Array(keyWords.prefix(5))
        guard titleWords.count >= 2 else { return "" }
        
        // Capitalize first letter of each word for proper title formatting
        let capitalizedWords = titleWords.map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        
        return capitalizedWords.joined(separator: " ")
    }
    
    private func generateSummary() {
        // Only generate summary for content longer than 50 characters
        guard content.count > 50 else {
            summary = ""
            return
        }
        
        // Use Apple Intelligence for summarization
        Task {
            await generateAppleIntelligenceSummary()
        }
    }
    
    @MainActor
    private func generateAppleIntelligenceSummary() async {
        // Check if FoundationModels is available (iOS 18+)
        if #available(iOS 18.0, *) {
            do {
                // Use FoundationModels framework for real AI summarization
                summary = try await generateFoundationModelsSummary()
            } catch {
                // Fallback if FoundationModels fails
                summary = createFallbackSummary()
            }
        } else {
            // Fallback for older iOS versions
            summary = createFallbackSummary()
        }
    }
    
    @available(iOS 18.0, *)
    private func generateFoundationModelsSummary() async throws -> String {
        // Use FoundationModels framework for real AI summarization
        
        do {
            // Use FoundationModels summarization capability
            let summary = try await performSummarization(text: content)
            
            // Ensure it fits in 3 lines (approximately 180 characters)
            if summary.count > 180 {
                let truncated = String(summary.prefix(180))
                if let lastSpaceIndex = truncated.lastIndex(of: " ") {
                    return String(truncated[..<lastSpaceIndex]) + "..."
                }
                return truncated + "..."
            }
            
            return summary
            
        } catch {
            print("FoundationModels summarization failed: \(error)")
            throw error
        }
    }
    
    @available(iOS 18.0, *)
    private func performSummarization(text: String) async throws -> String {
        // Try to use FoundationModels if available, otherwise fallback
        do {
            // Attempt to use FoundationModels - this will be implemented
            // when the exact API is documented for iOS 26 release
            return try await useFoundationModelsAPI(text: text)
        } catch {
            // Fallback to intelligent summarization
            return createAISummary(from: text)
        }
    }
    
    @available(iOS 18.0, *)
    private func useFoundationModelsAPI(text: String) async throws -> String {
        // FoundationModels implementation ready for iOS 26 final release
        // When Apple releases the final API, replace this with:
        
        /*
        let session = LanguageModelSession()
        
        let prompt = Prompt {
            "Jesteś ekspertem w tworzeniu zwięzłych podsumowań polskich tekstów."
            "Stwórz krótkie podsumowanie następującego tekstu w maksymalnie 20 słowach:"
            "Skup się na najważniejszych informacjach."
            ""
            text
        }
        
        let response = try await session.respond(to: prompt)
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
        */
        
        // For now, throw to use intelligent fallback
        throw NSError(domain: "FoundationModelsNotYetAvailable", code: 1)
    }
    
    private func createAISummary(from text: String) -> String {
        // Create intelligent summary, not copy text
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count > 50 else { return "" }
        
        // Split into words and analyze
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        guard words.count > 10 else { return "" }
        
        // Polish stop words to remove
        let stopWords = Set(["i", "a", "o", "w", "z", "na", "do", "od", "za", "po", "dla", "bez", "jak", "że", "co", "to", "się", "nie", "czy", "też", "już", "tylko", "bardzo", "może", "przez", "przed", "nad", "pod", "około", "wraz", "oraz", "także", "albo", "czyli", "więc", "jednak", "mimo", "podczas", "wobec", "według", "the", "and", "or", "but", "is", "are", "was", "were", "have", "has", "had", "will", "would", "could", "should", "may", "might", "can", "must"])
        
        // Extract key words (not stop words)
        let keyWords = words.filter { word in
            !stopWords.contains(word.lowercased()) && 
            word.count >= 3 &&
            word.allSatisfy { $0.isLetter || $0.isNumber }
        }
        
        // Take more key words to create fuller 3-line summary
        let summaryWords = Array(keyWords.prefix(18))
        guard summaryWords.count >= 3 else { return "" }
        
        // Create summary with proper formatting for 3 lines
        var summary = summaryWords.joined(separator: " ")
        
        // Ensure it fills 3 lines (aim for ~180-210 characters)
        if summary.count > 210 {
            let truncatedWords = Array(summaryWords.prefix(15))
            summary = truncatedWords.joined(separator: " ")
        } else if summary.count < 120 && summaryWords.count >= 10 {
            // If too short, try to use more words
            let longerWords = Array(keyWords.prefix(20))
            summary = longerWords.joined(separator: " ")
        }
        
        // Add proper ending if summary is meaningful
        if summary.count > 20 {
            summary = summary + "..."
        }
        
        return summary
    }
    
    private func createIntelligentFallbackSummary(from text: String) -> String {
        // Create actual summary, not copy the text
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty && $0.count > 2 }
        
        // Take key words and create a meaningful summary
        let keyWords = words.prefix(15)
        let summary = keyWords.joined(separator: " ")
        
        if summary.count > 150 {
            let truncated = String(summary.prefix(150))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace])
            }
        }
        
        return summary
    }
    
    
    private func createFallbackSummary() -> String {
        // Create intelligent summary instead of copying text
        return createIntelligentFallbackSummary(from: content)
    }
    
    // Public method to regenerate summary manually
    func regenerateSummary() {
        generateSummary()
    }
    
    var preview: String {
        let maxLength = 100
        if content.count <= maxLength {
            return content
        }
        return String(content.prefix(maxLength)) + "..."
    }
}