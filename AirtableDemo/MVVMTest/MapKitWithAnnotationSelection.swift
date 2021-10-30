//
//  MapKitWithAnnotatioNSelection.swift
//  MapKitWithAnnotatioNSelection
//
//  Created by Admin on 05/09/2021.
//

import SwiftUI
import MapKit


struct MapKitWithAnnotationSelection: View {
    let locations: [MKAnnotation] = (1...4).map {_ in MyAnnotation()}
    @State private var selectedLocation: MKAnnotation?
    var body: some View {
        VStack {
            Text("\(selectedLocation?.coordinate.latitude ?? 0)")
            MapView(selectedLocation: $selectedLocation, annotations: locations)
        }
    }
}

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    override init() {
        self.coordinate = CLLocationCoordinate2D(latitude: Double.random(in: 48...49), longitude: Double.random(in: 2...3))
    }
    
}


struct MapView: UIViewRepresentable {
    
    @Binding var selectedLocation: MKAnnotation?
    let annotations: [MKAnnotation]
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 48.862725, longitude: 2.287592), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
        mapView.addAnnotations(annotations)
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is MKPointAnnotation else { return nil }

            let identifier = "Annotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
            } else {
                annotationView!.annotation = annotation
            }

            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            parent.selectedLocation = view.annotation
        }
    }
}

struct MapKitWithAnnotatioNSelection_Previews: PreviewProvider {
    static var previews: some View {
        MapKitWithAnnotationSelection()
    }
}
