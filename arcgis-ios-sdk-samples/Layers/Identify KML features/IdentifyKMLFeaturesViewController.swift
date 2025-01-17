//
// Copyright © 2018 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Identify KML features
/// sample.
class IdentifyKMLFeaturesViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let map = AGSMap(basemapStyle: .arcGISDarkGrayBase)
            map.operationalLayers.add(forecastLayer)
            mapView.map = map
            let center = AGSPoint(x: -48_885, y: 1_718_235, spatialReference: AGSSpatialReference(wkid: 5070))
            mapView.setViewpointCenter(center, scale: 50_000_000)
        }
    }
    
    // MARK: Instance properties
    
    /// A KML layer with forecast data.
    let forecastLayer: AGSKMLLayer = {
        let url = URL(string: "https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx_latest.kml")!
        let dataset = AGSKMLDataset(url: url)
        return AGSKMLLayer(kmlDataset: dataset)
    }()
    
    // MARK: Methods
    
    /// Show a callout for the ballon content of the placemark.
    func showCallout(for placemark: AGSKMLPlacemark, at point: AGSPoint) {
        guard let data = placemark.balloonContent.data(using: .utf8) else { return }
        do {
            let attributedText = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            let textView = UITextView()
            textView.attributedText = attributedText
            textView.backgroundColor = placemark.balloonBackgroundColor
            textView.isEditable = false
            textView.isScrollEnabled = false
            mapView.callout.customView = textView
            mapView.callout.show(at: point, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
        } catch {
            presentAlert(error: error)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["IdentifyKMLFeaturesViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension IdentifyKMLFeaturesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        geoView.callout.dismiss()
        geoView.identifyLayer(forecastLayer, screenPoint: screenPoint, tolerance: 15, returnPopupsOnly: false) { [weak self] (result) in
            if let placemark = result.geoElements.first as? AGSKMLPlacemark {
                // Google Earth only displays the placemarks with description
                // or extended data. To match its behavior, add a description
                // placeholder if it is empty in the data source.
                if placemark.nodeDescription.isEmpty {
                    placemark.nodeDescription = "Weather condition"
                }
                self?.showCallout(for: placemark, at: mapPoint)
            } else if let error = result.error {
                self?.presentAlert(error: error)
            }
        }
    }
}
