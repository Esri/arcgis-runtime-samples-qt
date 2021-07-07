// [WriteFile Name=FindPlace, Category=Search]
// [Legal]
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
// [Legal]

import QtQuick 2.6
import QtQuick.Controls 2.2
import QtPositioning 5.6
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISRuntime.Toolkit 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property bool isSearchingLocation: false
    property bool searchByExtent: false

    MapView {
        id: mapView
        anchors.fill: parent

        onDrawStatusChanged: {
            if (drawStatus !== Enums.DrawStatusCompleted || mapView.locationDisplay.started)
                return;

            mapView.locationDisplay.autoPanMode = Enums.LocationDisplayAutoPanModeRecenter;
            mapView.locationDisplay.start();
        }

        Component.onDestruction: {
            mapView.locationDisplay.stop();
        }

        Map {
            Basemap {
                initStyle: Enums.BasemapStyleArcGISTopographic
            }

            // start the location display once the map loads
        }

        // add a graphics overlay to the mapview
        GraphicsOverlay {
            id: graphicsOverlay

            // create a renderer for graphics representing geocode results
            SimpleRenderer {
                PictureMarkerSymbol {
                    id: pinSymbol
                    height: 36
                    width: 19
                    url: "qrc:/Samples/Search/FindPlace/red_pin.png"
                    offsetY: height / 2
                }
            }
        }

        // declare a Callout
        Callout {
            id: callout
            calloutData: parent.calloutData
            accessoryButtonHidden: true
            screenOffsetY: (pinSymbol.height / 2) * -1
            leaderPosition: leaderPositionEnum.Automatic
        }

        // dismiss suggestions if a mouse press occurs in the mapview
        onMousePressed: {
            suggestionView.visible = false;
        }

        // dismiss suggestions and set a search flag when the current viewpoint changes
        onViewpointChanged: {
            suggestionView.visible = false;
            if (poiTextField.text.length > 0 && graphicsOverlay.graphics.count > 0)
                searchByExtent = true;
        }

        // perform an identify on mouse clicked
        onMouseClicked: {
            callout.dismiss();
            mapView.identifyGraphicsOverlayWithMaxResults(graphicsOverlay, mouse.x, mouse.y, 5, false, 1);
        }

        // display the callout with the identify result
        onIdentifyGraphicsOverlayStatusChanged: {
            if (identifyGraphicsOverlayStatus === Enums.TaskStatusCompleted){
                if (!identifyGraphicsOverlayResult.graphics.length > 0)
                    return;

                mapView.calloutData.geoElement = identifyGraphicsOverlayResult.graphics[0];
                mapView.calloutData.title = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("ShortLabel");
                mapView.calloutData.detail = identifyGraphicsOverlayResult.graphics[0].attributes.attributeValue("Place_addr");
                callout.showCallout();
            }
        }
    }

    // declare a locator task that uses the world geocoding service
    LocatorTask {
        id: locatorTask
        
        // An ArcGIS Developer API key is required to utilize the world geocoding service
        url: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer"

        // setup suggestions parameters
        suggestions {
            // set the search text for which to obtain suggestion results
            searchText: poiTextField.focus ? poiTextField.text : locationTextField.text
            suggestParameters: SuggestParameters {
                maxResults: 5
                // the Points of Interest text box should use the POI category, and the location
                // text box should use the Populated Place category as filters
                categories: poiTextField.focus ? ["POI"] : ["Populated Place"]
            }
        }

        // handle the geocodeStatusChanged signal
        onGeocodeStatusChanged: {
            if (geocodeStatus === Enums.TaskStatusCompleted) {
                searchByExtent = false;

                // first determine if we are searching for the preferredSearchLocation
                if (isSearchingLocation) {
                    isSearchingLocation = false;
                    if (!geocodeResults.length > 0)
                        return;

                    const topLocation = geocodeResults[0];
                    geocodePOIs(poiTextField.text, topLocation.displayLocation);
                    return;
                }

                // create graphics for each geocode result
                if (geocodeResults.length > 0) {
                    graphicsOverlay.graphics.clear();
                    let bbox;
                    for (let i = 0; i < geocodeResults.length; i++) {
                        const graphic = ArcGISRuntimeEnvironment.createObject("Graphic");
                        graphic.geometry = geocodeResults[i].displayLocation;
                        graphic.attributes.attributesJson = geocodeResults[i].attributes;
                        graphicsOverlay.graphics.append(graphic);
                        // create bounding box so we can set the viewpoint at the end
                        if (bbox) {
                            bbox = GeometryEngine.unionOf(bbox, graphic.geometry);
                        } else {
                            bbox = graphic.geometry;
                        }
                    }
                    mapView.setViewpointGeometryAndPadding(bbox, 40);
                }

                else {
                    callout.dismiss();
                }
            }
        }
    }

    Rectangle {
        anchors {
            fill: searchColumn
            margins: -5
        }
        color: "white"
    }

    Column {
        id: searchColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 3

        // create a text field for the POI search
        SearchBox {
            id: poiTextField
            imageUrl: "qrc:/Samples/Search/FindPlace/find.png"
            placeholderText: "Point of interest (e.g. Movie Theater)"
            onTextChanged: if (text.length > 0 && suggestionView) { suggestionView.visible = true; }
            onAccepted: {
                geocodePOIs(poiTextField.text, locationTextField.text);
                suggestionView.visible = false;
                callout.dismiss();
            }
            onImageClicked: {
                geocodePOIs(poiTextField.text, locationTextField.text);
                suggestionView.visible = false;
                callout.dismiss();
            }
        }

        // create a text field for the location search
        SearchBox {
            id: locationTextField
            imageUrl: "qrc:/Samples/Search/FindPlace/location.png"
            placeholderText: "In proximity of"
            text: "Current Location"
            onTextChanged: if (text.length > 0 && suggestionView) { suggestionView.visible = true; }
            onAccepted: {
                geocodePOIs(poiTextField.text, locationTextField.text);
                suggestionView.visible = false;
            }
            onImageClicked: {
                locationTextField.text = "Current Location";
                geocodePOIs(poiTextField.text, locationTextField.text);
                suggestionView.visible = false;
            }
        }

        // create a list view for the suggestion results
        SuggestionView {
            id: suggestionView
            width: parent.width
            height: 20 * locatorTask.suggestions.count
            onSuggestionClicked: {
                if (locatorTask.geocodeStatus !== Enums.TaskStatusInProgress) {
                    // change the text label
                    poiTextField.focus ? poiTextField.text = label : locationTextField.text = label;

                    // geocode
                    geocodePOIs(poiTextField.text, locationTextField.text);
                }

                // dismiss suggestions
                suggestionView.visible = false;
            }
        }
    }

    // create a button that allows the user to re-search the current map extent
    SearchButton {
        id: searchExtentButton
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 23
        }
        visible: searchByExtent
        onButtonClicked: {
            geocodePOIs(poiTextField.text, null, mapView.currentViewpointExtent.extent);
            callout.dismiss();
        }
    }

    function geocodePOIs(poi, location, extent) {
        // create base geocode parameters
        const geocodeParams = ArcGISRuntimeEnvironment.createObject("GeocodeParameters");
        geocodeParams.resultAttributeNames = ["*"];
        geocodeParams.maxResults = 50;
        geocodeParams.minScore = 75.0;

        // if extent is not null, use this as the searchArea filter in the parameters
        if (extent) {
            // setup the parameters to filter by results near the preferredSearchLocation
            geocodeParams.searchArea = extent;
            geocodeParams.outputSpatialReference = extent.spatialReference;

            // execute the geocode
            locatorTask.geocodeWithParameters(poi, geocodeParams);
            return;
        }

        // if extent and location are null, do a generic geocode with no spatial filter
        if (!location) {
            locatorTask.geocodeWithParameters(poi, geocodeParams);
            return;
        }

        // check if the provided location is a Point
        if (location.x) {
            // setup the parameters to filter by results near the preferredSearchLocation
            geocodeParams.preferredSearchLocation = location;
            geocodeParams.outputSpatialReference = location.spatialReference;

            // execute the geocode with parameters
            locatorTask.geocodeWithParameters(poi, geocodeParams);
        // Check if a the location display's location should be used
        } else if (location === "Current Location") {
            geocodeParams.preferredSearchLocation = mapView.locationDisplay.location.position;
            geocodeParams.outputSpatialReference = mapView.spatialReference;

            // execute the geocode with parameters
            locatorTask.geocodeWithParameters(poi, geocodeParams);
        } else {
            // we only have the name of a location, so we must geocode to get a Point for the preferredSearchLocation
            isSearchingLocation = true;
            locatorTask.geocodeWithParameters(location, geocodeParams);
        }
    }
}
