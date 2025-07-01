//
//  NoteListView.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let folder: Folder
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    @State private var selectedNote: Note?
    
    var filteredNotes: [Note] {
        let notes = folder.notes.sorted { $0.modifiedAt > $1.modifiedAt }
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.title.localizedCaseInsensitiveContains(searchText) ||
            note.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background that adapts to light/dark mode
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isSearchFocused = false
                    }
                
                VStack(spacing: 0) {
                    // Top buttons - right under status bar
                    HStack {
                        // Back button
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Foldery")
                                    .font(.body.weight(.medium))
                            }
                            .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 70)
                    
                    // Notes List with glass cards
                    List {
                        ForEach(filteredNotes) { note in
                            SimpleNoteRowView(note: note, onTap: {
                                selectedNote = note
                            })
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Glass search bar - fixed at bottom
                    GlassNoteSearchBarView(searchText: $searchText, folder: folder, modelContext: modelContext, isSearchFocused: $isSearchFocused, createNote: createNewNote)
                }
            }
        }
        .ignoresSafeArea(.all)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(item: $selectedNote) { note in
            NoteEditorView(note: note)
        }
    }
    
    private func createNewNote() {
        let newNote = Note(title: "Nowa notatka", content: "", folder: folder)
        modelContext.insert(newNote)
        
        do {
            try modelContext.save()
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Automatically open the new note in editor
            selectedNote = newNote
        } catch {
            print("Error creating note: \(error)")
        }
    }
    
    private func deleteNote(note: Note) {
        modelContext.delete(note)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting note: \(error)")
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredNotes[index])
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Error deleting notes: \(error)")
            }
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

struct GlassNoteSearchBarView: View {
    @Binding var searchText: String
    let folder: Folder
    let modelContext: ModelContext
    @FocusState.Binding var isSearchFocused: Bool
    let createNote: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.body.weight(.medium))
                
                TextField("Szukaj w \(folder.name)", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            
            // Action buttons
            // Compose button or close keyboard button
            Button(action: {
                if isSearchFocused {
                    isSearchFocused = false
                } else {
                    createNote()
                }
            }) {
                Image(systemName: isSearchFocused ? "xmark" : "square.and.pencil")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 34) // Extra padding for home indicator area
    }
    
}


struct SimpleNoteRowView: View {
    let note: Note
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(note.title.isEmpty ? "Nowa notatka" : note.title)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        // Priority hashtag
                        Text(note.priority)
                            .font(.body.weight(.medium))
                            .foregroundStyle(priorityColor(note.priority))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(priorityColor(note.priority).opacity(0.1), in: Capsule())
                        
                        // Status hashtag
                        Text(note.status)
                            .font(.body.weight(.medium))
                            .foregroundStyle(statusColor(note.status))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(statusColor(note.status).opacity(0.1), in: Capsule())
                        
                        // Type hashtag
                        Text(note.type)
                            .font(.body.weight(.medium))
                            .foregroundStyle(typeColor(note.type))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(typeColor(note.type).opacity(0.1), in: Capsule())
                    }
                    
                    // Summary section
                    if !note.summary.isEmpty {
                        Text(note.summary)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineLimit(4)
                            .multilineTextAlignment(.leading)
                            .padding(.top, 4)
                    }
                    
                    // Created and modified dates on separate line
                    HStack {
                        // Created date on left
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text(note.createdAt, style: .date)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.1), in: Capsule())
                        
                        Spacer()
                        
                        // Modified date on right
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(note.modifiedAt, style: .date)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.orange.opacity(0.1), in: Capsule())
                    }
                }
                
                Spacer()
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 0)
        .padding(.vertical, 16)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
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


#Preview {
    let folder = Folder(name: "Przykład")
    let note1 = Note(title: "Pierwsza notatka", content: "To jest przykład treści notatki, która może być dłuższa i zawierać więcej informacji.", folder: folder)
    let note2 = Note(title: "Druga notatka", content: "Krótka treść", folder: folder)
    
    return NoteListView(folder: folder)
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
}