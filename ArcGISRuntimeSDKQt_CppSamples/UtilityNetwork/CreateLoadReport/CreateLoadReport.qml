// [WriteFile Name=CreateLoadReport, Category=UtilityNetwork]
// [Legal]
// Copyright 2021 Esri.

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
import Esri.Samples 1.0

Item {
    property var phases: ["A", "AB", "ABC", "AC", "B", "BC", "C", "DeEnergized", "Unknown"]
    property var selectedPhases: ({})
    property bool reportHasRun: false

    // Declare the C++ instance which creates the scene etc. and supply the view
    CreateLoadReportSample {
        id: sampleModel
    }

    ScrollView {
        id: rectangle
        anchors.centerIn: parent
        width: children.width
        height: parent.height

        Column {
            id: contents
            padding: 20
            spacing: 10

            Row {
                ButtonGroup {
                    id: checkBoxes
                    exclusive: false
                    checkState: parentBox.checkState
                }

                GridLayout {
                    id: grid
                    rows: phases.length + 1
                    flow: GridLayout.TopToBottom

                    CheckBox { id: parentBox; checkState: checkBoxes.checkState }
                    Repeater {
                        id: phaseCheckBoxes
                        model: phases
                        CheckBox { onCheckedChanged: selectedPhases[modelData] = !selectedPhases[modelData]; ButtonGroup.group: checkBoxes }
                    }

                    Text { text: "Phase"; font.pointSize: 18; font.bold: true }
                    Repeater {
                        id: phaseLabels
                        model: phases
                        Text { text: modelData }
                    }

                    Text { text: "Total customers"; font.pointSize: 18; font.bold: true; }
                    Repeater {
                        id: phaseCustomerValues
                        model: phases
                        Text { text: modelData in sampleModel.phaseCust ? sampleModel.phaseCust[modelData].toLocaleString(Qt.locale(), "f", 0) : "NA" }
                    }

                    Text { text: "Total load"; font.bold: true; font.pointSize: 18 }
                    Repeater {
                        id: phaseLoadValues
                        model: phases
                        Text { text: modelData in sampleModel.phaseLoad ? sampleModel.phaseLoad[modelData].toLocaleString(Qt.locale(), "f", 0) : "NA" }
                    }
                }
            }

            Row {
                Button {
                    text: checkBoxes.checkState !== 0 || !reportHasRun ? "Run Report" : "Reset"

                    enabled: ((reportHasRun || checkBoxes.checkState !== 0) && sampleModel.sampleStatus === 2) ? true : false

                    onClicked: {
                        let phasesToRun = [];
                        phases.forEach((phase) => {
                                           if (selectedPhases[phase])
                                           phasesToRun.push(phase)
                                       });
                        sampleModel.runReport(phasesToRun);

                        reportHasRun = phasesToRun.length !== 0;
                    }
                }
            }

            Row {
                Text {
                    id: noticeText
                    text: {
                        switch (sampleModel.sampleStatus) {
                        case CreateLoadReportSample.SampleError: // SampleError
                            "Error initializing sample";
                            break;
                        case CreateLoadReportSample.SampleNotLoaded: // SampleNotLoaded
                            "Sample initializing...";
                            break;
                        case CreateLoadReportSample.SampleBusy: // SampleBusy
                            "Generating load report...";
                            break;
                        case CreateLoadReportSample.SampleReady: // SampleReady
                            if (checkBoxes.checkState === 0 && !reportHasRun) {
                                "Select phases to include in the load report";
                            } else {
                                "Tap the \"Run Report\" button to create the load report";
                            }
                            break;
                        default:
                            "Sample status is not defined";
                            break;
                        }
                    }
                }
            }
        }
    }
}
