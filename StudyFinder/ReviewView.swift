//
//  ReviewView.swift
//  StudyFinder
//
//  Created by Eden Hallett on 14/5/2026.
//

import SwiftUI

struct ReviewView: View {
    
    let place: Place
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var review: String = ""
    @State private var rating: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color.blue.opacity(0.25), Color.green.opacity(0.2)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text("How was your experience with \(place.name)?").font(.title)
                        .bold()
                    
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star").foregroundStyle(.yellow)
                                .onTapGesture {
                                    rating = star
                                }
                        }
                    }.buttonStyle(.plain)
                    
                    TextEditor(text: $review)
                        .frame(height: geometry.size.height * 0.4)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    
                    Button("Submit"){
                        submitReview()
                        dismiss()
                    }.fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(review.isEmpty ? Color.blue.opacity(0.5) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(review.isEmpty)
                }.padding()
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(20)
                    .shadow(radius: 8)
                    .padding(.horizontal)
                
            }
            
        }
    }
    
    func submitReview() {
        let reviewKey = "reviews.\(place.name)"
        var reviews = UserDefaults.standard.stringArray(forKey: reviewKey) ?? []
        reviews.append("\(rating)|\(review)")
        UserDefaults.standard.set(reviews, forKey: reviewKey)
    }
}
