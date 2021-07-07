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
import Esri.Samples 1.0

ExportTilesSample {
    id: exportTilesSample
    width: 800
    height: 600
        
    property string statusText: ""

    // add a mapView component
    MapView {
        id: mapView
        anchors.fill: parent
        objectName: "mapView"
    }

    onHideWindow: {
        exportWindow.hideWindow(time);

        if (success) {
            extentRectangle.visible = false;
            downloadButton.visible = false;
        }
    }

    onUpdateStatus: statusText = status;

    Rectangle {
        id: extentRectangle
        anchors.centerIn: parent
        width: parent.width - 50
        height: parent.height - 125
        color: "transparent"
        border {
            color: "red"
            width: 3
        }
    }

    // Create the download button to export tile cache
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
                // call the C++ invokable function to export tile cache from the input screen coordinates
                exportTilesSample.exportTileCacheFromCorners(extentRectangle.x, extentRectangle.y, (extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                exportWindow.visible = true;
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
                    text: exportTilesSample.exportTilesProgress + "% Completed"
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
