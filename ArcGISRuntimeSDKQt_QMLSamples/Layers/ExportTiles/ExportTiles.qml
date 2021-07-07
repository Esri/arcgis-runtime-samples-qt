// [WriteFile Name=ExportTiles, Category=Layers]
// [Legal]
// Copyright 2016 Esri.

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
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISExtras 1.1

Rectangle {
    width: 800
    height: 600
    
    readonly property url outputTileCache: System.temporaryFolder.url + "/TileCacheQml_%1.tpkx".arg(new Date().getTime().toString())
    property Envelope tileCacheExtent: null
    property string statusText: ""
    property ExportTileCacheParameters params
    property var exportTileCacheProgress: 0

    // Create MapView that contains a Map
    MapView {
        id: mapView
        anchors.fill: parent
        Map {
            id: map
            // Add an imagery basemap to the map and get the url of the raster baselayer once it has loaded
            Basemap {
                initStyle: Enums.BasemapStyleArcGISImagery

                onLoadStatusChanged: {
                    if (loadStatus !== Enums.LoadStatusLoaded)
                        return;

                    exportTask.url = baseLayers.get(0).url;
                }
            }

            initialViewpoint: ViewpointCenter {
                center: Point {
                    x: -117
                    y: 35
                    spatialReference: SpatialReference { wkid: 4326 }
                }
                targetScale: 1e7
            }
        }
    }

    // Create ExportTileCacheTask
    //! [ExportTiles ExportTileCacheTask]

    ExportTileCacheTask {
        id: exportTask
        property var exportJob

        onCreateDefaultExportTileCacheParametersStatusChanged: {
            if (createDefaultExportTileCacheParametersStatus === Enums.TaskStatusCompleted) {
                params = defaultExportTileCacheParameters;

                // export the cache with the parameters
                executeExportTileCacheTask(params);
            }
        }

        function generateDefaultParameters() {
            // generate the default parameters with the extent and map scales specified
            exportTask.createDefaultExportTileCacheParameters(tileCacheExtent, mapView.mapScale, mapView.mapScale/10);
        }

        function executeExportTileCacheTask(params) {
            // execute the asynchronous task and obtain the job
            exportJob = exportTask.exportTileCache(params, outputTileCache);

            // check if job is valid
            if (exportJob) {
                // show the export window
                exportWindow.visible = true;

                // connect to the job's status changed signal to know once it is done
                exportJob.jobStatusChanged.connect(updateJobStatus);
                exportJob.progressChanged.connect(updateExportProgress);

                exportJob.start();
            } else {
                exportWindow.visible = true;
                statusText = "Export failed";
                exportWindow.hideWindow(5000);
            }
        }

        function updateJobStatus() {
            switch(exportJob.jobStatus) {
            case Enums.JobStatusFailed:
                statusText = "Export failed";
                exportWindow.hideWindow(5000);
                break;
            case Enums.JobStatusNotStarted:
                statusText = "Job not started";
                break;
            case Enums.JobStatusPaused:
                statusText = "Job paused";
                break;
            case Enums.JobStatusStarted:
                statusText = "In progress...";
                break;
            case Enums.JobStatusSucceeded:
                statusText = "Adding TPKX...";
                exportWindow.hideWindow(1500);
                displayOutputTileCache(exportJob.result);
                break;
            default:
                break;
            }
        }

        function updateExportProgress() {
            exportTileCacheProgress = exportJob.progress;
        }

        function displayOutputTileCache(tileCache) {
            // create a new tiled layer from the output tile cache
            const tiledLayer = ArcGISRuntimeEnvironment.createObject("ArcGISTiledLayer", { tileCache: tileCache } );

            // create a new basemap with the tiled layer
            const basemap = ArcGISRuntimeEnvironment.createObject("Basemap");
            basemap.baseLayers.append(tiledLayer);

            // set the new basemap on the map
            map.basemap = basemap;

            // zoom to the new layer and hide window once loaded
            tiledLayer.loadStatusChanged.connect(()=> {
                 if (tiledLayer.loadStatus === Enums.LoadStatusLoaded) {
                     extentRectangle.visible = false;
                     downloadButton.visible = false;

                     const prevMapScale = mapView.mapScale;
                     mapView.setViewpointScale(prevMapScale * .5);
                     map.minScale = prevMapScale;
                     map.maxScale = prevMapScale / 10;
                 }
             });
        }

        Component.onDestruction: {
            if (exportJob) {
                exportJob.jobStatusChanged.disconnect(updateJobStatus);
                exportJob.progressChanged.disconnect(updateExportProgress);
            }
        }
    }
    //! [ExportTiles ExportTileCacheTask]

    Rectangle {
        id: extentRectangle
        anchors.centerIn: parent
        width: parent.width - (50)
        height: parent.height - (125)
        color: "transparent"
        border {
            color: "red"
            width: 3
        }
    }

    // Create the download button to export the tile cache
    Rectangle {
        id: downloadButton
        property bool pressed: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 23
        }

        width: 130
        height: 35
        color: pressed ? "#959595" : "#D6D6D6"
        radius: 5
        border {
            color: "#585858"
            width: 1
        }

        Row {
            anchors.fill: parent
            spacing: 5
            Image {
                width: 38
                height: width
                source: "qrc:/Samples/Layers/ExportTiles/download.png"
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Export tiles"
                font.pixelSize: 14
                color: "#474747"
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: downloadButton.pressed = true
            onReleased: downloadButton.pressed = false
            onClicked: {
                getRectangleEnvelope();
            }

            function getRectangleEnvelope() {
                const corner1 = mapView.screenToLocation(extentRectangle.x, extentRectangle.y);
                const corner2 = mapView.screenToLocation((extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                const envBuilder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder");
                envBuilder.setCorners(corner1, corner2);
                tileCacheExtent = GeometryEngine.project(envBuilder.geometry, Factory.SpatialReference.createWebMercator());
                exportTask.generateDefaultParameters();
            }
        }
    }

    // Create a window to display the export window
    Rectangle {
        id: exportWindow
        anchors.fill: parent
        color: "transparent"
        visible: false
        clip: true

        RadialGradient {
            anchors.fill: parent
            opacity: 0.7
            gradient: Gradient {
                GradientStop { position: 0.0; color: "lightgrey" }
                GradientStop { position: 0.7; color: "black" }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
            onWheel: wheel.accepted = true
        }

        Rectangle {
            anchors.centerIn: parent
            width: 140
            height: 145
            color: "lightgrey"
            opacity: 0.8
            radius: 5
            border {
                color: "#4D4D4D"
                width: 1
            }

            Column {
                anchors {
                    fill: parent
                    margins: 10
                }
                spacing: 10

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: statusText
                    font.pixelSize: 16
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: exportTileCacheProgress + "% Completed"
                    font.pixelSize: 16
                }
            }
        }

        Timer {
            id: hideWindowTimer
            onTriggered: exportWindow.visible = false;
        }

        function hideWindow(time) {
            hideWindowTimer.interval = time;
            hideWindowTimer.restart();
        }
    }
}
