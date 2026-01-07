//
// LocationPickerView.swift
// IosDam
//
// Interactive map for picking stadium location

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct LocationPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    
    @State private var region: MKCoordinateRegion
    @State private var searchText = ""
    @State private var isSearching = false
    
    // Add LocationManager
    @StateObject private var locationManager = LocationManager()
    
    init(selectedCoordinate: Binding<CLLocationCoordinate2D?>, locationName: Binding<String>) {
        self._selectedCoordinate = selectedCoordinate
        self._locationName = locationName
        
        // Initialize region with selected coordinate or default to Tunis
        if let coord = selectedCoordinate.wrappedValue {
            _region = State(initialValue: MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            // Default region (will be updated by user location)
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, annotationItems: selectedCoordinate != nil ? [MapPin(coordinate: selectedCoordinate!)] : []) { pin in
                    MapAnnotation(coordinate: pin.coordinate) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    let coordinate = region.center
                    selectedCoordinate = coordinate
                    reverseGeocode(coordinate: coordinate)
                }
                .onAppear {
                    // Request location when view appears
                    locationManager.requestLocation()
                }
                .onChange(of: locationManager.userLocation) { newLocation in
                    // Only center on user location if no location is already selected
                    if let location = newLocation, selectedCoordinate == nil {
                        withAnimation {
                            region = MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        }
                    }
                }
                
                // Center crosshair when no location is selected
                if selectedCoordinate == nil {
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.red)
                }
                
                // Current Location Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            if let location = locationManager.userLocation {
                                withAnimation {
                                    region = MKCoordinateRegion(
                                        center: location,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                }
                            } else {
                                locationManager.requestLocation()
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 140) // Above the instructions
                    }
                }
                
                // Search bar
                VStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search location...", text: $searchText, onCommit: {
                            searchLocation()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding()
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 8) {
                        if selectedCoordinate == nil {
                            Text("Tap on the map to select a location")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        } else {
                            VStack(spacing: 4) {
                                Text("📍 Location Selected")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                if !locationName.isEmpty {
                                    Text(locationName)
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(8)
                            .background(Color.green.opacity(0.9))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitle("Pick Location", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(selectedCoordinate == nil)
            )
        }
    }
    
    // MARK: - Search Location
    
    func searchLocation() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        searchRequest.region = region
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            isSearching = false
            
            guard let response = response, let firstItem = response.mapItems.first else {
                return
            }
            
            let coordinate = firstItem.placemark.coordinate
            selectedCoordinate = coordinate
            locationName = firstItem.name ?? firstItem.placemark.title ?? searchText
            
            // Update region to show selected location
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - Reverse Geocode
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                var addressComponents: [String] = []
                
                if let name = placemark.name {
                    addressComponents.append(name)
                }
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                if let country = placemark.country {
                    addressComponents.append(country)
                }
                
                locationName = addressComponents.joined(separator: ", ")
            } else {
                locationName = "Selected Location"
            }
        }
    }
}

// MARK: - Map Pin Model

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Location Manager

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationStatus: CLAuthorizationStatus?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        // Optionally stop updating to save battery, but keeping it allows tracking
        // locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
