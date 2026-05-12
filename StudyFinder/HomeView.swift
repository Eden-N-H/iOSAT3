import SwiftUI
import MapKit

struct HomeView: View {
    
    let cameraPosition: MapCameraPosition = .region(.init(center: .init(latitude: -33.883702711471514, longitude: 151.20016681156335), latitudinalMeters: 1300, longitudinalMeters: 1300))
    //make it a state variable for a dynamic map
    
    @State private var route: MKRoute?
    @State private var selectedMarker: String?
    @State private var places: [Place] = []
    @State private var showOverlay: Bool = false
    @State private var selectedPlace: Place?
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        Map(initialPosition: cameraPosition, selection: $selectedMarker) {
            ForEach(places, id: \.id) { place in
                Marker(place.name, systemImage: place.marker, coordinate: place.coordinate).tag(String(place.name))
            }
            
            if let route {
                MapPolyline(route.polyline).stroke(.blue, lineWidth: 4)
            }
            
        }
        .onAppear {
            DispatchQueue.main.async {
                locationManager.requestWhenInUseAuthorization()
                places = readPlacesCSV(filename: "placeList")
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapPitchToggle()
            MapScaleView()
        }
        .onChange(of: selectedMarker ) { _, newValue in
            
            if let place = places.first(where: { $0.name == newValue }) {
                selectedPlace = place
                showOverlay = true
                //getDirections(to: place.coordinate)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .sheet(item: $selectedPlace, onDismiss: { selectedMarker = nil}) { place in
            PlaceView(place: place)
        }
        
    }
    
    func getUserLocation() async -> CLLocationCoordinate2D? {
        let updates = CLLocationUpdate.liveUpdates()
        
        do {
            let update = try await updates.first { $0.location?.coordinate != nil }
            return update?.location?.coordinate
        }
        catch {
            print("Cannot retrieve user location.")
            return nil
        }
    }
    
    func getDirections(to destination: CLLocationCoordinate2D) {
        Task {
            guard let userLocation = await getUserLocation() else { return }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(location: .init(latitude: userLocation.latitude, longitude: userLocation.longitude), address: nil)
            request.destination = MKMapItem(location: .init(latitude: destination.latitude, longitude: destination.longitude), address: nil)
            request.transportType = .walking
            
            do {
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first
            }
            catch {
                print("Error")
            }
        }
    }
    
    func readPlacesCSV(filename: String) -> [Place] {
        guard let path = Bundle.main.path(forResource: filename, ofType: "csv"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                return []
            }
        
        let rows = content.components(separatedBy: .newlines)
            .dropFirst()
        
        return rows.compactMap { row in
            let columns = row
                .split(separator: ",")

            guard columns.count >= 4,
                let latitude = Double(columns[1]),
                let longitude = Double(columns[2])
            else {
                return nil
            }
            
            
            return Place(name: String(columns[0]), coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), marker: String(columns[3]))
        }
        
    }
}


#Preview {
    HomeView()
}
