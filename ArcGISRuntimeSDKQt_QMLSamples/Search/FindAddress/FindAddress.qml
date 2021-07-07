// [WriteFile Name=FindAddress, Category=Search]
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
import QtQuick.Layouts 1.3
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    id: root
    width: 800
    height: 600
    
    property string calloutText
    property Point calloutLocation

    // Create MapView that contains a Map with the Imagery with Labels Basemap
    MapView {
        id: mapView
        anchors.fill: parent

        // Create a GraphicsOverlay to display the geocode results
        GraphicsOverlay {
            id: graphicsOverlay

            SimpleRenderer {
                PictureMarkerSymbol {
                    url: "qrc:/Samples/Search/FindAddress/pin_circle_red.png"
                    width: 35
                    height: 35
                    offsetY: height / 2 // the tip of the pin will point to the location
                }
            }
        }

        Map {
            Basemap {
                initStyle: Enums.BasemapStyleArcGISImagery
            }
        }

        // show the callout once the identify is complete
        onIdentifyGraphicsOverlayStatusChanged: {
            if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted) {
                if (identifyGraphicsOverlayResult.graphics.length > 0) {
                    // setup the attributes
                    calloutText = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("Match_addr");

                    // show the callout
                    callout.showCallout();
                }
            }
        }

        // perform identify operation on mapview
        onMouseClicked: {
            if (callout.visible)
                callout.dismiss();
            calloutLocation = mouse.mapPoint;
            mapView.identifyGraphicsOverlay(graphicsOverlay, mouse.x, mouse.y, 2, false);
        }

        // hide callout after navigation
        onViewpointChanged: {
            if (callout.visible)
                callout.dismiss();
        }

        calloutData {
            location:  calloutLocation
            title: calloutText            
        }

        // map callout window
        Callout {
            id: callout
            borderWidth: 1
            calloutData: parent.calloutData
            borderColor: "lightgrey"
            accessoryButtonHidden: true
            maxWidth: root.width * 0.75
            leaderPosition: leaderPositionEnum.Automatic
        }
    }

    //! [FindAddress create LocatorTask]
    // Create a locator task using the World Geocoding Service
    LocatorTask {
        id: locatorTask
        
        // An ArcGIS Developer API key is required to utilize the world geocoding service
        url: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer"

        // handle the result once the geocode status is complete
        onGeocodeStatusChanged: {
            if (geocodeStatus === Enums.TaskStatusCompleted) {
                if (geocodeResults.length > 0) {
                    graphicsOverlay.graphics.clear();
                    const graphic = ArcGISRuntimeEnvironment.createObject("Graphic");
                    graphic.geometry = geocodeResults[0].displayLocation;
                    graphic.attributes.attributesJson = geocodeResults[0].attributes;
                    graphicsOverlay.graphics.append(graphic);
                    mapView.setViewpointCenterAndScale(geocodeResults[0].extent.center, 8000);
                }
            }
        }
    }

    // Create geocode parameters
    GeocodeParameters {
        id: geocodeParameters
        minScore: 75
        resultAttributeNames: ["Place_addr", "Match_addr"]
    }
    //! [FindAddress create LocatorTask]

    // search bar for geocoding
    Column {
        anchors {
            fill: parent
            margins: 10
        }

        Rectangle {
            color: "#f7f8fa"
            border {
                color: "#7B7C7D"
            }
            radius: 2
            width: parent.width
            height: childrenRect.height

            GridLayout {
                width: parent.width
                columns: 3
                TextField {
                    Layout.margins: 5
                    Layout.fillWidth: true
                    id: textField
                    font.pixelSize: 14
                    placeholderText: "Type in an address"
                    selectByMouse: true

                    Keys.onEnterPressed: geocodeAddress();
                    Keys.onReturnPressed: geocodeAddress();

                    function geocodeAddress() {
                        //! [FindAddress geocodeWithParameters]
                        locatorTask.geocodeWithParameters(textField.text, geocodeParameters);
                        //! [FindAddress geocodeWithParameters]
                        suggestView.visible = false;
                        Qt.inputMethod.hide();
                    }
                }

                Rectangle {
                    Layout.margins: 5
                    width: height
                    height: textField.height
                    color: "#f7f8fa"
                    visible: textField.length === 0
                    enabled: visible
                    Image {
                        anchors.fill: parent
                        source: "qrc:/Samples/Search/FindAddress/ic_menu_collapsedencircled_light_d.png"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                textField.focus = true;
                                suggestView.visible = !suggestView.visible;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.margins: 5
                    width: height
                    color: "transparent"
                    height: textField.height
                    visible: textField.length !== 0
                    enabled: visible
                    Image {
                        anchors.fill: parent
                        source: "qrc:/Samples/Search/FindAddress/ic_menu_closeclear_light_d.png"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                textField.text = "";
                                if (callout.visible)
                                    callout.dismiss();
                                graphicsOverlay.graphics.clear();
                            }
                        }
                    }
                }
            }
        }

        // show a drop down of suggested locations
        ListView {
            id: suggestView
            height: 300
            width: textField.width
            visible: false
            clip: true
            model: geocodeSuggestions
            delegate: Component {
                Rectangle {
                    id: rect
                    width: parent.width
                    height: 25
                    color: "#f7f8fa"

                    Rectangle {
                        anchors {
                            top: parent.top;
                            left: parent.left;
                            right: parent.right;
                            topMargin: -5
                            leftMargin: 20
                            rightMargin: 20
                        }
                        color: "darkgrey"
                        height: 1
                    }

                    Text {
                        text: name
                        anchors {
                            fill: parent
                            leftMargin: 5
                        }

                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            textField.text = name;
                            suggestView.visible = false;
                            locatorTask.geocodeWithParameters(name, geocodeParameters);
                            Qt.inputMethod.hide();
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: geocodeSuggestions
        ListElement { name: "277 N Avenida Caballeros, Palm Springs, CA" }
        ListElement { name: "380 New York St, Redlands, CA 92373" }
        ListElement { name: "Београд" }
        ListElement { name: "Москва" }
        ListElement { name: "北京" }
    }
}
