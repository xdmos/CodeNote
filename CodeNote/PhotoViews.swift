//
//  PhotoViews.swift
//  CodeNote
//
//  Created by Macbook M4 Pro on 01/07/2025.
//

import SwiftUI

struct PhotoScrollView: View {
    let photos: [Data]
    let onPhotoTap: (Int) -> Void
    let onPhotoDelete: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photoData in
                    if let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .onTapGesture {
                                onPhotoTap(index)
                            }
                            .contextMenu {
                                Button("Usuń", role: .destructive) {
                                    onPhotoDelete(index)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 100)
    }
}

struct FullScreenImageView: View {
    let photos: [Data]
    @Binding var currentIndex: Int
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if !photos.isEmpty, currentIndex < photos.count {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { index, photoData in
                            if let image = UIImage(data: photoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2.weight(.medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}