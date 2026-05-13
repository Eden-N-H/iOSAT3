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
