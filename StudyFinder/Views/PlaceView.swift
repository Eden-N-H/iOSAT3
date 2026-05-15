import SwiftUI

struct PlaceView: View {
    
    @State private var showReviewOverlay: Bool = false
    
    @Environment(\.dismiss) private var dismiss
    @Binding var isFavourite: Bool
    var onNavigate: () -> Void
    var onReviewSubmit: () -> Void
    
    let place: Place
    let reviews: [String]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.25), Color.green.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
                    
                    VStack(alignment: .leading) {
                        HStack {
                            
                            Text("Rating: ").padding(8)
                            
                            ForEach (1...5, id: \.self) { number in // Star display that reflects the rounded place rating. Drawn using filled and unfilled SF Symbols.
                                if number <= Int(place.rating.rounded()) {
                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                }
                                else {
                                    Image(systemName: "star").foregroundStyle(.yellow)
                                }
                            }
                            Text("\(place.rating, specifier: "%g")").foregroundStyle(.yellow).bold()
                        }
                        
                        Text("Wifi: \(place.hasWifi ? "Yes" : "No")").padding(8)
                        Text("Outlets: \(place.hasOutlets ? "Yes" : "No")").padding(8)
                        Text("Noise Level: \(place.noiseLevel)").padding(8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviews")
                            .font(.headline)
                        
                        if reviews.isEmpty {
                            Text("No reviews yet.")
                                .foregroundStyle(.secondary)
                        }
                        else {
                            ScrollView {
                                ForEach(reviews, id: \.self) { review in
                                    
                                    let segment = review.split(separator: "|", maxSplits: 1)
                                    let starRating = Int(segment.first ?? "0") ?? 0
                                    let reviewText = segment.last ?? "No review"
                                    
                                    VStack(alignment: .leading) {
                                        HStack {
                                            ForEach (1...5, id: \.self) { number in
                                                if number <= starRating {
                                                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                                                }
                                                else {
                                                    Image(systemName: "star").foregroundStyle(.yellow)
                                                }
                                                
                                            }
                                        }
                                        Text(reviewText)
                                            .padding(8)
                                    }
                                    .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .frame(height: geometry.size.height * 0.3)
                            .padding(8)
                            .scrollDismissesKeyboard(.never)
                            .simultaneousGesture(DragGesture())
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                        }
                    }
                    
                    Button("Navigate") {
                        onNavigate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    
                    Button("Review"){
                        showReviewOverlay = true
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .sheet(isPresented: $showReviewOverlay, onDismiss: { onReviewSubmit()}) {
                        ReviewView(place: place)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.75))
                .cornerRadius(20)
                .shadow(radius: 8)
                .padding(.horizontal)
            }
        }
    }
}
