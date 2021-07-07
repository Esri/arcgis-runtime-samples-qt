// [WriteFile Name=ReverseGeocodeOnline, Category=Search]
// [Legal]
// Copyright 2020 Esri.

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

#include "ReverseGeocodeOnline.h"

#include "CalloutData.h"
#include "Graphic.h"
#include "GraphicsOverlay.h"
#include "LocatorTask.h"
#include "Map.h"
#include "MapQuickView.h"
#include "PictureMarkerSymbol.h"
#include "SimpleRenderer.h"

#include <QDir>
#include <QUrl>

using namespace Esri::ArcGISRuntime;

namespace
{
// An ArcGIS Developer API key is required to utilize the world geocoding service
const QUrl url("https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer");
const QUrl pinUrl("qrc:/Samples/Search/ReverseGeocodeOnline/pin_circle_red.png");
} // namespace

ReverseGeocodeOnline::ReverseGeocodeOnline(QObject* parent /* = nullptr */):
  QObject(parent),
  m_map(new Map(BasemapStyle::ArcGISImagery, this))
{
  m_graphicsOverlay = new GraphicsOverlay(this);
  m_locatorTask = new LocatorTask(url, this);
}

ReverseGeocodeOnline::~ReverseGeocodeOnline() = default;

void ReverseGeocodeOnline::configureGraphic()
{
  PictureMarkerSymbol* pinSymbol = new PictureMarkerSymbol(pinUrl, this);
  pinSymbol->setHeight(40);
  pinSymbol->setWidth(40);
  pinSymbol->setOffsetY(pinSymbol->height() / 2);
  SimpleRenderer* simpleRenderer = new SimpleRenderer(pinSymbol, this);

  m_graphicsOverlay->setRenderer(simpleRenderer);
  m_graphicsOverlay->graphics()->append(new Graphic(this));
  m_graphic = m_graphicsOverlay->graphics()->at(0);
}

void ReverseGeocodeOnline::getAddress()
{
  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent& e)
  {
    e.accept();
    const Point clickedLocation = m_mapView->screenToLocation(e.x(), e.y());
    ReverseGeocodeParameters reverseGeocodeParameters;
    reverseGeocodeParameters.setOutputSpatialReference(m_mapView->spatialReference());
    m_locatorTask->reverseGeocodeWithParameters(clickedLocation, reverseGeocodeParameters);
  });

  connect(m_locatorTask, &LocatorTask::geocodeCompleted, this, [this](QUuid, const QList<GeocodeResult>& geocodeResults)
  {
    if (geocodeResults.empty())
      return;

    GeocodeResult geocode = geocodeResults.at(0);
    const Point location = geocode.displayLocation();
    m_mapView->setViewpointCenter(location);

    const QString address = geocode.label();
    const int splitIndex = address.indexOf(",");

    m_mapView->calloutData()->setTitle(address.left(splitIndex).trimmed());
    m_mapView->calloutData()->setDetail(address.mid(splitIndex + 1).trimmed());
    m_mapView->calloutData()->setLocation(location);
    m_mapView->calloutData()->setVisible(true);

    m_graphic->setGeometry(geocode.displayLocation());
    m_graphic->attributes()->setAttributesMap(geocode.attributes());
    constexpr double scale = 8000.0;
    m_mapView->setViewpointCenter(geocode.extent().center(), scale);
    m_graphic->setVisible(true);
  });
}

void ReverseGeocodeOnline::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<ReverseGeocodeOnline>("Esri.Samples", 1, 0, "ReverseGeocodeOnlineSample");
  qmlRegisterUncreatableType<CalloutData>("Esri.Samples", 1, 0, "CalloutData", "CalloutData is an uncreatable type");
}

MapQuickView* ReverseGeocodeOnline::mapView() const
{
  return m_mapView;
}

CalloutData* ReverseGeocodeOnline::calloutData() const
{
  return m_calloutData;
}

// Set the view (created in QML)
void ReverseGeocodeOnline::setMapView(MapQuickView* mapView)
{
  if (!mapView || mapView == m_mapView)
    return;

  m_mapView = mapView;
  m_mapView->setMap(m_map);

  // center map in San Diego
  const Point center(-13042254.715252, 3857970.236806, SpatialReference(3857));
  m_mapView->setViewpointCenter(center, 30000);

  configureGraphic();
  m_mapView->graphicsOverlays()->append(m_graphicsOverlay);

  getAddress();

  emit mapViewChanged();
}
