// [WriteFile Name=GenerateGeodatabase, Category=Features]
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

import QtQuick 2.3
import QtQuick.Controls 1.4
import QtGraphicalEffects 1.0
import Esri.Samples 1.0
import Esri.ArcGISExtras 1.2

GenerateGeodatabaseSample {
    id: generateSample
    width: 800
    height: 600

    property double scaleFactor: System.displayScaleFactor
    property string statusText: ""
    property url dataPath: System.userHomePath + "/ArcGIS/Runtime/Data/"
    property string outputGdb: System.temporaryFolder.path + "/WildfireCpp_%1.geodatabase".arg(new Date().getTime().toString())

    // add a mapView component
    MapView {
        id: mapView        
        anchors.fill: parent
        objectName: "mapView"
    }

    onHideWindow: {
        generateWindow.hideWindow(time);

        if (success) {
            extentRectangle.visible = false;
            downloadButton.visible = false;
        }
    }

    onUpdateStatus: statusText = status;

    Rectangle {
        id: extentRectangle
        anchors.centerIn: parent
        width: parent.width - (50 * scaleFactor)
        height: parent.height - (125 * scaleFactor)
        color: "transparent"
        border {
            color: "red"
            width: 3 * scaleFactor
        }
    }

    // Create the download button to generate geodatabase
    Rectangle {
        id: downloadButton
        property bool pressed: false
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 23 * scaleFactor
        }

        width: 200 * scaleFactor
        height: 35 * scaleFactor
        color: pressed ? "#959595" : "#D6D6D6"
        radius: 8
        border {
            color: "#585858"
            width: 1 * scaleFactor
        }

        Row {
            anchors.fill: parent
            spacing: 5
            Image {
                width: 38 * scaleFactor
                height: width
                source: "qrc:/Samples/Features/GenerateGeodatabase/download.png"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Generate Geodatabase"
                font.pixelSize: 14 * scaleFactor
                color: "#474747"
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: downloadButton.pressed = true
            onReleased: downloadButton.pressed = false
            onClicked: {
                generateSample.generateGeodatabaseFromCorners(extentRectangle.x, extentRectangle.y, (extentRectangle.x + extentRectangle.width), (extentRectangle.y + extentRectangle.height));
                generateWindow.visible = true;
            }
        }
    }

    // Create a window to display the generate window
    Rectangle {
        id: generateWindow
        anchors.fill: parent
        color: "transparent"
        visible: false
        clip: true

        RadialGradient {
            anchors.fill: parent
            opacity: 0.7
            gradient: Gradient {
                GradientStop { position: 0.0; color: "lightgrey" }
                GradientStop { position: 0.5; color: "black" }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
            onWheel: wheel.accepted = true
        }

        Rectangle {
            anchors.centerIn: parent
            width: 125 * scaleFactor
            height: 100 * scaleFactor
            color: "lightgrey"
            opacity: 0.8
            radius: 5
            border {
                color: "#4D4D4D"
                width: 1 * scaleFactor
            }

            Column {
                anchors {
                    fill: parent
                    margins: 10 * scaleFactor
                }
                spacing: 10

                BusyIndicator {
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: statusText
                    font.pixelSize: 16 * scaleFactor
                }
            }
        }

        Timer {
            id: hideWindowTimer

            onTriggered: generateWindow.visible = false;
        }

        function hideWindow(time) {
            hideWindowTimer.interval = time;
            hideWindowTimer.restart();
        }
    }

    FileFolder {
        path: dataPath

        // create the data path if it does not yet exist
        Component.onCompleted: {
            if (!exists) {
                makePath(dataPath);
            }
        }
    }
}
