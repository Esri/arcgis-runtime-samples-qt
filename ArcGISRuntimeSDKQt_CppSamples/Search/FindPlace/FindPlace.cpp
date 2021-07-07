// [WriteFile Name=FindPlace, Category=Search]
// [Legal]
// Copyright 2017 Esri.

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

#ifdef PCH_BUILD
#include "pch.hpp"
#endif // PCH_BUILD

#include "FindPlace.h"

#include "CalloutData.h"
#include "Map.h"
#include "MapQuickView.h"
#include "GraphicsOverlay.h"
#include "GeocodeResult.h"
#include "GeoElement.h"
#include "GeometryEngine.h"
#include "PictureMarkerSymbol.h"
#include "IdentifyGraphicsOverlayResult.h"
#include "Point.h"
#include "Envelope.h"
#include "SimpleRenderer.h"
#include "LocatorTask.h"
#include "LocationDisplay.h"
#include "SuggestListModel.h"
#include <QUrl>

using namespace Esri::ArcGISRuntime;

FindPlace::FindPlace(QQuickItem* parent /* = nullptr */):
  QQuickItem(parent)
{
}

FindPlace::~FindPlace()
{
  m_mapView->locationDisplay()->stop();
}

void FindPlace::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<FindPlace>("Esri.Samples", 1, 0, "FindPlaceSample");
  qmlRegisterUncreatableType<CalloutData>("Esri.Samples", 1, 0, "CalloutData", "CalloutData is an uncreatable type");
  qmlRegisterUncreatableType<QAbstractListModel>("Esri.Samples", 1, 0, "AbstractListModel", "AbstractListModel is uncreateable");
}

void FindPlace::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");

  // Create a map using the topographic basemap
  m_map = new Map(BasemapStyle::ArcGISTopographic, this);

  // Set map to map view
  m_mapView->setMap(m_map);

  // create the locator
  createLocator();

  // add the graphics overlay
  addGraphicsOverlay();

  // initialize callout
  m_mapView->calloutData()->setVisible(false);
  m_calloutData = m_mapView->calloutData();

  // connect mapview signals
  connectSignals();
}

void FindPlace::connectSignals()
{
  connect(m_mapView, &MapQuickView::drawStatusChanged, this, [this](DrawStatus drawStatus)
  {
    if (drawStatus != DrawStatus::Completed || m_mapView->locationDisplay()->isStarted())
      return;

    // turn on the location display
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::Recenter);
    m_mapView->locationDisplay()->start();
  });

  connect(m_mapView, &MapQuickView::mousePressed, this, [this](QMouseEvent& /*event*/)
  {
    emit hideSuggestionView();
  });

  connect(m_mapView, &MapQuickView::viewpointChanged, this, [this]()
  {
    emit hideSuggestionView();
    if (m_graphicsOverlay->graphics()->size() > 0)
      emit showExtentButton();
  });

  // perform an identify operation on mouse clicked
  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent& e)
  {
    emit hideCallout();
    m_mapView->identifyGraphicsOverlay(m_graphicsOverlay, e.x(), e.y(), 5, false, 1);
  });

  // handle the result once identify completes
  connect(m_mapView, &MapQuickView::identifyGraphicsOverlayCompleted, this, [this](QUuid, IdentifyGraphicsOverlayResult* result)
  {
    if (result->graphics().length() == 0)
      return;

    // display the callout with the identify result
    Graphic* graphic = result->graphics().at(0);
    m_calloutData->setGeoElement(graphic);
    m_calloutData->setTitle(graphic->attributes()->attributeValue("ShortLabel").toString());
    m_calloutData->setDetail(graphic->attributes()->attributeValue("Place_addr").toString());
    emit showCallout();
  });
}

void FindPlace::addGraphicsOverlay()
{
  // add a graphics overlay to the mapview
  m_graphicsOverlay = new GraphicsOverlay(this);
  m_mapView->graphicsOverlays()->append(m_graphicsOverlay);

  // create a renderer for graphics representing geocode results
  PictureMarkerSymbol* pinSymbol = new PictureMarkerSymbol(QUrl("qrc:/Samples/Search/FindPlace/red_pin.png"), this);
  pinSymbol->setHeight(36);
  pinSymbol->setWidth(19);
  pinSymbol->setOffsetY(pinSymbol->height() / 2);
  SimpleRenderer* simpleRenderer = new SimpleRenderer(pinSymbol, this);
  m_graphicsOverlay->setRenderer(simpleRenderer);
}

