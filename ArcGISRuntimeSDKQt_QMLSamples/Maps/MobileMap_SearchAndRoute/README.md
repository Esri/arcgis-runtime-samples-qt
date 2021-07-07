# Mobile map (search and route)

Display maps and use locators to enable search and routing offline using a Mobile Map Package.

![](screenshot.png)

## Use case

Mobile map packages make it easy to transmit and store the necessary components for an offline map experience including: transportation networks (for routing/navigation), locators (address search, forward and reverse geocoding), and maps.

A field worker might download a mobile map package to support their operations while working offline.

## How to use the sample

A list of maps from a mobile map package will be displayed. If the map contains transportation networks, the list item will have a navigation icon. Click on a map in the list to open it. If a locator task is available, click on the map to place a point. Click it again to reverse geocode the location's address. If transportation networks are available, click the route icon in the top right corner a route will be calculated between geocode locations.

## How it works

1. Create a `MobileMapPackage` passing in the path to the constructor.
2. Get a list model of maps inside the package using the `maps` property.
3. If the package has a locator, access it using the `LocatorTask` property.
4. To see if a map contains transportation networks, check each map's `transportationNetworks` property.

## Relevant API

* GeocodeResult
* MobileMapPackage
* ReverseGeocodeParameters
* Route
* RouteParameters
* RouteResult
* RouteTask
* TransportationNetworkDataset

## Offline data

Read more about how to set up the sample's offline data [here](http://links.esri.com/ArcGISRuntimeQtSamples#use-offline-data-in-the-samples).

Link | Local Location
---------|-------|
|[Yellowstone mmpk File](https://www.arcgis.com/home/item.html?id=e1f3a7254cb845b09450f54937c16061)| `<userhome>`/ArcGIS/Runtime/Data/mmpk/Yellowstone.mmpk |
|[SanFrancisco mmpk File](https://www.arcgis.com/home/item.html?id=260eb6535c824209964cf281766ebe43)| `<userhome>`/ArcGIS/Runtime/Data/mmpk/SanFrancisco.mmpk |

## Tags

disconnected, field mobility, geocode, network, network analysis, offline, routing, search, transportation
