import SwiftUI
import MapKit

struct HomeView: View {
    
    @State private var cameraPosition: MapCameraPosition = .region(.init(
        center: .init(
            latitude: -33.883702711471514,
            longitude: 151.20016681156335),
        latitudinalMeters: 1300,
        longitudinalMeters: 1300
            )
    )

    @State private var route: MKRoute?
    @State private var selectedMarker: String?
    @State private var places: [Place] = []
    @State private var showOverlay: Bool = false
    @State private var selectedPlace: Place?
    @State private var shouldNavigate: Bool = false
    @State private var navigationCoordinate: CLLocationCoordinate2D?
    @State private var searchInput: String = ""
    @State private var showSearch: Bool = false
    
    private var filteredListofPlaces: [Place] {
        if !searchInput.isEmpty {
            return places.filter({ $0.name.lowercased().contains(searchInput.lowercased()) })
        }
        else {
            return []
        }
    }
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack {
                Map(position: $cameraPosition, selection: $selectedMarker) {
                    ForEach(places, id: \.id) { place in
                        Marker(place.name, systemImage: place.marker, coordinate: place.coordinate).tag(String(place.name))
                    }
                    
                    UserAnnotation()
                    
                    if let route {
                        MapPolyline(route.polyline).stroke(.blue, lineWidth: 4)
                    }
                    
                }
                .onAppear {
                    locationManager.requestWhenInUseAuthorization()
                    places = readPlacesCSV(filename: "placeList")
                    Task {
                        if let coordinate = await getUserLocation() {
                            cameraPosition = .region(.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
                        }
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
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .sheet(item: $selectedPlace, onDismiss: {
                    if shouldNavigate, let destination = navigationCoordinate {
                        getDirections(to: destination)
                    }
                    shouldNavigate = false
                    selectedMarker = nil
                    
                }) { place in
                    PlaceView(onNavigate: {
                        navigationCoordinate = place.coordinate
                        shouldNavigate = true
                    }, place: place, isFavourite: favouriteBinding(for: place))
                }
                
                VStack(spacing: 0) {
                    TextField("Search", text: $searchInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: geometry.size.width * 0.65)
                    
                    ScrollView {
                        VStack(spacing: 0){
                            ForEach(filteredListofPlaces.prefix(10), id: \.id) { place in
                                Text(place.name)
                                    .frame(width: geometry.size.width * 0.65)
                                    .background(.white)
                                    .onTapGesture {
                                        selectedMarker = place.name
                                        searchInput = ""
                                    }
                                }
                            }
                        }
                    }
                

                
                }
            
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
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    private func favouriteBinding(for place: Place) -> Binding<Bool> {
        Binding(
            get: {
                places.first(where: { $0.id == place.id })?.isFavourite ?? place.isFavourite
            },
            set: { newValue in
                if let index = places.firstIndex(where: { $0.id == place.id }) {
                    places[index].isFavourite = newValue
                }
                selectedPlace?.isFavourite = newValue
            }
        )
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

            guard columns.count >= 9,
                let latitude = Double(columns[1]),
                let longitude = Double(columns[2]),
                let rating = Double(columns[5])
            else {
                return nil
            }
            
            
            return Place(
                name: String(columns[0]), 
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), 
                marker: String(columns[3]),
                type: String(columns[4]),
                rating: rating,
                hasWifi: String(columns[6]).lowercased() == "true",
                hasOutlets: String(columns[7]).lowercased() == "true",
                noiseLevel: String(columns[8]))
        }
        
    }
}


#Preview {
    HomeView()
}

