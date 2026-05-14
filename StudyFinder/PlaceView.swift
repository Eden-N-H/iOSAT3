//
//  PlaceView.swift
//  StudyFinder
//
//  Created by Eden Hallett on 12/5/2026.
//

import SwiftUI

struct PlaceView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var isFavourite: Bool
    var onNavigate: () -> Void
    
    let place: Place
    let reviews: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(place.name)
                    .font(.title)
                    .bold()
                
                Button {
                    isFavourite.toggle()
                } label: {
                    Image(systemName: isFavourite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavourite ? .red : .secondary)
                        .font(.title2)
                }
                .accessibilityLabel(isFavourite ? "Remove from favourites" : "Add to favourites")
            }
            Text("Rating: \(place.rating, specifier: "%g")")
            Text("Wifi: \(place.hasWifi ? "Yes" : "No")")
            Text("Outlets: \(place.hasOutlets ? "Yes" : "No")")
            Text("Noise Level: \(place.noiseLevel)")

            VStack(alignment: .leading, spacing: 8) {
                Text("Reviews")
                    .font(.headline)
                
                if reviews.isEmpty {
                    Text("No reviews yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reviews, id: \.self) { review in
                        Text(review)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            
            Button("Navigate") {
                onNavigate()
                dismiss()
            }
        }
        .padding()
    }
}
/*
 #Preview {
 PlaceView()
 }
 */
