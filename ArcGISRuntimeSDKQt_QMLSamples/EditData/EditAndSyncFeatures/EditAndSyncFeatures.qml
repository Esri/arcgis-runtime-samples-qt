// [WriteFile Name=EditAndSyncFeatures, Category=EditData]
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
    
    readonly property url dataPath: System.userHomePath + "/ArcGIS/Runtime/Data/"
    readonly property url outputGdb: System.temporaryFolder.url + "/WildfireQml_%1.geodatabase".arg(new Date().getTime().toString())
    readonly property string featureServiceUrl: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Sync/WildfireSync/FeatureServer"
    property Envelope generateExtent: null
    property string statusText: ""
    property string featureLayerId: "0"
    property string instructionText: ""
    property bool isOffline: false
    property var selectedFeature: null
    property Geodatabase offlineGdb: null

    MapView {
        id: mapView
        anchors.fill: parent

        Map {
            id: map

            Basemap {
                ArcGISTiledLayer {
                    TileCache {
                        path: dataPath + "tpkx/SanFrancisco.tpkx"
                    }
                }
            }

            FeatureLayer {
                ServiceFeatureTable {
                    url: featureServiceUrl + "/" + featureLayerId
                }
            }

            // set an initial viewpoint
            ViewpointExtent {
                Envelope {
                    xMax: -122.43843016064368
                    xMin: -122.50017717584528
                    yMax: 37.81638388695054
                    yMin: 37.745000054347535
                    spatialReference: Factory.SpatialReference.createWgs84()
                }
            }
        }

        onMouseClicked: {
            if (isOffline && !selectedFeature) {
                // identify to select a feature
                mapView.identifyLayer(map.operationalLayers.get(0), mouse.x, mouse.y, 5, false);
            } else if (isOffline && selectedFeature) {

                // connect to feature table signal
                const featureTable = map.operationalLayers.get(0).featureTable;
                featureTable.updateFeatureStatusChanged.connect(()=> {
                    if (featureTable.updateFeatureStatus === Enums.TaskStatusCompleted) {
                        // clear selections
                        featureTable.featureLayer.clearSelection();
                        selectedFeature = null;
                        instructionText = "Tap the sync button";
                        syncButton.visible = true;
                    }
                });

                // update selected feature's geometry
                selectedFeature.geometry = mouse.mapPoint;
                featureTable.updateFeature(selectedFeature);
            }
        }

        onIdentifyLayerStatusChanged: {
            if (identifyLayerStatus === Enums.TaskStatusCompleted) {
                const featureLayer = map.operationalLayers.get(0);

                // clear any previous selections
                featureLayer.clearSelection();
                selectedFeature = null;

                // select the feature
                if (identifyLayerResult.geoElements.length > 0) {
                    const geoElement = identifyLayerResult.geoElements[0];
                    featureLayer.selectFeature(geoElement);
                    selectedFeature = geoElement;
                    instructionText = "Tap on map to move feature";
                }
            }
        }
    }

    //! [EditAndSyncFeatures create GeodatabaseSyncTask]
    // create the GeodatabaseSyncTask to generate the local geodatabase
    GeodatabaseSyncTask {
        id: geodatabaseSyncTask
        url: featureServiceUrl
        property var generateJob
        property var syncJob

        function executeGenerate() {
            // execute the asynchronous task and obtain the job
            generateJob = generateGeodatabase(generateParameters, outputGdb);

            // check if the job is valid
            if (generateJob) {

                // show the sync window
                syncWindow.visible = true;

                // connect to the job's status changed signal to know once it is done
                generateJob.jobStatusChanged.connect(updateGenerateJobStatus);

                // start the job
                generateJob.start();
            } else {
                // a valid job was not obtained, so show an error
                syncWindow.visible = true;
                statusText = "Generate failed";
                syncWindow.hideWindow(5000);
            }
        }

        function updateGenerateJobStatus() {
            switch(generateJob.jobStatus) {
            case Enums.JobStatusFailed:
                statusText = "Generate failed";
                syncWindow.hideWindow(5000);
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
                statusText = "Complete";
                syncWindow.hideWindow(1500);
                offlineGdb = generateJob.geodatabase;
                displayLayersFromGeodatabase();
                isOffline = true;
                break;
            default:
                break;
            }
        }

        function executeSync() {
            // execute the asynchronous task and obtain the job
            syncJob = syncGeodatabase(syncParameters, offlineGdb);

            // check if the job is valid
            if (syncJob) {

                // show the sync window
                syncWindow.visible = true;

                // connect to the job's status changed signal to know once it is done
                syncJob.jobStatusChanged.connect(updateSyncJobStatus);

                // start the job
                syncJob.start();
            } else {
                // a valid job was not obtained, so show an error
                syncWindow.visible = true;
                statusText = "Sync failed";
                syncWindow.hideWindow(5000);
            }
        }

        function updateSyncJobStatus() {
            switch(syncJob.jobStatus) {
            case Enums.JobStatusFailed:
                statusText = "Sync failed";
                syncWindow.hideWindow(5000);
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
                statusText = "Complete";
                syncWindow.hideWindow(1500);
                isOffline = true;
                break;
            default:
                break;
            }
        }

        // ...
        //! [EditAndSyncFeatures create GeodatabaseSyncTask]

        function displayLayersFromGeodatabase() {
            // remove the original online feature layers
            map.operationalLayers.clear();

            // load the geodatabase to access the feature tables
            offlineGdb.loadStatusChanged.connect(()=> {
                if (offlineGdb.loadStatus === Enums.LoadStatusLoaded) {
                    // create a feature layer from each feature table, and add to the map
                    for (let i = 0; i < offlineGdb.geodatabaseFeatureTables.length; i++) {
                        const featureTable = offlineGdb.geodatabaseFeatureTables[i];
                        const featureLayer = ArcGISRuntimeEnvironment.createObject("FeatureLayer");
                        featureLayer.featureTable = featureTable;
                        map.operationalLayers.append(featureLayer);
                    }

                    // hide the extent rectangle and download button
                    extentRectangle.visible = false;
                    syncButton.visible = false;
                }
            });
            offlineGdb.load();
        }

        Component.onDestruction: {
            generateJob.jobStatusChanged.disconnect(updateGenerateJobStatus);
            syncJob.jobStatusChanged.disconnect(updateSyncJobStatus);
        }
    }

    //! [EditAndSyncFeatures GeodatabaseSyncTask parameters]
    // create the generate geodatabase parameters
    GenerateGeodatabaseParameters {
        id: generateParameters
        extent: generateExtent
        outSpatialReference: SpatialReference { wkid: 3857 }
        returnAttachments: false

        // only generate a geodatabase with 1 layer
        layerOptions: [
            GenerateLayerOption {
                layerId: featureLayerId
            }
        ]
    }

    // create the sync geodatabase parameters
    SyncGeodatabaseParameters {
        id: syncParameters

        // only sync the 1 layer
        layerOptions: [
            SyncLayerOption {
                layerId: featureLayerId
            }
        ]
        // push up edits, and receive any new edits
        geodatabaseSyncDirection: Enums.SyncDirectionBidirectional
    }
    //! [EditAndSyncFeatures GeodatabaseSyncTask parameters]

    // create an extent rectangle for the output geodatabase
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

    // Create the button to generate/sync geodatabase
    Rectangle {
        id: syncButton
        property bool pressed: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 23
        }

        width: isOffline ? 175 : 200
        height: 35
        color: pressed ? "#959595" : "#D6D6D6"
        radius: 8
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
                source: isOffline ? "qrc:/Samples/EditData/EditAndSyncFeatures/sync.png" : "qrc:/Samples/EditData/EditAndSyncFeatures/download.png"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: isOffline ? "Sync Geodatabase" : "Generate Geodatabase"
                font.pixelSize: 14
                color: "#474747"
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: syncButton.pressed = true
            onReleased: syncButton.pressed = false
            onClicked: {
                if (isOffline) {
                    instructions.visible = false;
                    geodatabaseSyncTask.executeSync();
                } else {
                    getRectangleEnvelope();
                    geodatabaseSyncTask.executeGenerate();
                }
            }

            function getRectangleEnvelope() {
                const corner1 = mapView.screenToLocation(extentRectangle.x, extentRectangle.y);
                const corner2 = mapView.screenToLocation((extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                const envBuilder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder");
                envBuilder.setCorners(corner1, corner2);
                generateExtent = GeometryEngine.project(envBuilder.geometry, Factory.SpatialReference.createWebMercator());
            }
        }
    }

    // Create a bar to display editing instructions
    Rectangle {
        id: instructions
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 25
        color: "gray"
        opacity: 0.9
        visible: false

        Text {
            anchors.centerIn: parent
            text: instructionText
            font.pixelSize: 16
            color: "white"
        }
    }

    // Create a window to display the generate/sync window
    Rectangle {
        id: syncWindow
        anchors.fill: parent
        color: "transparent"
        clip: true
        visible: false

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
            width: 125
            height: 100
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
            }
        }

        Timer {
            id: hideWindowTimer

            onTriggered: {
                syncWindow.visible = false;
                instructions.visible = true;
                instructionText = "Tap on a feature";
            }
        }

        function hideWindow(time) {
            hideWindowTimer.interval = time;
            hideWindowTimer.restart();
        }
    }

    FileFolder {
        url: dataPath

        // create the data path if it does not yet exist
        Component.onCompleted: {
            if (!exists) {
                makePath(dataPath);
            }
        }
    }

    Component.onDestruction: {
        // unregister the replica
        if (offlineGdb)
            geodatabaseSyncTask.unregisterGeodatabase(offlineGdb)
    }
}
