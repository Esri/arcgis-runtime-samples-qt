# Show labels on layers

Display custom labels on a feature layer.

![](screenshot.png)

## Use case

Labeling features is useful to visually display a key piece of information or attribute of a feature on a map. For example, you may want to label rivers or street with their names.

## How to use the sample

Pan and zoom around the United States. Labels for congressional districts will be shown in red for Republican districts and blue for Democrat districts. Notice how labels pop into view as you zoom in.

## How it works

To show custom labels on a feature layer:

1. Create a `FeatureLayer` and `ServiceFeatureTable` by passing in a URL to the REST endpoint of a map service.
2. Create an `ArcadeLabelExpression` for the label definition.
    * You can use fields of the feature by using `$feature.field_name` in the expression.
3. Create a `TextSymbol` to control how the label text is styled.
4. Create a `LabelDefinition` from the `ArcadeLabelExpression` and `TextSymbol`.
5. Add the `LabelDefinition` to the list of `LabelDefinitions` in the `FeatureLayer` instance.
6. Enable labels on the `FeatureLayer` by setting `labelsEnabled` to true.

## Relevant API

* ArcadeLabelExpression
* FeatureLayer
* LabelDefinition
* TextSymbol

## About the data

This sample uses the [USA 116th Congressional Districts](https://www.arcgis.com/home/item.html?id=cc6a869374434bee9fefad45e291b779) feature layer hosted on ArcGIS Online.

## Additional information

Help regarding the Arcade label expression script for defining a label definition can be found on the [ArcGIS Developers](https://developers.arcgis.com/arcade/) site.

## Tags

attribute, deconfliction, label, labeling, string, symbol, text, visualization
