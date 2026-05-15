import Foundation
import MapKit

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let marker: String
    
    let type: String
    let rating: Double
    let hasWifi: Bool
    let hasOutlets: Bool
    let noiseLevel: String
    var isFavourite: Bool = false
}
