# Display layer view draw state

Determine if a layer is currently being viewed.

![](screenshot.png)

## Use case

The view status includes information on the loading state of layers and whether layers are visible at a given scale. You might change how a layer is displayed in a layer list to communicate whether it is being viewed in the map. For example, you could show a loading spinner next to its name when the view status is Loading, grey out the name when NotVisible or OutOfScale, show the name normally when Active, or with a warning or error icon when the status is Warning or Error.

## How to use the sample

Tap the *Load layer* button to add a feature layer to the map. The current view status of the layer will display on the map. Zoom in and out of the map and note the layer disappears when the map is scaled outside of its min and max scale range. Control the layer's visibility with the *Hide layer* button. If you disconnect your device from the network and pan around the map, a warning will display. Reconnect to the network to remove the warning. The layer's current view status will update accordingly as you carry out these actions.

## How it works

1. Create a `Map` with some operational layers.
2. Set the map on a `MapView`.
3. Connect to the `layerViewStateChanged` signal from the map view.
4. Display the `LayerViewStatus` flag for the `FeatureLayer`.

## Relevant API

* Enums.LayerViewStatus
* LayerViewState
* Map
* MapView
* MapView.layerViewStateChanged

## About the data

The [Satellite (MODIS) Thermal Hotspots and Fire Activity](https://runtime.maps.arcgis.com/home/item.html?id=b8f4033069f141729ffb298b7418b653) layer presents detectable thermal activity from MODIS satellites for the last 48 hours. [MODIS Global Fires](https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/active-fire-data) is a product of NASA’s [Earth Observing System Data and Information System (EOSDIS)](https://earthdata.nasa.gov/about), part of NASA's [Earth Science Data](https://science.nasa.gov/earth-science/earth-data/). EOSDIS integrates remote sensing and GIS technologies to deliver global MODIS hotspot/fire locations to natural resource managers and other stakeholders around the World.

## Additional information

The following are members of the `LayerViewStatus` enum:

* `Enums.LayerViewStatusActive`: The layer in the view is active.
* `Enums.LayerViewStatusNotVisible`: The layer in the view is not visible.
* `Enums.LayerViewStatusOutOfScale`: The layer in the view is out of scale. A status of `Enums.LayerViewStatusOutOfScale` indicates that the view is zoomed outside of the scale range of the layer. If the view is zoomed too far in (e.g. to a street level), it is beyond the max scale defined for the layer. If the view has zoomed too far out (e.g. to global scale), it is beyond the min scale defined for the layer.
* `Enums.LayerViewStatusLoading`: The layer in the view is loading. Once loading has completed, the layer will be available for display in the view. If there was a problem loading the layer, the status will be set to ERROR.
* `Enums.LayerViewStatusError`: The layer in the view has an unrecoverable error. When the status is `Enums.LayerViewStatusError`, the layer cannot be rendered in the view. For example, it may have failed to load, be an unsupported layer type, or contain invalid data.
* `Enums.LayerViewStatusWarning`: The layer in the view has a non-breaking problem with its display, such as incomplete information (eg. by requesting more features than the max feature count of a service) or a network request failure.

If your device supports airplane mode, you can toggle this on and pan around the map to see layers display the WARNING status when they cannot online fetch data. Toggle airplane mode back off to see the warning disappear.

## Tags

layer, load, map, status, view, visibility
