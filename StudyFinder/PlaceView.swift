//
//  PlaceView.swift
//  StudyFinder
//
//  Created by Eden Hallett on 12/5/2026.
//

import SwiftUI

struct PlaceView: View {
    
    @Environment(\.dismiss) private var dismiss
    var onNavigate: () -> Void
    
    let place: Place
    
    var body: some View {
        VStack {
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
            
            Text(place.name).font(.title).bold()
            Text("Rating: \(place.rating)")
            Text("Wifi: \(place.hasWifi ? "Yes" : "No")")
            Text("Outlets: \(place.hasOutlets ? "Yes" : "No")")
            Text("Noise Level: \(place.noiseLevel)")
            
            Button("Navigate") {
                onNavigate()
                dismiss()
            }
        }
    }
}
/*
 #Preview {
 PlaceView()
 }
 */
