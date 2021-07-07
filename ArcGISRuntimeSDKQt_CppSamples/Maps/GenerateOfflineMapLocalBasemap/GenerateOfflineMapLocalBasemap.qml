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
import Esri.Samples 1.0
import Esri.ArcGISRuntime.Toolkit 100.11

GenerateOfflineMapLocalBasemapSample {
    id: offlineMapSample
    clip: true
    width: 800
    height: 600

    onUpdateStatus: generateWindow.statusText = status;
    onUpdateProgress: generateWindow.progressText = progress;
    onHideWindow: {
        generateWindow.hideWindow(time);

        if (success) {
            extentRectangle.visible = false;
            downloadButton.visible = false;
        }
    }

    onShowLayerErrors: {
        msgDialog.detailedText = error;
        msgDialog.open();
    }

    // add a mapView component
    MapView {
        id: mapView
        anchors.fill: parent
        objectName: "mapView"

        // Create a button and anchor it to the attribution top
        DownloadButton {
            id: downloadButton
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: mapView.attributionTop
                margins: 5
            }
            visible: mapLoaded

            onButtonClicked: {
                dialog.open();
            }
        }
    }

    // Create an extent rectangle for selecting the offline area
    Rectangle {
        id: extentRectangle
        anchors.centerIn: parent
        width: parent.width - 50
        height: parent.height - 125
        color: "transparent"
        visible: mapLoaded
        border {
            color: "red"
            width: 3
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
                    generateMapByExtent(extentRectangle.x, extentRectangle.y, (extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                    generateWindow.visible = true;
                    dialog.close();
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Download Basemap"
                onClicked: {
                    useLocalBasemap = false;
                    generateMapByExtent(extentRectangle.x, extentRectangle.y, (extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                    generateWindow.visible = true;
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
