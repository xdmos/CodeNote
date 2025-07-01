//
//  NoteEditorView.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let note: Note
    @State private var content: String = ""
    @State private var title: String = ""
    @State private var isEditing = false
    @State private var showingSaveIndicator = false
    @FocusState private var focusedField: FocusedField?
    
    private let autoSaveInterval: TimeInterval = 3.0
    @State private var autoSaveTimer: Timer?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingFullScreenImage = false
    @State private var fullScreenImageIndex = 0
    
    enum FocusedField {
        case title, content
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background that adapts to light/dark mode
                Group {
                    #if canImport(UIKit)
                    Color(.systemBackground)
                    #else
                    Color(NSColor.controlBackgroundColor)
                    #endif
                }
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }
                
                VStack(spacing: 0) {
                    // Simple header with only back button
                    HStack {
                        Button(action: {
                            saveNote()
                            // Generate summary when transitioning back to notes list
                            note.regenerateSummary()
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Notes")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.primary)
                        }
                        .accessibilityLabel("Back to Notes")
                        .accessibilityHint("Save note and return to notes list")
                        
                        Spacer()
                        
                        // Modified date only
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.body)
                                .foregroundStyle(.orange)
                            Text(note.modifiedAt, style: .date)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.1), in: Capsule())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 70)
                    
                    // Hashtags section
                    HashtagsEditView(note: note)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Photos section - horizontal scroll
                    if !note.photos.isEmpty {
                        PhotoScrollView(photos: note.photos, onPhotoTap: { index in
                            fullScreenImageIndex = index
                            showingFullScreenImage = true
                        }, onPhotoDelete: { index in
                            note.removePhoto(at: index)
                            saveNote()
                        })
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    
                    // Custom text editor with bold first line
                    ZStack {
                        CustomTextEditor(text: $content)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .onChange(of: content) { _, _ in
                                scheduleAutoSave()
                            }
                        
                        // Floating action buttons in bottom right corner
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 12) {
                                    // Photo picker button
                                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                            .frame(width: 44, height: 44)
                                            .background(.regularMaterial, in: Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    }
                                    .accessibilityLabel("Add Photo")
                                    .accessibilityHint("Select a photo from your photo library to add to this note")
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 34)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(.all)
        #if canImport(UIKit)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        #endif
        .onAppear {
            title = note.title
            content = note.content
        }
        .onDisappear {
            saveNote()
            // Generate summary every time when leaving note view
            note.regenerateSummary()
            autoSaveTimer?.invalidate()
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            if let newPhoto = newPhoto {
                loadPhoto(from: newPhoto)
            }
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(photos: note.photos, currentIndex: $fullScreenImageIndex, isPresented: $showingFullScreenImage)
        }
    }
    
    private func scheduleAutoSave() {
        showingSaveIndicator = true
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: false) { _ in
            saveNote()
        }
    }
    
    private func saveNote() {
        note.title = title.isEmpty ? generateTitleFromContent() : title
        note.updateContent(content)
        
        do {
            try modelContext.save()
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSaveIndicator = false
            }
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private func generateTitleFromContent() -> String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return firstLine.isEmpty ? "New Note" : String(firstLine.prefix(50))
    }
    
    private func loadPhoto(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                DispatchQueue.main.async {
                    self.note.addPhoto(data)
                    self.saveNote()
                    self.selectedPhoto = nil
                }
            }
        }
    }
}

struct GlassEditorHeaderView: View {
    let folderName: String
    let showingSaveIndicator: Bool
    let onBack: () -> Void
    let onShare: () -> Void
    let onDone: () -> Void
    
