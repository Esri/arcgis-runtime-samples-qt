// [WriteFile Name=AnimateImagesWithImageOverlay, Category=Scenes]
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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Esri.ArcGISRuntime 100.11
import Esri.ArcGISExtras 1.1

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    readonly property var timerIntervals: [17,34,68]
    readonly property var imageFrameRefreshRate: ["Fast","Medium","Slow"]
    readonly property url dataPath: System.userHomePath +  "/ArcGIS/Runtime/Data/3D/ImageOverlay/PacificSouthWest"
    property int fileNamesLength: 0
    property var imageFrameList: []

    // free up memory claimed by imageFrameList property
    Component.onDestruction: {
        imageFrameList = [];
    }

    // Create new Timer and set the timeout interval to 68ms
    Timer {
        id: timer
        interval: 68
        repeat: true
        property var index: 0

        // connect to the triggered signal to load and display a new image frame each time
        onTriggered: {
            // check if images are found before trying to load them
            if (fileNamesLength === 0)
                return;

            // Create new ImageFrames from images in the folder
            // Add them to a list so infinite ImageFrame objects are not created each loop
            if (imageFrameList.length !== fileNamesLength) {
                imageFrameList.push(ArcGISRuntimeEnvironment.createObject("ImageFrame", {
                                                                              url: dataPath + "/" + imageFrameFolder.fileNames()[index],
                                                                              extent: imageFrameExtent
                                                                          }));
            }

            // set image frame to image overlay
            imageOverlay.imageFrame = imageFrameList[index];

            // increment the index to keep track of which image to load next
            index++;

            // reset index once all files have been loaded
            if (index === fileNamesLength) {
                index = 0;
            }
        }
    }

    SceneView {
        id: sceneView
        anchors.fill: parent

        Scene {
            id: scene

            Surface {
                // create a new elevation source from Terrain3D REST service
                ArcGISTiledElevationSource {
                    url: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"
                }
            }

            // create a new tiled layer from World_Dark_Gray_Base REST service
            ArcGISTiledLayer {
                id: worldDarkGrayBasemap
                url: "https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer"
            }

            // set an initial viewpoint
            ViewpointExtent {
                Point {
                    id: initialViewpoint
                    x: -116.621
                    y: 24.7773
                    z: 856977
                    spatialReference: SpatialReference { wkid: 4326 }
                }

                // create a camera, looking at the pacific southwest sector
                Camera {
                    id: camera
                    location: initialViewpoint
                    heading: 353.994
                    pitch: 48.5495
                    roll: 0
                }
            }
        }

        ImageOverlay {
            id: imageOverlay
        }

        Rectangle {
            id: controlsRect
            anchors {
                bottom: sceneView.attributionTop
                horizontalCenter: parent.horizontalCenter
            }
            width: childrenRect.width
            height: childrenRect.height
            color: "lightgrey"
            opacity: 0.8
            radius: 5
            ColumnLayout {
                id: controlsLayout
                Layout.alignment: Qt.AlignBottom
                spacing: 0

                Slider {
                    id: opacitySlider
                    from: 0
                    to: 1
                    value: 1
                    Layout.preferredHeight: bottomRowControls.height
                    Layout.alignment: Qt.AlignHCenter

                    onMoved: imageOverlay.opacity = value;

                    // Custom slider handle that displays the current value
                    handle: Item {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - headingHandleNub.width)
                        y: parent.topPadding + parent.availableHeight / 2 - headingHandleNub.height / 2

                        Rectangle {
                            id: headingHandleNub
                            color: headingHandleRect.color
                            radius: width * 0.5
                            width: 20
                            height: width
                        }
                        Rectangle {
                            id: headingHandleRect
                            height: childrenRect.height
                            width: childrenRect.width
                            radius: 3
                            x: headingHandleNub.x - width / 2 + headingHandleNub.width / 2
                            y: headingHandleNub.y - height
                            color: opacitySlider.background.children[0].color

                            Text {
                                id: headingValue
                                font.pixelSize: 14
                                padding: 3
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                text: "opacity: " + (opacitySlider.value).toFixed(2)
                                color: "white"
                            }
                        }
                    }
                }

                RowLayout {
                    id: bottomRowControls
                    spacing: 2
                    Button {
                        id: startStopBtn
                        text: !timer.running ? qsTr("Start") : qsTr("Stop")
                        Layout.minimumWidth: timerIntervalComboBox.width
                        onClicked: {
                            if (!timer.running)
                                timer.start();
                            else
                                timer.stop();
                        }
                    }

                    ComboBox {
                        id: timerIntervalComboBox
                        currentIndex: 2
                        model: imageFrameRefreshRate
                        Layout.minimumWidth: startStopBtn.width

                        onActivated: timer.interval = timerIntervals[currentIndex];
                    }
                }
            }
        }
    }

    // create an envelope of the pacific southwest sector for displaying the image frame
    Envelope {
        id: imageFrameExtent
        xMin: -127.62
        xMax: -112.524
        yMin: 27.9425
        yMax: 42.3195
        spatialReference: SpatialReference { wkid: 4326 }
    }

    // Create file folder to find image file names
    FileFolder {
        id: imageFrameFolder
        url: dataPath

        Component.onCompleted: fileNamesLength = imageFrameFolder.fileNames().length;
    }
}
