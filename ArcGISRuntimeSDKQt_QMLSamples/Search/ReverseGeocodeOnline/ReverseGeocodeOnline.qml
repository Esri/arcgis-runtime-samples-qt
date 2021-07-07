// [WriteFile Name=ReverseGeocodeOnline, Category=Search]
// [Legal]
// Copyright 2020 Esri.

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
import QtQuick.Controls 2.6
import Esri.ArcGISExtras 1.1
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property Point clickedPoint: null

    MapView {
        id: mapView
        anchors.fill: parent

        Callout {
            id: callout
            calloutData: parent.calloutData
            accessoryButtonHidden: true
            leaderPosition: leaderPositionEnum.Top
            padding: 5
        }
        onMouseClicked: {
            clickedPoint = mapView.screenToLocation(mouse.x, mouse.y);
            mapView.identifyGraphicsOverlayWithMaxResults(graphicsOverlay, mouse.x, mouse.y, 5, false, 1);
        }

        onIdentifyGraphicsOverlayStatusChanged: {
            if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted) {
                if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress) {
                    locatorTask.reverseGeocodeWithParameters(clickedPoint, reverseGeocodeParameters);
                }
            }
        }

        Map {
            Basemap {
                initStyle: Enums.BasemapStyleArcGISImagery
            }

            ViewpointCenter {
                Point {
                    x: -13042254.715252
                    y: 3857970.236806
                    SpatialReference {
                        wkid: 3857
                    }
                }
                targetScale: 30000
            }
        }

        GraphicsOverlay {
            id: graphicsOverlay

            Graphic {
                id: pointGraphic
                PictureMarkerSymbol {
                    url: "qrc:/Samples/Search/ReverseGeocodeOnline/pin_circle_red.png"
                    height: 40
                    width: 40
                    offsetY: height/2
                }
            }
        }

        ReverseGeocodeParameters {
            id: reverseGeocodeParameters
            outputSpatialReference: mapView.spatialReference
        }

        LocatorTask {
            id: locatorTask
            
            // An ArcGIS Developer API key is required to utilize the world geocoding service
            url: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer"

            onGeocodeStatusChanged: {
                if (geocodeStatus === Enums.TaskStatusCompleted) {
                    if (geocodeResults.length > 0) {
                        const address = geocodeResults[0].label;
                        const splitIndex = address.indexOf(",");
                        mapView.setViewpointCenter(geocodeResults[0].displayLocation);
                        mapView.calloutData.location = clickedPoint;
                        mapView.calloutData.title = address.substring(0, splitIndex < 0 ? undefined: splitIndex).trim();
                        mapView.calloutData.detail = address.substring(splitIndex + 1).trim();
                        callout.showCallout();
                        pointGraphic.geometry = clickedPoint;
                    }
                }
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        visible: true
        running: locatorTask.geocodeStatus === Enums.TaskStatusInProgress
    }
}
