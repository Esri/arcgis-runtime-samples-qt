# Service feature table (cache)

Display a feature layer from a service using the **on interaction cache** feature request mode.

![](screenshot.png)

## Use case

`ServiceFeatureTable` supports three request modes, which define how features are requested from the service and stored in the local table. The feature request modes have different performance characteristics. Use **On interaction cache** in scenarios with large amounts of infrequently edited data.

## How to use the sample

Run the sample and pan and zoom around the map. With each interaction, features will be requested and stored in a local cache. Each subsequent interaction will display features from the cache and only request new features from the service.

## How it works
1. Create a `ServiceFeatureTable` with the provided URL.
2. Since the default request mode is `FeatureRequestMode::OnInteractionCache` we do not need to change it.
3. Add the table to the map using a `FeatureLayer`.

## Relevant API

* FeatureLayer
* FeatureRequestMode::OnInteractionCache
* ServiceFeatureTable
* ServiceFeatureTable::setFeatureRequestMode

## About the data

This sample displays a [Pool permit](https://sampleserver6.arcgisonline.com/arcgis/rest/services/PoolPermits/FeatureServer/0) feature layer in Riverside, California, displaying which parcels do not have pool permits.

## Additional information

**On interaction cache** is the default feature request mode. Features are requested automatically for the visible extent as the users pans and zooms the map. If the user returns to an area where features have previously been requested, those features won't be requested again.

## Tags

cache, feature request mode, performance
