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
import Esri.ArcGISRuntime 100.11
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
    property var phaseCodedValuesList: null
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

    property bool reportHasRun: false

    property var phaseNames: ["A", "AB", "ABC", "AC", "B", "BC", "C", "DeEnergized", "Unknown"]
    property var phaseQueue: []
    property var currentPhase: null
    property var selectedPhases: ({})
    property var phaseCust: ({})
    property var phaseLoad: ({})


    property var sampleStatus: CreateLoadReport.SampleStatus.NotLoaded
    enum SampleStatus {
        Error,
        NotLoaded,
        Busy,
        Ready
    }

    UtilityNetwork {
        id: utilityNetwork
        url: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer"

        credential: Credential {
            username: "viewer01"
            password: "I68VGU^nMurF"
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
                sampleStatus = CreateLoadReport.SampleStatus.Ready;
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

                phaseCust[currentPhase.name] = customers;
                phaseLoad[currentPhase.name] = load;
                phaseCustChanged();
                phaseLoadChanged();

                if (phaseQueue.length > 0) {
                    currentPhase = phaseQueue.pop();
                    createReportForPhase(currentPhase);
                } else {
                    sampleStatus = CreateLoadReport.SampleStatus.Ready;
                    reportHasRun = true;
                }
            }
        }

        onErrorChanged: {
            sampleStatus = CreateLoadReport.SampleStatus.Error;
        }
    }

    UtilityCategoryComparison {
        // Create a comparison to check the existence of service points.
        id: serviceCategoryComparison
        comparisonOperator: Enums.UtilityCategoryComparisonOperatorExists

        // Service Category for counting total customers
        function setServiceCategoryComparison() {
            const utilityCategories = utilityNetwork.definition.categories;
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
        const traceConfig = utilityTier.traceConfiguration;
        traceConfig.domainNetwork = utilityNetwork.definition.domainNetwork(domainNetworkName);

        serviceCategoryComparison.setServiceCategoryComparison();
        traceConfig.outputCondition = serviceCategoryComparison;

        // The load attribute for counting total load.
        addLoadAttributeFunction.networkAttribute = utilityNetwork.definition.networkAttribute(loadNetworkAttributeName);
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
            let codedValues = [];
            for (let i = 0; i < phasesCurrentAttr.domain.codedValues.length; i++) {
                codedValues.push(phasesCurrentAttr.domain.codedValues[i]);
            }

            return codedValues;
        }
    }

    function createReportForPhase(phase) {
        const condExpr = ArcGISRuntimeEnvironment.createObject("UtilityNetworkAttributeComparison", {
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
                    rows: phaseNames.length + 1
                    flow: GridLayout.TopToBottom

                    CheckBox { id: parentBox; checkState: checkBoxes.checkState }
                    Repeater {
                        id: phaseCheckBoxes
                        model: phaseNames
                        CheckBox { onCheckedChanged: selectedPhases[modelData] = !selectedPhases[modelData]; ButtonGroup.group: checkBoxes }
                    }

                    Text { text: "Phase"; font.pointSize: 18; font.bold: true }
                    Repeater {
                        id: phaseLabels
                        model: phaseNames
                        Text { text: modelData }
                    }

                    Text { text: "Total customers"; font.pointSize: 18; font.bold: true; }
                    Repeater {
                        id: phaseCustomerValues
                        model: phaseNames
                        Text { text: modelData in phaseCust ? phaseCust[modelData].toLocaleString(Qt.locale(), "f", 0) : "NA" }
                    }

                    Text { text: "Total load"; font.bold: true; font.pointSize: 18 }
                    Repeater {
                        id: phaseLoadValues
                        model: phaseNames
                        Text { text: modelData in phaseLoad ? phaseLoad[modelData].toLocaleString(Qt.locale(), "f", 0) : "NA" }
                    }
                }
            }

            Row {
                Button {
                    text: checkBoxes.checkState !== 0 || !reportHasRun ? "Run Report" : "Reset"

                    enabled: ((reportHasRun || checkBoxes.checkState !== 0) && sampleStatus === CreateLoadReport.SampleStatus.Ready) ? true : false

                    onClicked: {
                        phaseCust = {};
                        phaseLoad = {};
                        let runPhases = [];
                        phaseNames.forEach((phase) => {
                                               if (selectedPhases[phase])
                                                   runPhases.push(phase)
                                           });

                        if (runPhases.length > 0) {
                            phaseCodedValuesList.forEach(codedValue => {
                                                             if (runPhases.includes(codedValue.name))
                                                                 phaseQueue.push(codedValue);
                                                         });

                            if (phaseQueue.length > 0) {
                                sampleStatus = CreateLoadReport.SampleStatus.Busy;
                                currentPhase = phaseQueue.pop();
                                createReportForPhase(currentPhase);
                            }
                        }

                        reportHasRun = runPhases.length !== 0;
                    }
                }
            }

            Row {
                Text {
                    id: noticeText
                    text: {
                        switch (sampleStatus) {
                        case CreateLoadReport.SampleStatus.Error:
                            "The sample encountered an error:\n"+utilityNetwork.error.message+"\n"+utilityNetwork.error.additionalMessage;
                            break;

                        case CreateLoadReport.SampleStatus.NotLoaded:
                            "Sample initializing...";
                            break;

                        case CreateLoadReport.SampleStatus.Busy:
                            "Generating load report...";
                            break;

                        case CreateLoadReport.SampleStatus.Ready:
                            if (checkBoxes.checkState === 0 && !reportHasRun) {
                                "Select phases to include in the load report";
                            } else if (checkBoxes.checkState === 0 && reportHasRun) {
                                "Tap the \"Reset\" button to reset the load report";
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
