// [WriteFile Name=GenerateOfflineMapLocalBasemap, Category=Maps]
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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISExtras 1.1
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    readonly property url outputMapPackage: System.temporaryFolder.url + "/OfflineMap_%1.mmpk".arg(new Date().getTime().toString())
    readonly property url basemapDirectory: System.userHomePath + "/ArcGIS/Runtime/Data/tpkx"
    readonly property string webMapId: "acc027394bc84c2fb04d1ed317aac674"
    property bool useLocalBasemap: false

    MapView {
        id: mapView
        anchors.fill: parent

        // Create a Map from a Portal Item
        Map {
            id: map

            PortalItem {
                id: mapPortalItem
                itemId: webMapId
            }
        }

        // Create a button and anchor it to the attribution top
        DownloadButton {
            id: downloadButton
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: mapView.attributionTop
                margins: 5
            }
            visible: map.loadStatus === Enums.LoadStatusLoaded

            onButtonClicked: dialog.open()
        }
    }

    // Create an extent rectangle for selecting the offline area
    Rectangle {
        id: extentRectangle
        anchors.centerIn: parent
        width: parent.width - 50
        height: parent.height - 125
        color: "transparent"
        visible: map.loadStatus === Enums.LoadStatusLoaded
        border {
            color: "red"
            width: 3
        }

        function getRectangleEnvelope() {
            const corner1 = mapView.screenToLocation(extentRectangle.x, extentRectangle.y);
            const corner2 = mapView.screenToLocation((extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
            const envBuilder = ArcGISRuntimeEnvironment.createObject("EnvelopeBuilder");
            envBuilder.setCorners(corner1, corner2);
            const mapExtent = GeometryEngine.project(envBuilder.geometry, Factory.SpatialReference.createWebMercator());
            offlineMapTask.createDefaultGenerateOfflineMapParameters(mapExtent);
        }
    }


    // Create Offline Map Task
    OfflineMapTask {
        id: offlineMapTask
        portalItem: mapPortalItem
        property var generateJob

        onErrorChanged: console.log("error:", error.message, error.additionalMessage);

        onCreateDefaultGenerateOfflineMapParametersStatusChanged: {
            if (createDefaultGenerateOfflineMapParametersStatus !== Enums.TaskStatusCompleted)
                return;

            const parameters = offlineMapTask.createDefaultGenerateOfflineMapParametersResult;

            // update default parameters to specify use of local basemap
            // this will prevent new tiles from being generated on the server
            // and will reduce generation and download time/
            if (useLocalBasemap) {
                // set the path where 'naperville_imagery.tpkx' exists
                parameters.referenceBasemapDirectory = System.resolvedPath(basemapDirectory);
                // A default reference basemap filename can be specified by the source portal item's advanced offline options.
                parameters.referenceBasemapFilename = "naperville_imagery.tpkx";
            }

            // Take the map offline
            takeMapOffline(offlineMapTask.createDefaultGenerateOfflineMapParametersResult);
        }


        function takeMapOffline(parameters) {
            // create the job
            generateJob = offlineMapTask.generateOfflineMap(parameters, outputMapPackage);

            // check if job is valid
            if (generateJob) {
                // show the export window
                generateWindow.visible = true;

                // connect to the job's status changed signal to know once it is done
                generateJob.jobStatusChanged.connect(updateJobStatus);
                // connect to the job's progress changed signal
                generateJob.progressChanged.connect(updateProgress);

                generateJob.start();
            } else {
                generateWindow.visible = true;
                generateWindow.statusText = "Task failed";
                generateWindow.hideWindow(5000);
            }
        }

        function updateJobStatus() {
            switch(generateJob.jobStatus) {
            case Enums.JobStatusFailed:
                generateWindow.statusText = "Task failed";
                generateWindow.hideWindow(5000);
                break;
            case Enums.JobStatusNotStarted:
                generateWindow.statusText = "Job not started";
                break;
            case Enums.JobStatusPaused:
                generateWindow.statusText = "Job paused";
                break;
            case Enums.JobStatusStarted:
                generateWindow.statusText = "In progress";
                break;
            case Enums.JobStatusSucceeded:
                // show any layer errors
                if (generateJob.result.hasErrors) {
                    const layerErrors = generateJob.result.layerErrors;
                    let errorText = "";
                    for (let i = 0; i < layerErrors.length; i++) {
                        const errorPair = layerErrors[i];
                        errorText += errorPair.layer.name + ": " + errorPair.error.message + "\n";
                    }
                    msgDialog.detailedText = errorText;
                    msgDialog.open();
                }

                // show the map
                generateWindow.statusText = "Complete";
                generateWindow.hideWindow(1500);
                displayOfflineMap(generateJob.result);
                break;
            default:
                console.log("default");
                break;
            }
        }

        function updateProgress() {
            generateWindow.progressText = generateJob.progress;
        }

        function displayOfflineMap(result) {
            // Set the offline map to the MapView
            mapView.map = result.offlineMap;
            downloadButton.visible = false;
            extentRectangle.visible = false;
        }

        Component.onDestruction: {
            if (generateJob) {
                generateJob.jobStatusChanged.disconnect(updateJobStatus);
                generateJob.progressChanged.disconnect(updateProgress);
            }
        }
    }

    GenerateWindow {
        id: generateWindow
        anchors.fill: parent
    }

    Dialog {
        id: msgDialog
        modal: true
        x: Math.round(parent.width - width) / 2
        y: Math.round(parent.height - height) / 2
        standardButtons: Dialog.Ok
        title: "Layer Errors"
        property alias text : textLabel.text
        property alias detailedText : detailsLabel.text
        ColumnLayout {
            Text {
                id: textLabel
                text: "Some layers could not be taken offline."
            }
            Text {
                id: detailsLabel
            }
        }
    }

    Dialog {
        id: dialog
        anchors.centerIn: parent
        width: 200

        Column {
            spacing: 2
            width: parent.width

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: "This web map references a local basemap with the name 'naperville_imagery.tpkx'.\nYou can use the basemap already on disk or download the basemap again"
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Use Local Basemap"
                onClicked: {
                    useLocalBasemap = true;
                    extentRectangle.getRectangleEnvelope();
                    dialog.close();
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Download Basemap"
                onClicked: {
                    useLocalBasemap = false;
                    extentRectangle.getRectangleEnvelope();
                    dialog.close();
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Cancel"
                onClicked: dialog.close()
            }
        }
    }

    /* Uncomment this section when running as standalone application
    AuthenticationView {
        anchors.fill: parent
    }
    */
}
