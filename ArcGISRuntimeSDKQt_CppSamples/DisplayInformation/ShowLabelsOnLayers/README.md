# Show labels on layers

Display custom labels on a feature layer.

![](screenshot.png)

## Use case

Labeling features is useful to visually display a key piece of information or attribute of a feature on a map. For example, you may want to label rivers or street with their names.

## How to use the sample

Pan and zoom around the United States. Labels for congressional districts will be shown in red for Republican districts and blue for Democrat districts. Notice how labels pop into view as you zoom in.

## How it works

To show custom labels on a feature layer:

1. Create a `ServiceFeatureTable` using a feature service URL.
2. Create a `FeatureLayer` from the service feature table.
3. Create an `ArcadeLabelExpression` for the label definition.
    * You can use fields of the feature by using `$feature.field_name` in the expression.
4. Create a `TextSymbol` to control how the label text is styled.
5. Create a `LabelDefinition` by passing in the `ArcadeLabelExpression` and `TextSymbol`.
6. Add the definition to the feature layer with `featureLayer.labelDefinitions().append(labelDefinition)` .
7. Lastly, enable labels on the layer using `featureLayer.setLabelsEnabled()`.

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
