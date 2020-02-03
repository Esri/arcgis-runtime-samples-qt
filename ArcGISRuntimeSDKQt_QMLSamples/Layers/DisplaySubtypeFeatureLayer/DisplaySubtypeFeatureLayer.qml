// [WriteFile Name=DisplaySubtypeFeatureLayer, Category=Layers]
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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.12
import Esri.ArcGISRuntime 100.8

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    readonly property var labelJson: { "labelExpression": "[nominalvoltage]", "labelPlacement": "esriServerPointLabelPlacementAboveRight", "useCodedValues": true, "symbol": { "angle": 0, "backgroundColor": [ 0, 0, 0, 0 ], "borderLineColor": [ 0, 0, 0, 0 ], "borderLineSize": 0, "color": [ 0, 0, 255, 255 ], "font": { "decoration": "none", "size": 10.5, "style": "normal", "weight": "normal" }, "haloColor": [ 255, 255, 255, 255 ], "haloSize": 2, "horizontalAlignment": "center", "kerning": false, "type": "esriTS", "verticalAlignment": "middle", "xoffset": 0, "yoffset": 0 } }
    property var subtypeSublayer
    property var originalRenderer
    property var mapScale: mapView ? Math.round(mapView.mapScale) : 0
    property var sublayerMinScale


    MapView {
        id: mapView
        anchors.fill: parent

        Map {
            BasemapStreetsNightVector {}

            // create the feature layer
            SubtypeFeatureLayer  {
                id: subtypeFeatureLayer

                // feature table
                ServiceFeatureTable {
                    id: featureTable
                    url: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/100"
                }

                onLoadStatusChanged: {
                    if (loadStatus != Enums.LoadStatusLoaded)
                        return;

                    subtypeSublayer = subtypeFeatureLayer.sublayerWithSubtypeName("Street Light");

                    var labelDefinition = ArcGISRuntimeEnvironment.createObject("LabelDefinition", { json : labelJson});
                    subtypeSublayer.labelDefinitions.append(labelDefinition);
                    originalRenderer = subtypeSublayer.renderer;
                    subtypeSublayer.labelsEnabled = true;
                    subtypeSublayer.minScale = 3000.0;
                    sublayerMinScale = subtypeSublayer.minScale;
                }

                onErrorChanged: print("%1 - %2 - %3 - %4".arg(error.code, error.domain, error.message, error.additionalMessage));
            }

            ViewpointExtent {
                extent: Envelope {
                    xMin: -9812691.11079696
                    yMin: 5128687.20710657
                    xMax: -9812377.9447607
                    yMax: 5128865.36767282
                }
            }
        }

        SimpleRenderer {
            id: alternativeRenderer
            SimpleMarkerSymbol {
                style: Enums.SimpleMarkerSymbolStyleDiamond
                color: "#fff58f84"
                size: 20
            }
        }

        Rectangle {
            id: controlsBox
            anchors {
                left: parent.left
                top: parent.top
                margins: 3
            }
            width: childrenRect.width
            height: childrenRect.height
            color: "lightgrey"
            opacity: 0.8
            radius: 5

            // catch mouse signals from propagating to parent
            MouseArea {
                anchors.fill: parent
                onClicked: mouse.accepted = true
                onWheel: wheel.accepted = true
            }

            ColumnLayout {
                id: controlItemsLayout

                CheckBox {
                    text: qsTr("Show sublayer")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    checked: true
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onCheckedChanged: switchSublayerVisibility();
                }

                RadioButton {
                    text: qsTr("Show original rednerer")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    checked: true
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onCheckedChanged: {
                        if (checked)
                            setOringalRenderer();
                    }
                }

                RadioButton {
                    text: qsTr("Show alternative renderer")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onCheckedChanged: {
                        if (checked)
                            setAlternativeRenderer();
                    }
                }

                Shape {
                    id: pageBreak
                    height: 2
                    ShapePath {
                        strokeWidth: 1
                        strokeColor: "black"
                        strokeStyle: ShapePath.SolidLine
                        startX: 2; startY: 0
                        PathLine { x: controlItemsLayout.width - 2 ; y: 0 }
                    }
                }

                Text {
                    text: qsTr("Current map scale: 1:%1".arg(mapScale))
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                }

                Text {
                    text: qsTr("Sublayer min scale: %1".arg(sublayerMinScale ? sublayerMinScale : "not set"))
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                }

                Button {
                    text: qsTr("Set sublayer minimum scale")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onClicked: setSublayerMinScale();
                }
            }
        }

        BusyIndicator {
            id: busy
            anchors.centerIn: parent
            visible: subtypeFeatureLayer.loadStatus !== Enums.LoadStatusLoaded ? true : false
        }
    }

    function switchSublayerVisibility() {
        print("switchSublayerVisibility");
        subtypeSublayer.visible = !subtypeSublayer.visible;
    }

    function setOringalRenderer() {
        print("set original renderer");
        subtypeSublayer.renderer = originalRenderer;
    }

    function setAlternativeRenderer() {
        print("set alternative renderer");
        subtypeSublayer.renderer = alternativeRenderer;
    }

    function setSublayerMinScale() {
        print("set sublayer min scale");
        subtypeSublayer.minScale = mapView.mapScale;
        sublayerMinScale = subtypeSublayer.minScale;
    }
}
