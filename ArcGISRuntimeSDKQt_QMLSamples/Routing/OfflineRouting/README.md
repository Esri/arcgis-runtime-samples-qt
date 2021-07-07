# Offline routing

This sample demonstrates how to solve a route on-the-fly using offline data.

![](screenshot.png)

## Use case

You can use an offline network to enable routing in disconnected scenarios. For example, you could provide offline location capabilities to field workers repairing critical infrastructure in a disaster when network availability is limited.

## How to use the sample

Click near a road to start adding a stop to the route, click again to place it on the map. A number graphic will show its order in the route. After adding at least 2 stops, a route will display. Choose "Fastest" or "Shortest" to control how the route is optimized. To move a stop, click on the graphic, and while continuing to press on the graphic, move the mouse to reposition. Release the mouse to set the new position. The route will update on-the-fly while moving stops. The green box marks the boundary of the route geodatabase.

## How it works

To display a `Route` using a `RouteTask` with offline data:

1. Create the map's `Basemap` from a local tile package using a `TileCache` and `ArcGISTiledLayer`
2. Create a `RouteTask` with an offline locator geodatabase
3. Get the `RouteParameters` using `routeTask.createDefaultParameters()`
4. Create `Stop`s and add them to the route task's parameters.
5. Solve the `Route` using `routeTask.solveRoute(routeParameters)`
6. Create a graphic with the route's geometry and a `SimpleLineSymbol` and display it on another `GraphicsOverlay`.

## Relevant API

* RouteParameters
* RouteResult
* RouteTask
* Stop
* TravelMode

## Offline data

The data used by this sample is available on [ArcGIS Online](https://arcgisruntime.maps.arcgis.com/home/item.html?id=567e14f3420d40c5a206e5c0284cf8fc).

Link | Local Location
---------|-------|
|[San Diego Streets TPKX](https://arcgisruntime.maps.arcgis.com/home/item.html?id=567e14f3420d40c5a206e5c0284cf8fc)| `<userhome>`/ArcGIS/Runtime/Data/tpkx/san_diego |

## About the data

This sample uses a pre-packaged sample dataset consisting of a geodatabase with a San Diego road network and a tile package with a streets basemap.

## Tags

connectivity, disconnected, fastest, locator, navigation, network analysis, offline, routing, shortest, turn-by-turn
