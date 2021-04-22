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
import Esri.ArcGISRuntime 100.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

Rectangle {
    id: rootRectangle
    clip: true
    width: 800
    height: 600

    property var utilityAssetType: null
    property var utilityTier: null
    property var startingLocation: null
    property var phasesCurrentAttr: null
    property var phaseCodedValuesList: []
    property var baseCondition: null

    property var networkSourceName: "Electric Distribution Device"
    property var assetGroupName: "Circuit Breaker"
    property var assetTypeName: "Three Phase"
    property var terminalName: "Load"
    property var globalId: "{1CAF7740-0BF4-4113-8DB2-654E18800028}"
    property var domainNetworkName: "ElectricDistribution"
    property var tierName: "Medium Voltage Radial"
    property var serviceCategoryName: "ServicePoint"
    property var loadNetworkAttributeName: "Service Load"
    property var phasesNetworkAttributeName: "Phases Current"
    property var sampleStatus: 0

    property bool reportHasRun: false

    property var phases: ["A", "AB", "ABC", "AC", "B", "BC", "C", "DeEnergized", "Unknown"]
    property var phaseQueue: []
    property var currentPhase: null

    property var checkedPhases: {
        "A": false,
        "AB": false,
        "ABC": false,
        "AC": false,
        "BC": false,
        "B": false,
        "C": false,
        "DeEnergized": false,
        "Unknown": false
    }

    UtilityNetwork {
        id: utilityNetwork
        url: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer"

        credential: Credential {
            username: "editor01"
            password: "S7#i2LWmYH75"
        }

        Component.onCompleted: {
            utilityNetwork.load();
        }

        onLoadStatusChanged: {
            if (utilityNetwork.loadStatus === Enums.LoadStatusLoaded) {
                utilityAssetType = createUtilityAssetType();
                utilityTier = createUtilityTier();

                // Create a UtilityElement from the UtilityAssetType to use as the starting location
                startingLocation = createStartingLocation();

                // Get a default trace configuration from a tier in the network.
                traceParams.traceConfiguration = createTraceConfiguration();

                // Create a base condition to compare against
                baseCondition = traceParams.traceConfiguration.traversability.barriers;

                // Create a list of possible phases from a given network attribute
                phaseCodedValuesList = createCodedValuesPhaseList();
                sampleStatus = 2;
            }
        }

        onTraceStatusChanged: {
            if (traceStatus === Enums.TaskStatusCompleted) {
                let customers = 0;
                let load = 0;

                traceResult.forEach(result => {
                                        if (result.objectType === "UtilityElementTraceResult")
                                            customers = result.elements.length;

                                        else if (result.objectType === "UtilityFunctionTraceResult")
                                            load = result.functionOutputs[0].result;
                                    });

                setGridText(currentPhase.name, customers, load);

                if (phaseQueue.length > 0) {
                    currentPhase = phaseQueue.pop();
                    createReportForPhase(currentPhase);
                } else {
                    sampleStatus = 2;
                    reportHasRun = true;
                }
            }
        }

        onErrorChanged: {
            sampleStatus = -1;
        }
    }

    UtilityCategoryComparison {
        // Create a comparison to check the existence of service points.
        id: serviceCategoryComparison
        comparisonOperator: Enums.UtilityCategoryComparisonOperatorExists

        // Service Category for counting total customers
        function setServiceCategoryComparison() {
            let utilityCategories = utilityNetwork.definition.categories;
            for (let i = 0; i < utilityCategories.length; i++) {
                if (utilityCategories[i].name === serviceCategoryName) {
                    serviceCategoryComparison.category = utilityCategories[i];
                    break;
                }
            }
        }
    }

    UtilityTraceFunction {
        id: addLoadAttributeFunction
        functionType: Enums.UtilityTraceFunctionTypeAdd
        condition: serviceCategoryComparison

        function setNetworkAttribute() {
            // The load attribute for counting total load.
            addLoadAttributeFunction.networkAttribute = utilityNetwork.definition.networkAttribute(loadNetworkAttributeName);
        }
    }

    UtilityTraceParameters {
        id: traceParams
        traceType: Enums.UtilityTraceTypeDownstream
        startingLocations: [startingLocation]

        Component.onCompleted: {
            traceParams.resultTypes = [Enums.UtilityTraceResultTypeElements, Enums.UtilityTraceResultTypeFunctionOutputs]
        }
    }

    function createUtilityAssetType() {
        const networkDefinition = utilityNetwork.definition;
        const networkSource = networkDefinition.networkSource(networkSourceName);
        const assetGroup = networkSource.assetGroup(assetGroupName);
        return assetGroup.assetType(assetTypeName);
    }

    function createUtilityTier() {
        const networkDefinition = utilityNetwork.definition;
        const domainNetwork = networkDefinition.domainNetwork(domainNetworkName);
        return domainNetwork.tier(tierName);
    }

    function createStartingLocation() {
        let loadTerminal;

        // Get the terminal for the location. (For our case, use the "Load" terminal.)
        const utilityTerminals = utilityAssetType.terminalConfiguration.terminals;

        for (let i = 0; i < utilityTerminals.length; i++) {
            if (utilityTerminals[i].name === terminalName) {
                loadTerminal = utilityTerminals[i];
                break;
            }
        }

        if (!loadTerminal)
            return;

        return utilityNetwork.createElementWithAssetType(utilityAssetType, globalId, loadTerminal);
    }

    function createTraceConfiguration() {
        let traceConfig = utilityTier.traceConfiguration;
        traceConfig.domainNetwork = utilityNetwork.definition.domainNetwork(domainNetworkName);

        serviceCategoryComparison.setServiceCategoryComparison();
        traceConfig.outputCondition = serviceCategoryComparison;

        addLoadAttributeFunction.setNetworkAttribute();
        traceConfig.functions.clear();
        traceConfig.functions.append(addLoadAttributeFunction);

        // Set to false to ensure that service points with incorrect phasing
        // (which therefore act as barriers) are not counted with results.
        traceConfig.includeBarriers = false;
        return traceConfig;
    }

    function createCodedValuesPhaseList() {
        phasesCurrentAttr = utilityNetwork.definition.networkAttribute(phasesNetworkAttributeName);

        if (phasesCurrentAttr.domain.domainType === Enums.DomainTypeCodedValueDomain) {
            return phasesCurrentAttr.domain.codedValues;
        }
    }

    function runReport(selectedPhases) {
        for (let i = 0; i < phaseCodedValuesList.length; i++) {
            if (selectedPhases.includes(phaseCodedValuesList[i].name)) {
                phaseQueue.push(phaseCodedValuesList[i]);
            }
        }

        if (phaseQueue.length > 0) {
            sampleStatus = 1;
            currentPhase = phaseQueue.pop();
            createReportForPhase(currentPhase);
        }
    }

    function createReportForPhase(phase) {
        let condExpr = ArcGISRuntimeEnvironment.createObject("UtilityNetworkAttributeComparison", {
                                                                 networkAttribute: phasesCurrentAttr,
                                                                 comparisonOperator: Enums.UtilityAttributeComparisonOperatorDoesNotIncludeAny,
                                                                 value: phase.code
                                                             });

        const traceOrCondition = ArcGISRuntimeEnvironment.createObject("UtilityTraceOrCondition", {
                                                                     leftExpression: baseCondition,
                                                                     rightExpression: condExpr
                                                                 });

        traceParams.traceConfiguration.traversability.barriers = traceOrCondition;
        utilityNetwork.trace(traceParams);
    }

    // Load Report UI

    Rectangle {
        id: rectangle
        color: "white"
        width: grid.width
        height: contents.height
        anchors {
            horizontalCenter: parent.horizontalCenter

        }

        ButtonGroup {
            id: checkBoxes
            exclusive: false
            checkState: parentBox.checkState
        }

        Column {

            id: contents
            anchors.fill: parent
            padding: 10
            spacing: 25

            Row {

                GridLayout {
                    id: grid
                    columns: 4
                    rowSpacing: 5

                    CheckBox { id: parentBox; checkState: checkBoxes.checkState }
                    Text { text: "Phase"; font.pointSize: 18; font.bold: true }
                    Text { text: "Total customers"; font.pointSize: 18; font.bold: true; }
                    Text { text: "Total load"; font.bold: true; font.pointSize: 18 }

                    CheckBox { id: checkA; onCheckedChanged: checkedPhases["A"] = !checkedPhases["A"]; ButtonGroup.group: checkBoxes }
                    Text { text: "A" }
                    Text { id: custTextA }
                    Text { id: loadTextA }

                    CheckBox { id: checkAB; onCheckedChanged: checkedPhases["AB"] = !checkedPhases["AB"]; ButtonGroup.group: checkBoxes }
                    Text { text: "AB" }
                    Text { id: custTextAB }
                    Text { id: loadTextAB }

                    CheckBox { id: checkABC; onCheckedChanged: checkedPhases["ABC"] = !checkedPhases["ABC"]; ButtonGroup.group: checkBoxes }
                    Text { text: "ABC" }
                    Text { id: custTextABC }
                    Text { id: loadTextABC }

                    CheckBox { id: checkAC; onCheckedChanged: checkedPhases["AC"] = !checkedPhases["AC"]; ButtonGroup.group: checkBoxes }
                    Text { text: "AC" }
                    Text { id: custTextAC }
                    Text { id: loadTextAC }

                    CheckBox { id: checkB; onCheckedChanged: checkedPhases["B"] = !checkedPhases["B"]; ButtonGroup.group: checkBoxes }
                    Text { text: "B" }
                    Text { id: custTextB }
                    Text { id: loadTextB }

                    CheckBox { id: checkBC; onCheckedChanged: checkedPhases["BC"] = !checkedPhases["BC"]; ButtonGroup.group: checkBoxes }
                    Text { text: "BC" }
                    Text { id: custTextBC }
                    Text { id: loadTextBC }

                    CheckBox { id: checkC; onCheckedChanged: checkedPhases["C"] = !checkedPhases["C"]; ButtonGroup.group: checkBoxes }
                    Text { text: "C" }
                    Text { id: custTextC }
                    Text { id: loadTextC }

                    CheckBox { id: checkDeEnergized; onCheckedChanged: checkedPhases["DeEnergized"] = !checkedPhases["DeEnergized"]; ButtonGroup.group: checkBoxes }
                    Text { text: "DeEnergized" }
                    Text { id: custTextDE }
                    Text { id: loadTextDE }

                    CheckBox { id: checkUnknown; onCheckedChanged: checkedPhases["Unknown"] = !checkedPhases["Unknown"]; ButtonGroup.group: checkBoxes }
                    Text { text: "Unknown" }
                    Text { id: custTextU }
                    Text { id: loadTextU }
                }
                Component.onCompleted: {
                    resetGrid();
                }
            }

            Row {
                Button {
                    text: {
                        if (checkBoxes.checkState !== 0 || !reportHasRun) {
                            "Run Report";
                        } else {
                            "Reset";
                        }
                    }

                    enabled: ((reportHasRun || checkBoxes.checkState !== 0) && sampleStatus === 2) ? true : false

                    onClicked: {
                        resetGrid();
                        let runPhases = [];
                        phases.forEach((phase) => {
                                           if (checkedPhases[phase])
                                           runPhases.push(phase)
                                       });

                        runReport(runPhases);

                        if (runPhases.length === 0) {
                            reportHasRun = false;
                        } else {
                            reportHasRun = true;
                        }
                    }
                }
            }

            Row {
                Text {
                    id: noticeText
                    text: {
                        switch (sampleStatus) {
                        case -1:
                            "The sample encountered an error:\n"+utilityNetwork.error.message+"\n"+utilityNetwork.error.additionalMessage;
                            break;
                        case 0:
                            "Sample initializing...";
                            break;
                        case 1:
                            "Generating load report...";
                            break;
                        case 2:
                            if (checkBoxes.checkState === 0 && !reportHasRun) {
                                "Select phases to run the load report with";
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

    // UI Functions

    function resetGrid() {
        custTextA.text = "NA"
        loadTextA.text = "NA"

        custTextAB.text = "NA"
        loadTextAB.text = "NA"

        custTextABC.text = "NA"
        loadTextABC.text = "NA"

        custTextAC.text = "NA"
        loadTextAC.text = "NA"

        custTextB.text = "NA"
        loadTextB.text = "NA"

        custTextBC.text = "NA"
        loadTextBC.text = "NA"

        custTextC.text = "NA"
        loadTextC.text = "NA"

        custTextDE.text = "NA"
        loadTextDE.text = "NA"

        custTextU.text = "NA"
        loadTextU.text = "NA"
    }

    function setGridText(phaseName, customers, load) {
        switch (phaseName) {
        case "A":
            custTextA.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextA.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "AB":
            custTextAB.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextAB.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "ABC":
            custTextABC.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextABC.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "AC":
            custTextAC.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextAC.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "B":
            custTextB.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextB.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "BC":
            custTextBC.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextBC.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "C":
            custTextC.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextC.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "DeEnergized":
            custTextDE.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextDE.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        case "Unknown":
            custTextU.text = customers.toLocaleString(Qt.locale(), "f", 0);
            loadTextU.text = load.toLocaleString(Qt.locale(), "f", 0);
            break;

        default:
            break;
        }
    }
}