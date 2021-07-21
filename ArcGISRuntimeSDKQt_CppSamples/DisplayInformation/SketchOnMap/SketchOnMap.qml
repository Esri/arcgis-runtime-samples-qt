// [WriteFile Name=SketchOnMap, Category=DisplayInformation]
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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.15
import Esri.Samples 1.0

Item {
    SketchOnMapSample {
        id: model
        mapView: view
    }

    MapView {
        id: view
        anchors.fill: parent
    }

    Control {
        id: control
        width: 110
        anchors.right: parent.right
        padding: 5

        background: Rectangle {
            color: "black"
            opacity: .5
        }

        contentItem: ColumnLayout {
            id: columns
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            GridLayout {
                id: geometryColumn
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                columns: 2

                Text {
                    id: geometryText
                    color: "#ffffff"
                    text: qsTr("Geometry")
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.bold: true
                    Layout.columnSpan: 2
                }

                RoundButton {
                    id: ptButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Image {
                        id: ptImage
                        source: "iconAssets/point-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -ptText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: ptText
                        text: qsTr("Point")
                        font.pixelSize: 8
                        anchors {
                            top: ptImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.setSketchCreationMode(0);
                }

                RoundButton {
                    id: mPtButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Image {
                        id: mptImage1
                        source: "iconAssets/point-32.png"
                        anchors {
                            right: parent.horizontalCenter
                            rightMargin: -mptImage2.width/5
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -mptText.height/2 - 2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Image {
                        id: mptImage2
                        source: "iconAssets/point-32.png"
                        anchors {
                            left: parent.horizontalCenter
                            leftMargin: -mptImage1.width/5
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -mptText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: mptText
                        text: qsTr("Multipoint")
                        font.pixelSize: 8
                        anchors {
                            top: mptImage2.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }
                    onClicked: model.setSketchCreationMode(1);
                }

                RoundButton {
                    id: lineButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Image {
                        id: lineImage
                        source: "iconAssets/line-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -lineText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: lineText
                        text: qsTr("Line")
                        font.pixelSize: 8
                        anchors {
                            top: lineImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.setSketchCreationMode(2);
                }

                RoundButton {
                    id: polygonButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Image {
                        id: polygonImage
                        source: "iconAssets/polygon-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -polygonText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: polygonText
                        text: qsTr("Polygon")
                        font.pixelSize: 8
                        anchors {
                            top: polygonImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.setSketchCreationMode(3);
                }
            }

            GridLayout {
                id: editingColumn
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                columns: 2

                Text {
                    id: editingText
                    color: "#ffffff"
                    text: qsTr("Editing")
                    font.pixelSize: 16
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.bold: true
                    Layout.columnSpan: 2
                }

                RoundButton {
                    id: undoButton
                    radius: 5
                    Layout.fillWidth: true

                    Image {
                        id: undoImage
                        source: "iconAssets/undo-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -undoText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: undoText
                        text: qsTr("Undo")
                        font.pixelSize: 8
                        anchors {
                            top: undoImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.undo();
                }

                RoundButton {
                    id: redoButton
                    radius: 5
                    Layout.fillWidth: true
                    Image {
                        id: redoImage
                        source: "iconAssets/redo-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -redoText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: redoText
                        text: qsTr("Redo")
                        font.pixelSize: 8
                        anchors {
                            top: redoImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.redo();
                }


                RoundButton {
                    id: saveEditsButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.columnSpan: 2

                    Image {
                        id: saveEditsImage
                        source: "iconAssets/check-circle-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -saveEditsText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: saveEditsText
                        text: qsTr("Save edits")
                        font.pixelSize: 8
                        anchors {
                            top: saveEditsImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.stopSketching(true);
                }

                RoundButton {
                    id: discardEditsButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.columnSpan: 2

                    Image {
                        id: discardEditsImage
                        source: "iconAssets/circle-disallowed-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -discardEditsText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: discardEditsText
                        text: qsTr("Discard edits")
                        font.pixelSize: 8
                        anchors {
                            top: discardEditsImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.stopSketching(false);
                }

                RoundButton {
                    id: clearGraphicsButton
                    radius: 5
                    Layout.fillWidth: true
                    Layout.columnSpan: 2

                    Image {
                        id: clearGraphicsImage
                        source: "iconAssets/trash-32.png"
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                            verticalCenterOffset: -clearGraphicsText.height/2
                        }
                        width: 20
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        id: clearGraphicsText
                        text: qsTr("Clear graphics")
                        font.pixelSize: 8
                        anchors {
                            top: clearGraphicsImage.bottom
                            horizontalCenter: parent.horizontalCenter
                        }
                    }

                    onClicked: model.clearGraphics();
                }
            }
        }
    }
}