    var body: some View {
        HStack {
            // Back button
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text(folderName)
                        .font(.body.weight(.medium))
                }
                .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Save indicator
            if showingSaveIndicator {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Saving...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                // Share button
                Button(action: onShare) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 40, height: 40)
                        .background(.regularMaterial, in: Circle())
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Done button
                Button("Done", action: onDone)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct GlassEditorFooterView: View {
    let modifiedAt: Date
    let characterCount: Int
    let wordCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Last change: \(modifiedAt, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.abc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(characterCount) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Floating quick actions
            HStack(spacing: 12) {
                // Voice note button
                Button(action: {
                    // Voice note functionality
                }) {
                    Image(systemName: "mic.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .background(.regularMaterial, in: Circle())
                        .clipShape(Circle())
                }
                
                // Camera button
                Button(action: {
                    // Camera functionality
                }) {
                    Image(systemName: "camera.circle.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .background(.regularMaterial, in: Circle())
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 34) // Extra padding for home indicator area
    }
}

#Preview {
    let folder = Folder(name: "Example")
    let note = Note(title: "Example Note", content: "This is an example of note content.", folder: folder)
    
    return NoteEditorView(note: note)
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
}

#if canImport(UIKit)
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 24)
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.label
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let attributedString = createAttributedString(from: text)
            uiView.attributedText = attributedString
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createAttributedString(from text: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let font = UIFont.systemFont(ofSize: 24)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.label
            ]
            
            let lineString = NSAttributedString(string: line, attributes: attributes)
            attributedString.append(lineString)
            
            if index < lines.count - 1 {
                let lineBreak = NSAttributedString(string: "\n", attributes: attributes)
                attributedString.append(lineBreak)
            }
        }
        
        return attributedString
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        
        init(_ parent: CustomTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            
            // Update formatting after text changes
            let attributedString = parent.createAttributedString(from: textView.text)
            let selectedRange = textView.selectedTextRange
            textView.attributedText = attributedString
            
            // Restore cursor position
            if let selectedRange = selectedRange {
                textView.selectedTextRange = selectedRange
            }
        }
    }
}
#else
// Fallback for macOS
struct CustomTextEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 24))
    }
}
#endif

struct HashtagsEditView: View {
    let note: Note
    @State private var showingPriorityPicker = false
    @State private var showingStatusPicker = false
    @State private var showingTypePicker = false
    
    let priorities = ["Low", "Medium", "High"]
    let statuses = ["Not Started", "In Progress", "Done"]
    let types = ["Feature", "Bug", "Improvement"]
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority hashtag
            Button(action: {
                showingPriorityPicker = true
            }) {
                Text(note.priority)
                    .font(.body.weight(.medium))
                    .foregroundStyle(priorityColor(note.priority))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(priorityColor(note.priority).opacity(0.1), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(priorityColor(note.priority).opacity(0.3), lineWidth: 1)
                    )
            }
            .actionSheet(isPresented: $showingPriorityPicker) {
                ActionSheet(
                    title: Text("Select Priority"),
                    buttons: priorities.map { priority in
                        .default(Text(priority)) {
                            note.priority = priority
                        }
                    } + [.cancel()]
                )
            }
            
            // Status hashtag
            Button(action: {
                showingStatusPicker = true
            }) {
                Text(note.status)
                    .font(.body.weight(.medium))
                    .foregroundStyle(statusColor(note.status))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(statusColor(note.status).opacity(0.1), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(statusColor(note.status).opacity(0.3), lineWidth: 1)
                    )
            }
            .actionSheet(isPresented: $showingStatusPicker) {
                ActionSheet(
                    title: Text("Select Status"),
                    buttons: statuses.map { status in
                        .default(Text(status)) {
                            note.status = status
                        }
                    } + [.cancel()]
                )
            }
            
            // Type hashtag
            Button(action: {
                showingTypePicker = true
            }) {
                Text(note.type)
                    .font(.body.weight(.medium))
                    .foregroundStyle(typeColor(note.type))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(typeColor(note.type).opacity(0.1), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(typeColor(note.type).opacity(0.3), lineWidth: 1)
                    )
            }
            .actionSheet(isPresented: $showingTypePicker) {
                ActionSheet(
                    title: Text("Select Type"),
                    buttons: types.map { type in
                        .default(Text(type)) {
                            note.type = type
                        }
                    } + [.cancel()]
                )
            }
            
            Spacer()
        }
    }
    
    // Color functions for hashtags
    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .green
        default: return .gray
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Not Started": return .gray
        case "In Progress": return .blue
        case "Done": return .green
        default: return .gray
        }
    }
    
    private func typeColor(_ type: String) -> Color {
        switch type {
        case "Bug": return .red
        case "Feature": return .blue
        case "Improvement": return .purple
        default: return .gray
        }
    }
}