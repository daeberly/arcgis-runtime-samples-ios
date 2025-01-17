// Copyright 2016 Esri.
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

import UIKit
import ArcGIS

class ManualCacheViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    var featureTable: AGSServiceFeatureTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ManualCacheViewController"]
        
        // initialize map with topographic basemap
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        
        // create feature table using a url
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0")!)
        // set the feature request mode to Manual Cache
        featureTable.featureRequestMode = AGSFeatureRequestMode.manualCache
        // create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        // add feature layer to the map
        map.operationalLayers.add(featureLayer)
        
        // assign map to the map view
        mapView.map = map
        mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -13630484, y: 4545415, spatialReference: .webMercator()), scale: 500000))
    }
    
    // MARK: - Actions
    
    @IBAction func populateAction(_ sender: AnyObject) {
        // set query parameters
        let params = AGSQueryParameters()
        // for specific request type
        params.whereClause = "req_Type = 'Tree Maintenance or Damage'"
        
        // populate features based on query
        self.featureTable.populateFromService(with: params, clearCache: true, outFields: ["*"]) { [weak self] (result: AGSFeatureQueryResult?, error: Error?) in
            // check for error
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                // the resulting features should be displayed on the map
                // you can print the count of features
                print("Populated \(result?.featureEnumerator().allObjects.count ?? 0) features.")
            }
        }
    }
}
