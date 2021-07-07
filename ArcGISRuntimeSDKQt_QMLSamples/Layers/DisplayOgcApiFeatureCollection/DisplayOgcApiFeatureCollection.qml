// [WriteFile Name=DisplayOgcApiFeatureCollection, Category=Layers]
// [Legal]
// Copyright 2021 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// [Legal]

import QtQuick 2.6
import Esri.ArcGISRuntime 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    MapView {
        id: mapView
        anchors.fill: parent

        Map {
            initBasemapStyle: Enums.BasemapStyleArcGISTopographic

            FeatureLayer {
                OgcFeatureCollectionTable {
                    id: ogcFeatureCollectionTable
                    url: "https://demo.ldproxy.net/daraa"
                    collectionId: "TransportationGroundCrv"

                    // Enums.FeatureRequestModeManualCache specifies that features from the server will be stored locally for display and querying
                    // In this mode, ServiceFeatureTable::populateFromService() must be called to populate the local cache
                    featureRequestMode: Enums.FeatureRequestModeManualCache

                    onLoadStatusChanged: {
                        // ogcFeatureCollectionTable.load() will be automatically called when added to a FeatureLayer
                        // populateFromService() will be called with the initial viewpoint extent
                        if (ogcFeatureCollectionTable.loadStatus === Enums.LoadStatusLoaded) {
                            ogcFeatureCollectionTable.populateFromService(queryParameters, false, []);
                        }
                    }
                }

                renderer: SimpleRenderer {
                    SimpleLineSymbol {
                        style: Enums.SimpleLineSymbolStyleSolid
                        color: "blue"
                        width: 3
                    }
                }
            }

            ViewpointCenter {
                targetScale: 20000
                center: Point {
                    x: 36.10
                    y: 32.62
                    spatialReference: SpatialReference{ wkid: 4326 }
                }
            }
        }

        QueryParameters {
            id: queryParameters
            // Set the query area to what is currently visible in the map view
            geometry: mapView.currentViewpointExtent.extent
            // Enums.SpatialRelationshipIntersects will return all features that are within and crossing the perimiter of the input geometry
            spatialRelationship: Enums.SpatialRelationshipIntersects
            // Some services have low default values for max features returned
            maxFeatures: 5000
        }

        onNavigatingChanged: {
            if (mapView.navigating)
                return;

            // Populate the feature collection table with features that match the parameters, cache them locally, and store all table fields
            ogcFeatureCollectionTable.populateFromService(queryParameters, false, []);
        }
    }
}
