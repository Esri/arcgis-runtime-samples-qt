// [WriteFile Name=IdentifyKmlFeatures, Category=Layers]
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
import Esri.Samples 1.0
import Esri.ArcGISRuntime.Toolkit 100.11

Item {

    // add a mapView component
    MapView {
        id: view
        anchors.fill: parent

        Callout {
            id: callout
            calloutData: view.calloutData
            autoAdjustWidth: false
            calloutWidth: 300
            accessoryButtonHidden: true
            leaderPosition: leaderPositionEnum.Top
            calloutContent: customComponent
        }

        Component {
            id: customComponent

            Text {
                text: model.calloutText

                Binding {
                    target: callout
                    value: contentHeight + callout.calloutFramePadding
                    property: "calloutHeight"
                }

                wrapMode: Text.WordWrap
                textFormat: Text.RichText
            }
        }
    }

    // Declare the C++ instance which creates the scene etc. and supply the view
    IdentifyKmlFeaturesSample {
        id: model
        mapView: view
    }
}
