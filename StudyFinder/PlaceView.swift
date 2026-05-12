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
            Text(place.name)
            Text("Details about a place")
            
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
