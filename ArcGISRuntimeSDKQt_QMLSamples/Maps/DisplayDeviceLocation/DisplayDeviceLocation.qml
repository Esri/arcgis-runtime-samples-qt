// [WriteFile Name=DisplayDeviceLocation, Category=Maps]
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
import QtPositioning 5.3
import QtSensors 5.3
import Esri.ArcGISRuntime 100.11

Rectangle {
    width: 800
    height: 600
    
    readonly property string compassMode: "Compass"
    readonly property string navigationMode: "Navigation"
    readonly property string recenterMode: "Re-Center"
    readonly property string onMode: "On"
    readonly property string stopMode: "Stop"
    readonly property string closeMode: "Close"
    property string currentModeText: stopMode
    property string currentModeImage: "qrc:/Samples/Maps/DisplayDeviceLocation/Stop.png"

    // Create MapView that contains a Map with the Imagery with Labels Basemap
    MapView {
        id: mapView
        anchors.fill: parent
        Map {
            Basemap {
                initStyle: Enums.BasemapStyleArcGISImageryStandard
            }

            // start the location display
            onLoadStatusChanged: {
                if (loadStatus === Enums.LoadStatusLoaded) {
                    // populate list model with modes
                    autoPanListModel.append({name: compassMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/Compass.png"});
                    autoPanListModel.append({name: navigationMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/Navigation.png"});
                    autoPanListModel.append({name: recenterMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/Re-Center.png"});
                    autoPanListModel.append({name: onMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/On.png"});
                    autoPanListModel.append({name: stopMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/Stop.png"});
                    autoPanListModel.append({name: closeMode, image: "qrc:/Samples/Maps/DisplayDeviceLocation/Close.png"});
                }
            }
        }

        Component.onDestruction: {
            mapView.locationDisplay.stop();
        }
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        visible: autoPanListView.visible
        color: "black"
        opacity: 0.7
    }    

    ListView {
        id: autoPanListView
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        visible: false
        width: parent.width
        height: 300
        spacing: 10
        model: ListModel {
            id: autoPanListModel
        }

        delegate: Row {
            id: autopanRow
            anchors.right: parent.right
            spacing: 10

            Text {
                text: name
                font.pixelSize: 25
                color: "white"
                MouseArea {
                    anchors.fill: parent
                    // When an item in the list view is clicked
                    onClicked: {
                       autopanRow.updateAutoPanMode();
                    }
                }
            }

            Image {
                source: image
                width: 40
                height: width
                MouseArea {
                    anchors.fill: parent
                    // When an item in the list view is clicked
                    onClicked: {
                       autopanRow.updateAutoPanMode();
                    }
                }
            }

            // set the appropriate auto pan mode
            function updateAutoPanMode() {
                switch (name) {
                case compassMode:
                    mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeCompassNavigation;
                    mapView.locationDisplay.start();
                    break;
                case navigationMode:
                    mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeNavigation;
                    mapView.locationDisplay.start();
                    break;
                case recenterMode:
                    mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
                    mapView.locationDisplay.start();
                    break;
                case onMode:                   
                    mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeOff;
                    mapView.locationDisplay.start();
                    break;
                case stopMode:
                    mapView.locationDisplay.stop();
                    break;
                }

                if (name !== closeMode) {
                    currentModeText = name;
                    currentModeImage = image;
                }

                // hide the list view
                currentAction.visible = true;
                autoPanListView.visible = false;
            }
        }
    }

    Row {
        id: currentAction
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: 25
        }
        spacing: 10

        Text {
            text: currentModeText
            font.pixelSize: 25
            color: "white"
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    currentAction.visible = false;
                    autoPanListView.visible = true;
                }
            }
        }

        Image {
            source: currentModeImage
            width: 40
            height: width
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    currentAction.visible = false;
                    autoPanListView.visible = true;
                }
            }
        }
    }
}
