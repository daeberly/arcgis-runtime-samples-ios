// Copyright 2019 Esri.
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

class GroupLayersViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView!
    @IBOutlet var layersBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GroupLayersViewController", "LayersTableViewController", "GroupLayersSectionView"]
        
        // Assign scene to the scene view.
        sceneView.scene = makeScene()
        // Add the group layers to the scene as operational layers.
        sceneView.scene?.operationalLayers.addObjects(from: [makeProjectAreaGroupLayer(), makeBuildingsGroupLayer()])
        zoomToGroupLayer()
    }
    
    /// Zooms to the extent of the Group Layer when its child layers are loaded.
    func zoomToGroupLayer() {
        guard let groupLayer = (sceneView.scene?.operationalLayers as! [AGSLayer]).first(where: { $0.name == "Project area group" }) as? AGSGroupLayer else {
            return
        }
        
        guard let childLayers = groupLayer.layers as? [AGSLayer] else { return }
        
        AGSLoadObjects(childLayers) { [weak self] (success) in
            guard success else {
                print("Error loading layers")
                return
            }
            if let extent = groupLayer.fullExtent {
                let camera = AGSCamera(lookAt: extent.center, distance: 700, heading: 0, pitch: 60, roll: 0)
                
                // Zoom to the viewpoint specified by the camera position.
                self?.sceneView.setViewpointCamera(camera) { (_) in
                    DispatchQueue.main.async {
                        // Enable the bar button item to display
                        // The table of contents of operational layers.
                        self?.layersBarButtonItem.isEnabled = true
                    }
                }
            }
        }
    }
    
    /// Returns the project area group layer
    func makeProjectAreaGroupLayer() -> AGSGroupLayer {
        // Create a group layer and set its name.
        let groupLayer = AGSGroupLayer()
        groupLayer.name = "Project area group"
        // Create a layer for the trees.
        let trees = AGSArcGISSceneLayer(url: URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_Trees/SceneServer")!)
        // Create a layer for the pathways.
        let pathwaysTable = AGSServiceFeatureTable(url: URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_Pathways/FeatureServer/1")!)
        let pathways = AGSFeatureLayer(featureTable: pathwaysTable)
        pathways.sceneProperties?.altitudeOffset = 1
        pathways.sceneProperties?.surfacePlacement = .relative
        // Create a layer for the project area.
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevelopmentProjectArea/FeatureServer/0")!)
        let projectArea = AGSFeatureLayer(featureTable: featureTable)
        // Add the scene layers and feature layer as children of the group layer.
        groupLayer.layers.addObjects(from: [trees, pathways, projectArea])
        return groupLayer
    }
    
    /// Returns the buildings group layer.
    func makeBuildingsGroupLayer() -> AGSGroupLayer {
        // Create a group layer and set its name.
        let groupLayer = AGSGroupLayer()
        groupLayer.name = "Buildings group"
        
        //Create layers for the buildings.
        let buildingsA = AGSArcGISSceneLayer(url: URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/DevA_BuildingShells/SceneServer")!)
        let buildingsB = AGSArcGISSceneLayer(url: URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/DevB_BuildingShells/SceneServer")!)
        
        // Add the scene layers and feature layer as children of the group layer.
        groupLayer.layers.addObjects(from: [buildingsA, buildingsB])
        // Set the visibility mode to exclusive.
        groupLayer.visibilityMode = .exclusive
        return groupLayer
    }
    
    /// Returns a scene with imagery basemap and elevation data.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemap: .imagery())
        
        // Add base surface to the scene for elevation data.
        let surface = AGSSurface()
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        return scene
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LayersPopover" {
            guard let controller = segue.destination as? LayersTableViewController else { return }
            
            let operationalLayers = sceneView.scene?.operationalLayers as! [AGSLayer]
            controller.layers.append(contentsOf: operationalLayers)
            
            // Popover presentation logic.
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 180)
        }
    }
}

extension GroupLayersViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation.
        return .none
    }
}
