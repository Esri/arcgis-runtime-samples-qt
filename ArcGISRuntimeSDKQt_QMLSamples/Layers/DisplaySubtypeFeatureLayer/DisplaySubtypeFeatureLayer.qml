// [WriteFile Name=DisplaySubtypeFeatureLayer, Category=Layers]
// [Legal]
// Copyright 2020 Esri.

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
import Esri.ArcGISRuntime 100.11

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property var subtypeSublayer
    property var originalRenderer
    property double mapScale: mapView ? Math.round(mapView.mapScale) : 0
    property double sublayerMinScale


    MapView {
        id: mapView
        anchors.fill: parent

        Map {
            Basemap {
                initStyle: Enums.BasemapStyleArcGISStreetsNight
            }

            // create the feature layer
            SubtypeFeatureLayer  {
                id: subtypeFeatureLayer

                // feature table
                ServiceFeatureTable {
                    id: featureTable
                    url: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/0"

                    Credential {
                        username: "viewer01"
                        password: "I68VGU^nMurF"
                    }
                }

                LabelDefinition {
                    id: subtypeSublayerLabelDefinition

                    placement: Enums.LabelingPlacementPointAboveRight
                    useCodedValues: true

                    expression: SimpleLabelExpression {
                        expression: "[nominalvoltage]"
                    }

                    textSymbol: TextSymbol {
                        size: 14
                        color: "blue"
                        haloColor: "white"
                        haloWidth: 3
                        horizontalAlignment: Enums.HorizontalAlignmentCenter
                        verticalAlignment: Enums.VerticalAlignmentMiddle
                    }
                }

                onLoadStatusChanged: {
                    if (loadStatus != Enums.LoadStatusLoaded)
                        return;

                    // get the Street Light sublayer and define its labels
                    subtypeSublayer = subtypeFeatureLayer.sublayerWithSubtypeName("Street Light");

                    if (!subtypeSublayer)
                        return;

                    subtypeSublayer.labelDefinitions.append(subtypeSublayerLabelDefinition);
                    subtypeSublayer.labelsEnabled = true;

                    // get the original renderer of the sublayer
                    originalRenderer = subtypeSublayer.renderer;

                    // set a default minimum scale
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
                color: "magenta"
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
                    onCheckedChanged: subtypeSublayer ? subtypeSublayer.visible = !subtypeSublayer.visible : null
                }

                RadioButton {
                    text: qsTr("Show original renderer")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    checked: true
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onCheckedChanged: {
                        if (checked && subtypeSublayer)
                            subtypeSublayer.renderer = originalRenderer;
                    }
                }

                RadioButton {
                    text: qsTr("Show alternative renderer")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onCheckedChanged: {
                        if (checked && subtypeSublayer)
                            subtypeSublayer.renderer = alternativeRenderer;
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
                    text: subtypeSublayer ? qsTr("Sublayer min scale: 1:%1".arg(subtypeSublayer.minScale)) : qsTr("Sublayer min scale:")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                }

                Button {
                    text: qsTr("Set sublayer minimum scale")
                    Layout.margins: 2
                    Layout.alignment: Qt.AlignLeft
                    enabled: subtypeFeatureLayer.loadStatus === Enums.LoadStatusLoaded ? true : false
                    onClicked: subtypeSublayer ? subtypeSublayer.minScale = mapScale : null
                }
            }
        }

        BusyIndicator {
            id: busy
            anchors.centerIn: parent
            visible: subtypeFeatureLayer.loadStatus !== Enums.LoadStatusLoaded ? true : false
        }
    }
}
