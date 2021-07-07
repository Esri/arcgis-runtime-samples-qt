# Create load report

Create a simple electric distribution report that displays the count of customers and total load per phase by tracing downstream from a given point.

![](screenshot.png)

## Use case

You can use a load report to display the customers per phase as well as the load per phase based on a chosen starting point in a utility network. Load reports are used for electric load restoration and balancing.

## How to use the sample

Select phases to be included in the report. Press the "Run Report" button to initiate a downstream trace on the network and create a load report. Pressing "Run Report" again will generate a new load report. Deselect all phases and press the "Reset" button to clear the report.

## How it works

1. Create and load a `UtilityNetwork` with a feature service URL and credentials, then get an asset type and tier by their names when the utility network has loaded.
2. Create a `UtilityElement` from the asset type to use as the starting location for the trace.
3. Create a `UtilityTraceConfiguration` from the utility tier.
4. Create a `UtilityCategoryComparison` where "ServicePoint" category exists.
5. Reset the `functions` property of the trace configuration with a new `UtilityTraceFunction` adding a "Service Load" network attribute where this category comparison applies. This will limit the function results.
6. Set `outputCondition` with the category comparison to limit the element results.
7. Get a base condition from the utility tier's trace configuration.
8. Create `UtilityTraceParameters` passing in `downstream` utility trace type and the default starting location. Set its `traceConfiguration` property with the trace configuration above.
9. Populate a list of phases using the network attribute's `codedValues` property.
10. When the "Run Report" button is tapped, run a trace for every checked `CodedValue` in the phases list. Do this by creating a `UtilityTraceOrCondition` with the base condition and a `UtilityNetworkAttributeComparison` where the "Phases Current" network attribute does not include the coded value.
11. Display the count of "Total Customers" using the `elements` property of the result, and the result of "Total Load" using the first and only output in `functionOutputs` property.

## Relevant API

* UtilityAssetType
* UtilityCategoryComparison
* UtilityDomainNetwork
* UtilityElement
* UtilityElementTraceResult
* UtilityNetwork
* UtilityNetworkAttribute
* UtilityNetworkAttributeComparison
* UtilityNetworkDefinition
* UtilityNetworkSource
* UtilityTerminal
* UtilityTier
* UtilityTraceConfiguration
* UtilityTraceFunction
* UtilityTraceParameters
* UtilityTraceResult
* UtilityTraceType
* UtilityTraversability

## About the data

The [Naperville electrical](https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer) network feature service, hosted on ArcGIS Online, contains a utility network used to run the subnetwork-based trace shown in this sample.

## Additional information

Using utility network on ArcGIS Enterprise 10.8 requires an ArcGIS Enterprise member account licensed with the [Utility Network user type extension](https://enterprise.arcgis.com/en/portal/latest/administer/windows/license-user-type-extensions.htm#ESRI_SECTION1_41D78AD9691B42E0A8C227C113C0C0BF). Please refer to the [utility network services documentation](https://enterprise.arcgis.com/en/server/latest/publish-services/windows/utility-network-services.htm).

## Tags

condition barriers, downstream trace, network analysis, subnetwork trace, trace configuration, traversability, upstream trace, utility network, validate consistency
