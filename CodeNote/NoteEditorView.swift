//
//  NoteEditorView.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
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
    
    enum FocusedField {
        case title, content
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background that adapts to light/dark mode
                Color(.systemBackground)
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
                                Text("Notatki")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.primary)
                        }
                        
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
                                    Button(action: {
                                        // Photo picker functionality
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }) {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                            .frame(width: 56, height: 56)
                                            .background(.regularMaterial, in: Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    }
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
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
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
        return firstLine.isEmpty ? "Nowa notatka" : String(firstLine.prefix(50))
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
                    Text("Zapisywanie...")
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
                Button("Gotowe", action: onDone)
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
                    
                    Text("Ostatnia zmiana: \(modifiedAt, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.abc")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(characterCount) znaków")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(wordCount) słów")
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
    let folder = Folder(name: "Przykład")
    let note = Note(title: "Przykładowa notatka", content: "To jest przykład treści notatki.", folder: folder)
    
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
    let statuses = ["notStart", "inProgress", "Done"]
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
                    title: Text("Wybierz priorytet"),
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
                    title: Text("Wybierz status"),
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
                    title: Text("Wybierz typ"),
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
        case "notStart": return .gray
        case "inProgress": return .blue
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