// [WriteFile Name=CreateAndSaveMap, Category=Maps]
// [Legal]
// Copyright 2018 Esri.

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
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: layerWindow
    }

    // MapView that will display the Map created from the user options
    MapView {
        id: mapView
        visible: false

        Button {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: mapView.attributionTop
                margins: 5
            }
            text: "Save map"

            onClicked: {
                if (portal.loadStatus !== Enums.LoadStatusLoaded)
                    portal.load();
                else {
                    stackView.push(options);
                }
            }
        }
    }

    Component {
        id: layerWindow
        LayerWindow {
            onCreateMapSelected: {
                stackView.push(mapView)
                const map = createMap(basemap, layerList);
                mapView.map = map;
            }
        }
    }

    // Window to display options for setting title, tags, and description
    Component {
        id: options
        SaveOptionsWindow {
            onCancelClicked: {
                stackView.pop();
            }

            onSaveMapClicked: {
                const thumbnail = null;
                const folder = null;
                const forceSave = true;
                const tagsList = tags.split(",");
                mapView.map.saveAs(portal, title, tagsList, forceSave, folder, description, thumbnail);
            }
        }
    }

    // Rectangle to display completion text
    Component {
        id: completionRect
        Rectangle {
            property alias text: completeText.text

            Text {
                id: completeText
                anchors.centerIn: parent

                textFormat: Text.RichText
                horizontalAlignment: Text.AlignHCenter
                onLinkActivated: Qt.openUrlExternally(link)
            }

            Button {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    margins: 5
                }
                text: "Create New Map"
                onClicked: {
                    // We need a local ref to the stackView and layerWindow
                    // object as our object references will have been deleted
                    // once "clear" cleans up this object.
                    const sv = stackView;
                    const lWindow = layerWindow;
                    sv.clear();
                    sv.push(lWindow);
                }
            }
        }
    }


    // Create Portal object that requires sign in
    Portal {
        id: portal
        url: "https://www.arcgis.com"
        loginRequired: true

        onLoadStatusChanged: {
            if (loadStatus === Enums.LoadStatusLoaded) {
                stackView.push(options);
            }
        }
    }

    /*
    // Declare AuthenticationView to handle any authentication challenges
    AuthenticationView {
        anchors.fill: parent
    }
    */

    function createMap(basemap, layerList) {
        // Create the Basemap
        let selectedBasemap;
        if (basemap === "Streets")
            selectedBasemap = Enums.BasemapStyleArcGISStreets;
        else if (basemap === "Imagery")
            selectedBasemap = Enums.BasemapStyleArcGISImagery;
        else if (basemap === "Topographic")
            selectedBasemap = Enums.BasemapStyleArcGISTopographic;
        else if (basemap === "Oceans")
            selectedBasemap = Enums.BasemapStyleArcGISOceans;

        // Create the Map with the basemap
        selectedBasemap = ArcGISRuntimeEnvironment.createObject("Basemap", {initStyle: selectedBasemap});
        const map = ArcGISRuntimeEnvironment.createObject("Map", { basemap: selectedBasemap }, mapView);

        map.saveStatusChanged.connect(()=> {
            if (map.saveStatus === Enums.TaskStatusCompleted) {
                const url =  "https://www.arcgis.com/home/item.html?id=%1".arg(map.item.itemId);
                stackView.push(completionRect,
                               { text: 'Map saved successfully.<br>View in <a href="%1">ArcGIS Online</a>'.arg(url) });
            } else if (map.saveStatus === Enums.TaskStatusErrored) {
                if (stackView.currentItem === completionRect)
                    return;

                stackView.push(completionRect,
                               { text: 'An error occurred while saving the map. Details: %1 %2'.arg(map.error.message).arg(map.error.additionalMessage) });
            }
        });

        // Add Operational Layers
        for (let i = 0; i < layerList.length; i++) {
            if (layerList[i] === "WorldElevations") {
                const elevationLyr = ArcGISRuntimeEnvironment.createObject("ArcGISMapImageLayer", {
                                                                               url : "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Elevation/WorldElevations/MapServer"
                                                                           });
                elevationLyr.opacity = 0.5;
                map.operationalLayers.append(elevationLyr);
            } else if (layerList[i] === "Census") {
                map.operationalLayers.append(ArcGISRuntimeEnvironment.createObject("ArcGISMapImageLayer", {
                                                                                       url : "https://sampleserver5.arcgisonline.com/arcgis/rest/services/Census/MapServer"
                                                                                   }));
            }
        }

        // Return the Map
        return map;
    }
}
