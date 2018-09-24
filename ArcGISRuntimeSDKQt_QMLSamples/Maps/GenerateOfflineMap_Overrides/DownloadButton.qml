// Copyright 2017 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import QtQuick 2.6

// Create the download button to export the tile cache
Rectangle {
    property bool pressed: false
    signal buttonClicked()

    width: 265 * scaleFactor
    height: 35 * scaleFactor
    color: pressed ? "#959595" : "#D6D6D6"
    radius: 5
    border {
        color: "#585858"
        width: 1 * scaleFactor
    }

    Row {
        anchors.fill: parent
        spacing: 5 * scaleFactor
        Image {
            width: 38 * scaleFactor
            height: width
            source: "qrc:/Samples/Maps/GenerateOfflineMap_Overrides/download.png"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Generate Offline Map (Overrides)"
            font.pixelSize: 14 * scaleFactor
            color: "#474747"
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: downloadButton.pressed = true
        onReleased: downloadButton.pressed = false
        onClicked: {
            buttonClicked();
        }
    }
}