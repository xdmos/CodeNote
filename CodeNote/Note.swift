//
//  Note.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import Foundation
import SwiftData
import FoundationModels

// Timeout utility for Foundation Models API calls
func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    return try await withThrowingTaskGroup(of: T?.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return nil // Return nil instead of throwing to avoid isolation issues
        }
        
        for try await result in group {
            if let result = result {
                group.cancelAll()
                return result
            }
        }
        
        throw TimeoutError()
    }
}

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "Foundation Models API call timed out"
    }
}

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
    var status: String = "Not Started"
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
        self.status = "Not Started" 
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
        print("🔄 DEBUG: updateContent called with: '\(newContent.prefix(50))'")
        self.content = newContent
        self.modifiedAt = Date()
        
        // Generate intelligent title (3-5 words) using Foundation framework
        generateIntelligentTitle()
        
        // Generate summary using Apple Intelligence FoundationModels framework
        print("🔄 DEBUG: About to call generateSummary() from updateContent")
        generateSummary()
    }
    
    private func generateIntelligentTitle() {
        guard !content.isEmpty else {
            self.title = "New Note"
            return
        }
        
        // Use Apple Foundation Models for title generation
        Task {
            await generateFoundationModelsTitle()
        }
    }
    
    @MainActor
    private func generateFoundationModelsTitle() async {
        do {
            // Try to use Foundation Models for title generation
            let generatedTitle = try await generateTitleWithFoundationModels(text: content)
            self.title = generatedTitle.isEmpty ? fallbackTitle() : generatedTitle
            print("✅ TITLE GENERATION SUCCESS: '\(self.title)'")
        } catch {
            // Fallback if Foundation Models fails
            print("❌ TITLE GENERATION FAILED: \(error.localizedDescription)")
            print("🔄 Using fallback title generation...")
            self.title = fallbackTitle()
            print("📝 Fallback title: '\(self.title)'")
        }
    }
    
    @available(iOS 18.0, *)
    private func generateTitleWithFoundationModels(text: String) async throws -> String {
        // DEBUG: Check input text
        print("🔍 DEBUG TITLE: Input text length: \(text.count)")
        print("🔍 DEBUG TITLE: Input text preview: '\(text.prefix(100))'")
        
        // Foundation Models API for title generation
        // When Apple releases the final API, this will work:
        
        /*
        let session = LanguageModelSession()
        
        let prompt = Prompt {
            "Generate a concise title for this note in 2-4 words."
            "Make it descriptive and professional."
            "Only return the title, nothing else."
            ""
            text
        }
        
        let response = try await session.respond(to: prompt)
        let finalResponse = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // DEBUG: Log Foundation Models response for title
        print("🤖 FOUNDATION MODELS TITLE RESPONSE:")
        print("📝 Input text: \(text.prefix(100))...")
        print("🎯 Generated title: '\(finalResponse)'")
        print("📊 Title length: \(finalResponse.count) characters")
        print("---")
        
        return finalResponse
        */
        
        // Foundation Models framework (iOS 26 built-in) with timeout
        let session = LanguageModelSession()
        
        let prompt = Prompt {
            "Generate a concise title for this note in 2-4 words."
            "Make it descriptive and professional." 
            "Only return the title, nothing else."
            ""
            text
        }
        
        // Add timeout to prevent hanging in simulator
        let response = try await withTimeout(seconds: 10) {
            try await session.respond(to: prompt)
        }
        let finalResponse = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // DEBUG: Log Foundation Models response for title
        print("🤖 FOUNDATION MODELS TITLE RESPONSE:")
        print("📝 Input text: \(text.prefix(100))...")
        print("🎯 Generated title: '\(finalResponse)'")
        print("📊 Title length: \(finalResponse.count) characters")
        print("---")
        
        // Check if Foundation Models returned an error-like response
        let errorIndicators = [
            "I'm sorry, but I can't",
            "I cannot provide",
            "Could you please provide",
            "without the actual content",
            "I don't have access",
            "I'm unable to create",
            "I can't view or process",
            "I cannot fulfill that request",
            "I can't assist with that",
            "if you provide the text content",
            "However, if you provide",
            "I can't process text from",
            "I cannot assist with",
            "visual content",
            "modify visual content",
            "text-based summaries",
            "Please provide the note content"
        ]
        
        let responseContainsError = errorIndicators.contains { indicator in
            finalResponse.lowercased().contains(indicator.lowercased())
        }
        
        if responseContainsError {
            print("⚠️ Foundation Models returned error-like response, throwing error to trigger fallback")
            throw NSError(domain: "FoundationModelsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Foundation Models returned an error response"])
        }
        
        return finalResponse
    }
    
    private func fallbackTitle() -> String {
        // Smart fallback: extract key words for title
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanContent.isEmpty {
            return "New Note"
        }
        
        // Try to extract meaningful title from first sentence
        let firstSentence = cleanContent.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if firstSentence.isEmpty {
            return "New Note"
        }
        
        // Extract important words (skip common words)
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them"])
        
        let words = firstSentence.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !commonWords.contains($0) && $0.count > 2 }
        
        // Take first 2-3 important words
        let titleWords = Array(words.prefix(3))
        
        if titleWords.isEmpty {
            // If no meaningful words found, use first few words
            let allWords = firstSentence.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            return Array(allWords.prefix(3)).joined(separator: " ")
        }
        
        // Capitalize first letter of each word
        let capitalizedTitle = titleWords.map { word in
            String(word.prefix(1).uppercased() + word.dropFirst())
        }.joined(separator: " ")
        
        return capitalizedTitle
    }
    
    private func generateSummary() {
        // DEBUG: Check if generateSummary is called
        print("🔍 DEBUG SUMMARY: generateSummary() called with content length: \(content.count)")
        print("🔍 DEBUG SUMMARY: Content preview: '\(content.prefix(50))'")
        
        // Only generate summary for content longer than 10 characters
        guard content.count > 10 else {
            print("⚠️ SUMMARY: Content too short (\(content.count) chars), skipping summary generation")
            summary = ""
            return
        }
        
        print("✅ SUMMARY: Starting summary generation...")
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
                summary = try await generateSummaryWithFoundationModels(text: content)
                print("✅ SUMMARY GENERATION SUCCESS: '\(summary)'")
            } catch {
                // Fallback if FoundationModels fails
                print("❌ SUMMARY GENERATION FAILED: \(error.localizedDescription)")
                print("🔄 Using fallback summary generation...")
                summary = createFallbackSummary()
                print("📋 Fallback summary: '\(summary)'")
            }
        } else {
            // Fallback for older iOS versions
            print("⚠️ iOS VERSION TOO OLD: Using fallback summary")
            summary = createFallbackSummary()
            print("📋 Fallback summary: '\(summary)'")
        }
    }
    
    @available(iOS 18.0, *)
    private func generateSummaryWithFoundationModels(text: String) async throws -> String {
        // DEBUG: Check input text
        print("🔍 DEBUG: Input text length: \(text.count)")
        print("🔍 DEBUG: Input text preview: '\(text.prefix(100))'")
        
        // Foundation Models API for summary generation
        // When Apple releases the final API, this will work:
        
        /*
        let session = LanguageModelSession()
        
        let prompt = Prompt {
            "Create a brief summary of this note content."
            "Keep it under 100 characters and focus on key points."
            "Make it clear and informative."
            "Only return the summary, nothing else."
            ""
            text
        }
        
        let response = try await session.respond(to: prompt)
        let finalResponse = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // DEBUG: Log Foundation Models response for summary
        print("🤖 FOUNDATION MODELS SUMMARY RESPONSE:")
        print("📝 Input text: \(text.prefix(200))...")
        print("📋 Generated summary: '\(finalResponse)'")
        print("📊 Summary length: \(finalResponse.count) characters")
        print("📏 Fits in 4 lines: \(finalResponse.count <= 200 ? "✅" : "❌")")
        print("---")
        
        return finalResponse
        */
        
        // Foundation Models framework (iOS 26 built-in) with timeout
        let session = LanguageModelSession()
        
        let prompt = Prompt {
            "You are summarizing TEXT CONTENT from a note."
            "This is plain text, not an image or visual content."
            "Create a brief summary of this note content."
            "Keep it under 100 characters and focus on key points."
            "Make it clear and informative."
            "Only return the summary, nothing else."
            ""
            text
        }
        
        // Add timeout to prevent hanging in simulator
        let response = try await withTimeout(seconds: 10) {
            try await session.respond(to: prompt)
        }
        let finalResponse = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // DEBUG: Log Foundation Models response for summary
        print("🤖 FOUNDATION MODELS SUMMARY RESPONSE:")
        print("📝 Input text: \(text.prefix(200))...")
        print("📋 Generated summary: '\(finalResponse)'")
        print("📊 Summary length: \(finalResponse.count) characters")
        print("📏 Fits in 4 lines: \(finalResponse.count <= 200 ? "✅" : "❌")")
        print("---")
        
        // Check if Foundation Models returned an error-like response
        let errorIndicators = [
            "I'm sorry, but I can't",
            "I cannot provide",
            "Could you please provide",
            "without the actual content",
            "I don't have access",
            "I'm unable to create",
            "I can't view or process",
            "I cannot fulfill that request",
            "I can't assist with that",
            "if you provide the text content",
            "However, if you provide",
            "I can't process text from",
            "I cannot assist with",
            "visual content",
            "modify visual content",
            "text-based summaries",
            "Please provide the note content"
        ]
        
        let responseContainsError = errorIndicators.contains { indicator in
            finalResponse.lowercased().contains(indicator.lowercased())
        }
        
        if responseContainsError {
            print("⚠️ Foundation Models returned error-like response, throwing error to trigger fallback")
            throw NSError(domain: "FoundationModelsError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Foundation Models returned an error response"])
        }
        
        return finalResponse
    }
    
    private func createFallbackSummary() -> String {
        // Smart fallback: create actual summary from content
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If content is short, return it as is
        if cleanContent.count <= 100 {
            return cleanContent
        }
        
        // Extract key sentences for summary
        let sentences = cleanContent.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        // Take first sentence and one key sentence from middle/end
        var summaryParts: [String] = []
        
        if let firstSentence = sentences.first {
            summaryParts.append(firstSentence)
        }
        
        // Add a key sentence from later in the text if available
        if sentences.count > 2 {
            let midIndex = sentences.count / 2
            if midIndex < sentences.count {
                summaryParts.append(sentences[midIndex])
            }
        }
        
        let summary = summaryParts.joined(separator: ". ") + (summaryParts.count > 1 ? "." : "")
        
        // Limit to reasonable length for display
        if summary.count > 180 {
            let truncated = String(summary.prefix(180))
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }
        
        return summary
    }
    
    // Public method to regenerate summary manually
    func regenerateSummary() {
        print("🔄 DEBUG: regenerateSummary() called manually")
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