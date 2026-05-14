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
    @State private var reviewsByPlace: [String: [String]] = [:]
    @State private var showOverlay: Bool = false
    @State private var selectedPlace: Place?
    @State private var shouldNavigate: Bool = false
    @State private var navigationCoordinate: CLLocationCoordinate2D?
    @State private var searchInput: String = ""
    @State private var showSearch: Bool = false
    @State private var selectedTab: Int = 0
    @State private var noLocationError: Bool = false
    
    private var favouritePlacesKey: String {
        let username = UserDefaults.standard.string(forKey: "savedUsername") ?? "default"
        return "favouritePlaces.\(username)"
    }
    
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
        TabView(selection: $selectedTab) {
            mapView
                .tabItem {
                    Label("Map", systemImage: "map")
                }.tag(0)
            
            FavouritesView(
                favouritePlaces: places.filter { $0.isFavourite },
                selectedPlace: $selectedPlace
            )
            .tabItem {
                Label("Favourites", systemImage: "heart.fill")
            }.tag(1)
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            
            if places.isEmpty {
                places = readPlacesCSV(filename: "placeList")
                loadFavouritePlaces()
                reviewsByPlace = readReviewsCSV(filename: "placeReview")
            }
            
            Task {
                if let coordinate = await getUserLocation() {
                    cameraPosition = .region(.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
                }
            }
        }
        .sheet(item: $selectedPlace, onDismiss: {
            if shouldNavigate, let destination = navigationCoordinate {
                selectedTab = 0
                getDirections(to: destination)
            }
            shouldNavigate = false
            selectedMarker = nil
        }) { place in
            PlaceView(
                isFavourite: favouriteBinding(for: place), onNavigate: {
                navigationCoordinate = place.coordinate
                shouldNavigate = true
            }, onReviewSubmit: {
                reviewsByPlace = readReviewsCSV(filename: "placeReview")
            },
                
                place: place, reviews: reviewsByPlace[place.name] ?? [])
        }
        .alert("Location Services Disabled", isPresented: $noLocationError) {
            
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
            }
            
            Button("Ignore", role: .cancel) {
            }
        }message: {
            Text("You have to enable location services to use navigation features.")
        }
    }
    
    private var mapView: some View {
        
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
                VStack {
                    VStack(spacing: 0) {
                        TextField("Search", text: $searchInput)
                            .frame(width: geometry.size.width * 0.6)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)
                            
                        
                        
                            VStack(spacing: 0){
                                ForEach(filteredListofPlaces.prefix(10), id: \.id) { place in
                                    Text(place.name)
                                        .padding(8)
                                        .frame(width: geometry.size.width * 0.65)
                                        .background(selectedMarker == place.name ? Color.blue.opacity(0.1) : Color.clear)
                                        .onTapGesture {
                                            selectedMarker = place.name
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                                searchInput = ""
                                            }
                                            
                                        }
                                    
                                }
                                
                                }
                            
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        
                }
                
                    Spacer()
                    
                }.padding(.top, 8)
                

                
                }
            
        }
    }
    
    func getUserLocation() async -> CLLocationCoordinate2D? {
        
        guard locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways else {
            return nil
        }
        
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
            guard let userLocation = await getUserLocation() else {
                noLocationError = true
                return
            }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(location: .init(latitude: userLocation.latitude, longitude: userLocation.longitude), address: nil)
            request.destination = MKMapItem(location: .init(latitude: destination.latitude, longitude: destination.longitude), address: nil)
            request.transportType = .walking
            
            do {
                let directions = try await MKDirections(request: request).calculate()
                route = directions.routes.first
                
                if let boundingRect = directions.routes.first?.polyline.boundingMapRect {
                    cameraPosition = .rect(
                        MKMapRect(
                            x: boundingRect.origin.x - boundingRect.size.width * 0.3,
                            y: boundingRect.origin.y - boundingRect.size.height * 0.3,
                            width: boundingRect.size.width * 1.6,
                            height: boundingRect.size.height * 1.6)
                        )
                }
                
                
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
                saveFavouritePlaces()
            }
        )
    }

    private func loadFavouritePlaces() {
        let favouriteNames = Set(UserDefaults.standard.stringArray(forKey: favouritePlacesKey) ?? [])
        
        for index in places.indices {
            places[index].isFavourite = favouriteNames.contains(places[index].name)
        }
    }

    private func saveFavouritePlaces() {
        let favouriteNames = places
            .filter { $0.isFavourite }
            .map { $0.name }
        
        UserDefaults.standard.set(favouriteNames, forKey: favouritePlacesKey)
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

    func readReviewsCSV(filename: String) -> [String: [String]] {
        guard let path = Bundle.main.path(forResource: filename, ofType: "csv"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                return [:]
            }
        
        let rows = content.components(separatedBy: .newlines)
            .dropFirst()
        
        var reviewsByPlace: [String: [String]] = [:]
        
        for row in rows {
            let columns = row.split(separator: ",", maxSplits: 1)
            
            guard columns.count == 2 else {
                continue
            }
            
            let placeName = String(columns[0]).trimmingCharacters(in: .whitespacesAndNewlines)
            let review = String(columns[1]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !placeName.isEmpty && !review.isEmpty {
                reviewsByPlace[placeName, default: []].append(review)
            }
        }
        
        for place in places {
            let reviewKey = "reviews.\(place.name)"
            let reviews = UserDefaults.standard.stringArray(forKey: reviewKey) ?? []
            if !reviews.isEmpty {
                let existingReviews = reviewsByPlace[place.name] ?? []
                reviewsByPlace[place.name] = existingReviews + reviews
            
        }
        }
        return reviewsByPlace
    }
}


#Preview {
    HomeView()
}

