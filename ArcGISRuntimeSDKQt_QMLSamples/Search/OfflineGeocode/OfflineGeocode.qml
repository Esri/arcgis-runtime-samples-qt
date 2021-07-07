// [WriteFile Name=OfflineGeocode, Category=Search]
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
import Esri.ArcGISExtras 1.1
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    clip: true
    width: 800
    height: 600
    
    readonly property url dataPath: System.userHomePath + "/ArcGIS/Runtime/Data"
    property Point pinLocation: null
    property Point clickedPoint: null
    property bool isReverseGeocode: false
    property bool isPressAndHold: false
    property string errorMessage: ""

    // Map view UI presentation at top
    MapView {
        id: mapView
        anchors.fill: parent

        // initialize callout
        calloutData {
            title: "Address"
        }

        Map {

            // create local tiled layer using tile package
            Basemap {
                ArcGISTiledLayer {
                    TileCache {
                        path: dataPath + "/tpkx/streetmap_SD.tpkx"
                    }
                }
            }

            // set initial viewpoint
            ViewpointCenter {
                Point {
                    x: -13042254.715252
                    y: 3857970.236806
                    spatialReference: SpatialReference {
                        wkid: 3857
                    }
                }
                targetScale: 2e4
            }

            onErrorChanged: errorMessage = error.message;
        }

        // add a graphics overlay to the mapview
        GraphicsOverlay {
            id: graphicsOverlay

            // pin graphic that will visually display geocoding results
            Graphic {
                id: pinGraphic
                geometry: pinLocation
                visible: true

                PictureMarkerSymbol {
                    id: pictureMarker
                    height: 36
                    width: 19
                    url: "qrc:/Samples/Search/OfflineGeocode/red_pin.png"
                    offsetY: height / 2
                }
            }
        }

        Callout {
            id: callout
            calloutData: parent.calloutData
            screenOffsetY: (pictureMarker.height / 2) * -1
            accessoryButtonHidden: true
            leaderPosition: leaderPositionEnum.Automatic
        }

        // dismiss suggestions and no results notification on mouse press
        onMousePressed: {
            noResultsRect.visible = false;
            suggestionRect.visible = false;
        }

        onMouseClicked: {
            clickedPoint = mouse.mapPoint;
            mapView.identifyGraphicsOverlayWithMaxResults(graphicsOverlay, mouse.x, mouse.y, 5, false, 1);
        }

        onIdentifyGraphicsOverlayStatusChanged: {
            if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted){

                // if clicked on the pin graphic, display callout.
                if (identifyGraphicsOverlayResult.graphics.length > 0)
                    callout.showCallout();

                // otherwise, normal reverse geocode
                else if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress){
                    isReverseGeocode = true;
                    locatorTask.reverseGeocodeWithParameters(clickedPoint, reverseGeocodeParams);
                }
            }
        }

        // hide suggestion window if viewpoint changes
        onViewpointChanged: {
            suggestionRect.visible = false;
            noResultsRect.visible = false;
        }

        // When user press and holds, prepare for real-time reverse geocoding
        onMousePressedAndHeld: {
            isPressAndHold = true;
            isReverseGeocode = true;

            if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress)
                locatorTask.reverseGeocodeWithParameters(mouse.mapPoint, reverseGeocodeParams);
        }

        // real-time reverse geocode if mouse being held down
        onMousePositionChanged: {
            if (isPressAndHold && locatorTask.geocodeStatus !== Enums.TaskStatusInProgress)
                locatorTask.reverseGeocodeWithParameters(mouse.mapPoint, reverseGeocodeParams);
        }

        // stop real-time reverse geocoding
        onMouseReleased: {
            isPressAndHold = false;
            isReverseGeocode = false;
        }

        onErrorChanged: errorMessage = error.message;
    }

    //! [OfflineGeocode LocatorTask]

    LocatorTask {
        id: locatorTask
        url: dataPath + "/Locators/SanDiegoStreetAddressLocator/SanDiego_StreetAddress.loc"
        //! [OfflineGeocode LocatorTask]

        suggestions {
            // suggestions will update whenever textField's text property changes
            searchText: textField.text
            suggestTimerThreshold: 250
            suggestParameters: SuggestParameters {
                maxResults: 5
            }
        }

        GeocodeParameters {
            id: geocodeParams
            minScore: 75
            maxResults: 1
        }

        ReverseGeocodeParameters {
            id: reverseGeocodeParams
            maxDistance: 1000
            maxResults: 1
        }

        onGeocodeStatusChanged: {
            if (geocodeStatus === Enums.TaskStatusCompleted) {

                if(geocodeResults.length > 0) {
                    callout.dismiss();

                    // zoom to geocoded location
                    mapView.setViewpointCenter(geocodeResults[0].displayLocation)

                    // set pin and edit callout
                    pinLocation = geocodeResults[0].displayLocation;
                    mapView.calloutData.geoElement = pinGraphic;
                    mapView.calloutData.detail = geocodeResults[0].label;

                    // if it was a reverse geocode, also display callout
                    if (isReverseGeocode)
                        callout.showCallout();

                    // continue reverse geocoding if press and holding mouse
                    if (!isPressAndHold)
                        isReverseGeocode = false;
                }

                // if no result found, inform user
                else {
                    callout.dismiss()
                    noResultsRect.visible = true;
                    pinLocation = null;
                }
            }
        }

        onErrorChanged: errorMessage = error.message;
    }

    Column {
        anchors {
            fill: parent
            margins: 10
        }

        Rectangle {
            id: addressSearchRect
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height

            color: "#f7f8fa"
            border {
                color: "#7B7C7D"
                width: 1
            }
            radius: 2

            RowLayout {
                width: parent.width
                height: childrenRect.height

                // search bar for geocoding
                TextField {
                    id: textField
                    Layout.fillWidth: true
                    leftPadding: 5
                    selectByMouse: true

                    placeholderText: "Enter an Address"

                    // when user types, make suggestions visible
                    onTextChanged: {
                        suggestionRect.visible = true;
                    }

                    // when enter or return is presed, begin geocoding with inputted text
                    onAccepted: {
                        suggestionRect.visible = false;
                        if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress)
                            locatorTask.geocodeWithParameters(text, geocodeParams);
                    }

                    // initial text
                    Component.onCompleted: {
                        text = "910 N Harbor Dr, San Diego, CA 92101";
                        suggestionRect.visible = false;
                    }
                }

                // button to open and close suggestions
                Rectangle {
                    Layout.margins: 5
                    width: height
                    height: textField.contentHeight
                    color: "#f7f8fa"
                    radius: 2

                    Image {
                        anchors.fill: parent
                        source: suggestionRect.visible ? "qrc:/Samples/Search/OfflineGeocode/ic_menu_closeclear_light_d.png" : "qrc:/Samples/Search/OfflineGeocode/ic_menu_collapsedencircled_light_d.png"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                suggestionRect.visible = !suggestionRect.visible;
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: suggestionRect
            width: addressSearchRect.width
            height: 20 * locatorTask.suggestions.count
            color: "#f7f8fa"
            opacity: 0.85

            ListView {
                id: suggestView
                model: locatorTask.suggestions
                height: parent.height
                delegate: Component {

                    Rectangle {
                        width: addressSearchRect.width
                        height: 20
                        color: "#f7f8fa"
                        border.color: "darkgray"

                        Text {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                leftMargin: 5
                                rightMargin: 5
                            }

                            font {
                                weight: Font.Black
                                pixelSize: 12
                            }

                            width: parent.width
                            text: label
                            elide: Text.ElideRight
                            leftPadding: 5
                            color: "black"
                        }

                        // when user clicks suggestion, geocode with the selected address
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress) {
                                    // geocode with the suggestion
                                    locatorTask.geocodeWithParameters(label, geocodeParams);

                                    // change the text label
                                    textField.text = label;
                                }

                                // dismiss suggestions
                                suggestionRect.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // running when geocoding in progress
    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: locatorTask.geocodeStatus === Enums.TaskStatusInProgress
    }

    Rectangle {
        id: noResultsRect
        anchors.centerIn: parent
        height: 50
        width: 200
        color: "#f7f8fa"
        visible: false
        radius: 2
        opacity: 0.85
        border.color: "black"

        Text {
            anchors.centerIn: parent
            text: "No matching address"
            font.pixelSize: 18
        }
    }

    Dialog {
        modal: true
        x: Math.round(parent.width - width) / 2
        y: Math.round(parent.height - height) / 2
        standardButtons: Dialog.Ok
        visible: text.length > 0
        title: "Error"
        property alias text : textLabel.text
        property alias informativeText : detailsLabel.text
        ColumnLayout {
            Text {
                id: textLabel
                text: errorMessage
            }
            Text {
                id: detailsLabel
                text: "please consult README.md"
            }
        }
    }
}
