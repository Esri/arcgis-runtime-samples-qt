// [WriteFile Name=RasterLayerFile, Category=Analysis]
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
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.2
import Esri.Samples 1.0
import Esri.ArcGISExtras 1.2

RasterLayerFileSample {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property real scaleFactor: System.displayScaleFactor
    property string dataPath: System.userHomePath + "/ArcGIS/Runtime/Data/raster/"
    property var supportedFormats: ["img","I12","dt0","dt1","dt2","tc2","geotiff","tif", "tiff", "hr1","jpg","jpeg","jp2","ntf","png","i21","ovr"]

    // add a mapView component
    MapView {
        anchors.fill: parent
        objectName: "mapView"
    }

    Rectangle {
        visible: addButton.visible
        anchors.centerIn: addButton
        radius: 8 * scaleFactor
        height: addButton.height + (16 * scaleFactor)
        width: addButton.width + (16 * scaleFactor)
        color: "lightgrey"
        border.color: "darkgrey"
        border.width: 2 * scaleFactor
        opacity: 0.75
    }

    Button {
        id: addButton
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            margins: 32 * scaleFactor
        }

        text: "Add Raster"
        onClicked: loader.open();
    }

    RasterLoader {
        id: loader
        anchors.fill: rootRectangle
        folder: dataPath
        supportedExtensions: supportedFormats

        onRasterFileChosen: createAndAddRasterLayer(url);
    }
}
