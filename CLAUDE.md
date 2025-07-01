# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CodeNote is a SwiftUI-based iOS note-taking application that integrates with iCloud for synchronization. The app is designed to be a comprehensive notes app with folder management, note creation/editing, and search capabilities.

## Architecture

- **Framework**: SwiftUI for UI, SwiftData for data persistence
- **Data Layer**: SwiftData with iCloud integration via ModelContainer
- **Core Model**: `Item` class representing individual notes with timestamps
- **Main Views**: 
  - `ContentView`: Main interface with NavigationSplitView, handles note listing and CRUD operations
  - `CodeNoteApp`: App entry point with SwiftData model container setup

## Key Components

### Data Model
- `Item.swift`: SwiftData model for notes, currently stores only timestamps but designed to be extended
- Model container configured for iCloud sync with persistent storage

### UI Structure
- Uses NavigationSplitView for master-detail interface
- Supports both iOS and macOS with conditional toolbar items
- Preview-driven development with SwiftUI previews

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project CodeNote.xcodeproj -scheme CodeNote build

# Run on simulator
xcodebuild -project CodeNote.xcodeproj -scheme CodeNote -destination 'platform=iOS Simulator,name=iPhone 15' test

# Archive for distribution
xcodebuild -project CodeNote.xcodeproj -scheme CodeNote archive -archivePath ./build/CodeNote.xcarchive
```

### Opening in Xcode
```bash
open CodeNote.xcodeproj
```

## Product Requirements Context

The project includes a comprehensive PRD (`note.md`) that outlines:
- Target audience: Students, professionals, general consumers
- Core features: Folder management, note editing with auto-save, search with voice input, iCloud sync
- Technical requirements: iOS 15+, native Swift, iCloud Core Data integration
- Performance targets: <2s launch time, <1s search response, <5s sync latency

## Development Notes

- Enhanced data model with Apple Intelligence integration for note summarization
- Core data model includes Note and Folder entities with iCloud sync support
- Apple Intelligence summarization using UIWritingToolsCoordinator (iOS 18.1+) with intelligent fallback
- UI displays auto-generated summaries between hashtags and creation dates in note list view
- Voice search and additional advanced features from PRD still need implementation

### Apple Intelligence Integration

- **Framework**: Apple's FoundationModels framework (iOS 18+ beta) for Apple Intelligence features
- **Implementation**: Ready for Apple Intelligence API when fully documented (currently using intelligent fallback)
- **Summarization**: Automatic summary generation for notes >50 characters with async processing
- **Fallback Strategy**: Enhanced sentence-based summarization with intelligent text analysis
- **UI Integration**: Summaries displayed between hashtags and creation date in NoteListView as requested
- **Performance**: Async generation with multi-tier fallback to ensure smooth user experience
- **Future-Ready**: Infrastructure prepared for full Apple Intelligence API integration

## Testing

- Unit tests should be added for data model operations
- UI tests should cover note CRUD operations and navigation flows
- iCloud sync testing requires device testing, not just simulator

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftUI best practices with @State, @Binding, and @Environment properly
- Maintain preview compatibility for all views
- Use proper SwiftData relationships and queries for complex data operations