//
//  FolderView.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 29/06/2025.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct FolderView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [Folder]
    @State private var showingCreateFolder = false
    @State private var newFolderName = ""
    @State private var showingEditFolder = false
    @State private var editingFolder: Folder?
    @State private var editFolderName = ""
    
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
                
                VStack(spacing: 0) {
                    // Top buttons - right under status bar
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Create folder button with glass effect
                            Button(action: {
                                showingCreateFolder = true
                            }) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(.regularMaterial, in: Circle())
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Folder List with swipe-to-edit
                    List {
                        ForEach(folders) { folder in
                            NavigationLink(destination: NoteListView(folder: folder)) {
                                SimpleFolderRowView(folder: folder)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .swipeActions(edge: .leading) {
                                Button("Edit") {
                                    editFolder(folder)
                                }
                                .tint(.blue)
                            }
                        }
                        .onDelete(perform: deleteFolders)
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all)
        #if canImport(UIKit)
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        #endif
        .alert("New Folder", isPresented: $showingCreateFolder) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                createFolder()
            }
            .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("Edit Folder", isPresented: $showingEditFolder) {
            TextField("Folder Name", text: $editFolderName)
            Button("Cancel", role: .cancel) {
                editingFolder = nil
                editFolderName = ""
            }
            Button("Save") {
                saveEditedFolder()
            }
            .disabled(editFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .onAppear {
            createDefaultFoldersIfNeeded()
        }
    }
    
    private func createFolder() {
        let trimmedName = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newFolder = Folder(name: trimmedName)
        modelContext.insert(newFolder)
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating folder: \(error)")
        }
        
        newFolderName = ""
    }
    
    private func createDefaultFoldersIfNeeded() {
        // Application starts empty - no default folders or notes
    }
    
    private func deleteFolders(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let folder = folders[index]
                // Delete all notes in the folder first
                for note in folder.notes {
                    modelContext.delete(note)
                }
                // Then delete the folder
                modelContext.delete(folder)
            }
            
            do {
                try modelContext.save()
            } catch {
                print("Error deleting folders: \(error)")
            }
        }
    }
    
    private func editFolder(_ folder: Folder) {
        editingFolder = folder
        editFolderName = folder.name
        showingEditFolder = true
    }
    
    private func saveEditedFolder() {
        guard let folder = editingFolder else { return }
        let trimmedName = editFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        folder.name = trimmedName
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating folder: \(error)")
        }
        
        editingFolder = nil
        editFolderName = ""
    }
    
    private func deleteFolder(folder: Folder) {
        // Delete all notes in the folder first
        for note in folder.notes {
            modelContext.delete(note)
        }
        
        // Then delete the folder
        modelContext.delete(folder)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting folder: \(error)")
        }
    }
}

struct GlassFolderRowView: View {
    let folder: Folder
    let onTap: () -> Void
    let onDelete: () -> Void
    @State private var isPressed = false
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                Button(action: {
                    #if canImport(UIKit)
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    #endif
                    withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.8)) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(Color.red)
                        .cornerRadius(16)
                }
                .opacity(showingDeleteButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showingDeleteButton)
            }
            
            // Main content
            HStack(spacing: 16) {
                // Folder icon without border
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 50, height: 50)
                
                // Folder info
                VStack(alignment: .leading, spacing: 4) {
                    Text(folder.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                .regularMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(x: offset)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: offset)
            .onTapGesture {
                if showingDeleteButton {
                    withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8)) {
                        offset = 0
                        showingDeleteButton = false
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation < 0 {
                            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 1.0)) {
                                offset = max(translation, -80)
                                showingDeleteButton = offset < -40
                            }
                        }
                    }
                    .onEnded { value in
                        let velocity = value.velocity.width
                        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                            if offset < -40 || velocity < -300 {
                                offset = -80
                                showingDeleteButton = true
                            } else {
                                offset = 0
                                showingDeleteButton = false
                            }
                        }
                    }
            )
            .pressEvents {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
            } onRelease: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        .clipped()
    }
}


struct SimpleFolderRowView: View {
    let folder: Folder
    
    var body: some View {
        HStack(spacing: 16) {
            // Folder icon without border - 2x bigger
            Image(systemName: "folder.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .frame(width: 50, height: 50)
            
            // Folder info - 2x bigger
            VStack(alignment: .leading, spacing: 4) {
                Text(folder.name)
                    .font(.title.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(height: 66)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    FolderView()
        .modelContainer(for: [Folder.self, Note.self], inMemory: true)
}