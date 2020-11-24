// [WriteFile Name=PerformValveIsolationTrace, Category=UtilityNetwork]
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

import QtQuick 2.0
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12

Dialog {
    id: terminalPickerView
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    ColumnLayout {
        Text {
            text: qsTr("Select the terminal for this junction.")
            Layout.alignment: Qt.AlignHCenter
        }

        ComboBox {
            id: terminalSelection
            model: sampleModel.terminals
            Layout.alignment: Qt.AlignHCenter
        }
    }

    onAccepted: sampleModel.selectedTerminal(terminalSelection.currentIndex);
}