void FindPlace::createLocator()
{
  // create a locator task that uses the world geocoding service
  // an ArcGIS Developer API key is required to utilize the world geocoding service
  m_locatorTask = new LocatorTask(QUrl("https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer"), this);

  // set the suggestions Q_PROPERTY
  m_suggestListModel = m_locatorTask->suggestions();
  emit suggestionsChanged();

  // connect to the signal for when the geocode completes
  connect(m_locatorTask, &LocatorTask::geocodeCompleted, this, [this](QUuid, const QList<GeocodeResult>& results)
  {
    // if we are converting the location string to a Point, re-geocode with that information,
    // and don't add any graphics to the map
    if (m_isSearchingLocation)
    {
      m_isSearchingLocation = false;
      if (results.length() == 0)
        return;

      GeocodeResult topLocation = results.at(0);
      geocodePOIs(m_poiSearchText, topLocation.displayLocation());
      return;
    }

    // create graphics for each geocode result
    if (results.length() == 0)
      return;

    m_graphicsOverlay->graphics()->clear();

    // delete parent if it exists
    if (m_graphicParent)
    {
      delete m_graphicParent;
      m_graphicParent = nullptr;
    }
    m_graphicParent = new QObject(this);

    Geometry bbox;
    for (const GeocodeResult& result : results)
    {
      Graphic* graphic = new Graphic(result.displayLocation(), result.attributes(), m_graphicParent);
      m_graphicsOverlay->graphics()->append(graphic);
      // create bounding box so we can set the viewpoint at the end
      if (bbox.isEmpty())
        bbox = graphic->geometry();
      else
        bbox = GeometryEngine::unionOf(bbox, graphic->geometry());
    }
    // zoom to the bounding box
    m_mapView->setViewpointGeometry(bbox, 40);
  });
}

void FindPlace::setPoiTextHasFocus(bool hasFocus)
{
  if (m_poiTextHasFocus == hasFocus)
    return;

  m_poiTextHasFocus = hasFocus;

  // create and update the suggestion parameters
  SuggestParameters suggestParams;
  // the Points of Interest suggestions should use the POI category, and the location
  // suggestions should use the Populated Place category as filters
  QStringList categories;
  m_poiTextHasFocus ? categories << "POI" : categories << "Populated Place";
  suggestParams.setCategories(categories);
  suggestParams.setMaxResults(5);
  if (m_locatorTask)
    m_locatorTask->suggestions()->setSuggestParameters(suggestParams);
  emit poiTextHasFocusChanged();
}

// set the suggestion search text to fetch suggestions
void FindPlace::setSuggestionsText(const QString& searchText)
{
  if (!m_suggestListModel)
    return;

  SuggestListModel* suggestListModel = dynamic_cast<SuggestListModel*>(m_suggestListModel);
  if (!suggestListModel)
    return;

  suggestListModel->setSearchText(searchText);
}

// geocode without any spatial filter
void FindPlace::geocodePOIs(const QString& poi)
{
  m_poiSearchText = poi;
  GeocodeParameters params = createParameters();
  m_locatorTask->geocodeWithParameters(poi, params);
}

// use extent to filter the geocode results
void FindPlace::geocodePOIs(const QString& poi, SearchMode mode)
{
  m_poiSearchText = poi;

  GeocodeParameters params = createParameters();

  // If the Mode is CurrentLocation, use the Location Display as preferred search location
  if (mode == SearchMode::CurrentLocation)
  {
    params.setPreferredSearchLocation(m_mapView->locationDisplay()->location().position());
    params.setOutputSpatialReference(m_mapView->locationDisplay()->location().position().spatialReference());

    m_locatorTask->geocodeWithParameters(m_poiSearchText, params);
  }
  // If the Mode is BoundingGeometry, use the MapView's current viewpoint as the search area
  else
  {
    GeocodeParameters params = createParameters();
    Geometry extent = m_mapView->currentViewpoint(ViewpointType::BoundingGeometry).targetGeometry();
    params.setSearchArea(extent);
    params.setOutputSpatialReference(extent.spatialReference());

    m_locatorTask->geocodeWithParameters(m_poiSearchText, params);
  }
}

// use a point as a preferred search location for the geocode results
void FindPlace::geocodePOIs(const QString& poi, const Point& location)
{
  m_poiSearchText = poi;

  GeocodeParameters params = createParameters();
  params.setPreferredSearchLocation(location);
  params.setOutputSpatialReference(location.spatialReference());

  m_locatorTask->geocodeWithParameters(m_poiSearchText, params);
}

// use a location string as a preferred search location for the geocode results
void FindPlace::geocodePOIs(const QString& poi, const QString& location)
{
  if (location == m_currentLocationText)
  {
    geocodePOIs(poi, SearchMode::CurrentLocation);
    return;
  }
  m_poiSearchText = poi;
  GeocodeParameters params = createParameters();

  m_isSearchingLocation = true;
  m_locatorTask->geocodeWithParameters(location, params);
}

// create base geocode parameters
GeocodeParameters FindPlace::createParameters()
{
  GeocodeParameters params;
  params.setResultAttributeNames(QStringList{"*"});
  params.setMaxResults(50);
  params.setMinScore(75.0);
  return params;
}
