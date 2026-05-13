//
//  FavourtiesView.swift
//  StudyFinder
//
//  Created by Tristan Lim on 13/5/2026.
//
import SwiftUI

struct FavouritesView: View {
    let favouritePlaces: [Place]
    @Binding var selectedPlace: Place?
    
    var body: some View {
        NavigationStack {
            Group {
                if favouritePlaces.isEmpty {
                    ContentUnavailableView(
                        "No Favourites Yet",
                        systemImage: "heart",
                        description: Text("Tap the heart on a study place to save it here.")
                    )
                } else {
                    List(favouritePlaces) { place in
                        Button {
                            selectedPlace = place
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    Text("\(place.type) - Rating: \(place.rating)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favourites")
        }
    }
}

#Preview {
    FavouritesView(favouritePlaces: [], selectedPlace: .constant(nil))
}