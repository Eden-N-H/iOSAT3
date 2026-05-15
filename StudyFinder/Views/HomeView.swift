import SwiftUI
import MapKit

struct HomeView: View {
    
    @State private var cameraPosition: MapCameraPosition = .region(.init(
        center: .init( //The camera defaults to this location and will be updated according to the users location if location services are enabled.
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
    
    private var filteredListOfPlaces: [Place] { // filteredListOfPlaces is used for the drop down beneath the search bar to filter the place array according to the current search input.
        if !searchInput.isEmpty {
            return places.filter({ $0.name.lowercased().contains(searchInput.lowercased()) })
        }
        else {
            return []
        }
    }
    
    let locationManager = CLLocationManager()
    
    var body: some View {
        TabView(selection: $selectedTab) { // Initialize tab view allowing the user to navigate freely between the map and favourites view.
            mapView.tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(0)
            
            FavouritesView(
                favouritePlaces: places.filter {$0.isFavourite},
                selectedPlace: $selectedPlace
            )
            .tabItem {
                Label("Favourites", systemImage: "heart.fill")
            }
            .tag(1)
        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            
            if places.isEmpty { // Read places, reviews and favourites from the respective CSV's and UserDefaults locations.
                places = readPlacesCSV(filename: "placeList")
                loadFavouritePlaces()
                reviewsByPlace = readReviews(filename: "placeReview")
            }
            
            Task { // Assign camera to user location if location services are enabled.
                if let coordinate = await getUserLocation() {
                    cameraPosition = .region(.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000))
                }
            }
        }
        .sheet(item: $selectedPlace, onDismiss: {
            
            if shouldNavigate, let destination = navigationCoordinate { // When 'Navigate' has been selected the destination is assigned, tabview defaults to the map and getDirections function is called.
                selectedTab = 0
                getDirections(to: destination)
            }
            
            shouldNavigate = false
            selectedMarker = nil
            
        }) { place in
            PlaceView(
                isFavourite: favouriteBinding(for: place),
                onNavigate: { // After onNavigate is passed from the place view -> shouldNavigate boolean becomes true and the navigation process is initiated (above)
                    navigationCoordinate = place.coordinate
                    shouldNavigate = true
                },
                onReviewSubmit: { // When a review is submitted readReviews is called again to refresh the review list in the UI.
                    reviewsByPlace = readReviews(filename: "placeReview")
                },
                place: place, reviews: reviewsByPlace[place.name] ?? [])
        }
        .alert("Location Services Disabled", isPresented: $noLocationError) { // Pop-up that appears if a noLocationError occurs (if the user attempts to use a navigation feature without location features enabled.
            
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            
            Button("Ignore", role: .cancel) {}
        }
        message: {
            Text("You have to enable location services to use navigation features.")
        }
    }
    
    private var mapView: some View {
        
        GeometryReader { geometry in // Geometry reader is used to access the screen dimensions to scale UI elements according to screen size.
            ZStack {
                Map(position: $cameraPosition, selection: $selectedMarker) {
                    ForEach(places, id: \.id) { place in // Adds place markers to the map.
                        Marker(place.name, systemImage: place.marker, coordinate: place.coordinate).tag(String(place.name))
                    }
                    
                    UserAnnotation() // Shows the user location on the map.
                    
                    if let route { // Draws navigation route.
                        MapPolyline(route.polyline).stroke(.blue, lineWidth: 4)
                    }
                }
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                    MapScaleView()
                }
                .onChange(of: selectedMarker ) { _, newValue in // If a marker is selected the respective place view overlay appears.
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
                        
                        VStack(spacing: 0) {
                            ForEach(filteredListOfPlaces.prefix(10), id: \.id) { place in // Lists filtered places beneath the search bar.
                                Text(place.name)
                                    .padding(8)
                                    .frame(width: geometry.size.width * 0.65)
                                    .background(selectedMarker == place.name ? Color.blue.opacity(0.1) : Color.clear)
                                    .onTapGesture {
                                        selectedMarker = place.name
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // A 1 second delay occurs before clearing the input giving the user time to see the blue-tint over the selected item in the list indicating it has been tapped.
                                            searchInput = ""
                                        }
                                    }
                            }
                        }
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
    
    func getUserLocation() async -> CLLocationCoordinate2D? { // Function to retrieve user location for navigation services.
        
        guard locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways // Checks location services permissions.
        else {
            return nil
        }
        
        let updates = CLLocationUpdate.liveUpdates()
        
        do { // Retrieves user location.
            let update = try await updates.first { $0.location?.coordinate != nil }
            return update?.location?.coordinate
        }
        catch {
            print("Cannot retrieve user location.")
            return nil
        }
    }
    
    func getDirections(to destination: CLLocationCoordinate2D) { // Function to get a valid route between the user location and the selected destination.
        Task {
            guard let userLocation = await getUserLocation() else { // Attempts to retrieve user location. Otherwise triggers 'noLocationError'.
                noLocationError = true
                return
            }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(location: .init(latitude: userLocation.latitude, longitude: userLocation.longitude), address: nil)
            request.destination = MKMapItem(location: .init(latitude: destination.latitude, longitude: destination.longitude), address: nil)
            request.transportType = .walking
            
            do {
                let directions = try await MKDirections(request: request).calculate() // Retrieves directions.
                route = directions.routes.first
                
                if let boundingRect = directions.routes.first?.polyline.boundingMapRect { // Changes the camera position to ensure both the users current location and the destination are visible on the map.
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
    
    private func favouriteBinding(for place: Place) -> Binding<Bool> { // Binding boolean that reads whether a place has been favourited and updates the favourite state accordingly.
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
    
    private func loadFavouritePlaces() { // Loads favourite places from UserDefaults
        let favouriteNames = Set(UserDefaults.standard.stringArray(forKey: favouritePlacesKey) ?? [])
        
        for index in places.indices {
            places[index].isFavourite = favouriteNames.contains(places[index].name)
        }
    }
    
    private func saveFavouritePlaces() { // Saves new Favourites to UserDefaults.
        let favouriteNames = places
            .filter { $0.isFavourite }
            .map { $0.name }
        
        UserDefaults.standard.set(favouriteNames, forKey: favouritePlacesKey)
    }
    
    func readPlacesCSV(filename: String) -> [Place] { // Reads places from CSV -> creates a new 'Place' struct instance and returns them in an array.
        guard let path = Bundle.main.path(forResource: filename, ofType: "csv"),
              let content = try? String(contentsOfFile: path, encoding: .utf8)
        else {
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
                noiseLevel: String(columns[8])
            )
        }
    }
    
    func readReviews(filename: String) -> [String: [String]] { // Retrieves reviews from CSV and UserDefaults. Example reviews are all stored within a CSV. New reviews that are created by the user are stored in UserDefaults (CSV mutation is not possible in this instance). If this app were to be published these reviews would be stored in a single centralized location.
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

