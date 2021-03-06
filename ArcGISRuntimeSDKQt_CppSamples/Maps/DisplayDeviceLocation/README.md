# Display device location with autopan modes

Display your current position on the map, as well as switch between different types of auto pan modes.

![](screenshot.png)

## Use case

When using a map within a GIS, it may be helpful for a user to know their own location within a map, whether that's to aid the user's navigation or to provide an easy means of identifying/collecting geospatial information at their location.

## How to use the sample

Tap the button in the lower right (which starts in Stop mode). A menu will appear with the following options:

* Stop - Stops the location display.
* On - Starts the location display with no `AutoPanMode` mode set.
* Re-Center - Starts the location display with auto pan mode set to `LocationDisplayAutoPanMode::Recenter`.
* Navigation - Starts the location display with auto pan mode set to `LocationDisplayAutoPanMode::Navigation`.
* Compass - Starts the location display with auto pan mode set to `LocationDisplayAutoPanMode::CompassNavigation`.

## How it works

1. Create a `MapView`.
2. Get the `LocationDisplay` object by calling `locationDisplay()` on the map view.
3. Use `start()` and `stop()` on the `LocationDisplay` object as necessary.

## Relevant API

* LocationDisplay
* LocationDisplay::setAutoPanMode
* Map
* MapView

## Additional information

Location permissions are required for this sample.

## Tags

compass, GPS, location, map, mobile, navigation
