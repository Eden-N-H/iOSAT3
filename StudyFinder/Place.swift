//
//  Place.swift
//  StudyFinder
//
//  Created by Eden Hallett on 12/5/2026.
//
import Foundation
import MapKit

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let marker: String
}
