// [WriteFile Name=CreateTerrainSurfaceFromLocalTilePackage, Category=Scenes]
// [Legal]
// Copyright 2019 Esri.

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
import Esri.ArcGISExtras 1.1

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    readonly property string montereyTpkElevationPath: System.userHomePath + "/ArcGIS/Runtime/Data/tpkx/MontereyElevation.tpkx"

    SceneView {
        id: sceneView
        anchors.fill: parent

        Scene {
            id: scene
            Basemap {
                initStyle: Enums.BasemapStyleArcGISImageryStandard
            }

            Surface {
                ArcGISTiledElevationSource {
                    url: montereyTpkElevationPath
                    //Hook up success/error reporting for the Elevation Source load
                    onLoadStatusChanged: reportLoadStatus(loadStatus, loadError)
                }
            }
        }

        // Once the scene view has loaded, apply the camera.
        Component.onCompleted: {
            setViewpointCameraAndWait(camera);
        }
    }

    function reportLoadStatus(loadStatus, loadError) {
        if (loadStatus === Enums.LoadStatusLoaded) {
            console.info("Loaded tiled elevation source succesfully")
        }
        else if (loadStatus === Enums.LoadStatusFailedToLoad) {
            console.warn("Error loading elevation source : ", loadError.message, loadError.additionalMessage)
        }
    }

    // Create the camera to be used as the scene view's viewpoint, looking at Monterey, California..
    Camera {
        id: camera
        location: Point {
            x: -121.80 // Longitude
            y: 36.51 // Latitude
            z: 300.0 // Altiude
            spatialReference: SpatialReference { wkid: 4326 }
        }
        heading: 10.0
        pitch: 70.0
        roll: 0.0
    }
}
