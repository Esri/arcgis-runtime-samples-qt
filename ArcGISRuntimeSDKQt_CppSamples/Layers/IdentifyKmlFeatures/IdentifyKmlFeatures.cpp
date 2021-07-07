// [WriteFile Name=IdentifyKmlFeatures, Category=Layers]
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

#include "IdentifyKmlFeatures.h"

#include "CalloutData.h"
#include "KmlDataset.h"
#include "KmlLayer.h"
#include "KmlPlacemark.h"
#include "Map.h"
#include "MapQuickView.h"

using namespace Esri::ArcGISRuntime;

namespace  {
const QUrl datasetUrl("https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx_latest.kml");
}

IdentifyKmlFeatures::IdentifyKmlFeatures(QObject* parent /* = nullptr */):
  QObject(parent),
  m_map(new Map(BasemapStyle::ArcGISDarkGray, this))
{
  // create new KML layer
  KmlDataset* forecastDataset = new KmlDataset(datasetUrl, this);
  m_forecastLayer = new KmlLayer(forecastDataset, this);
  m_map->operationalLayers()->append(m_forecastLayer);
}

IdentifyKmlFeatures::~IdentifyKmlFeatures() = default;

void IdentifyKmlFeatures::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<IdentifyKmlFeatures>("Esri.Samples", 1, 0, "IdentifyKmlFeaturesSample");
}

MapQuickView* IdentifyKmlFeatures::mapView() const
{
  return m_mapView;
}

// Set the view (created in QML)
void IdentifyKmlFeatures::setMapView(MapQuickView* mapView)
{
  if (!mapView || mapView == m_mapView)
    return;

  m_mapView = mapView;
  m_mapView->setMap(m_map);

  // start zoomed in over the US
  m_mapView->setViewpointGeometry(Envelope(-19195297.778679, 512343.939994, -3620418.579987, 8658913.035426, SpatialReference::webMercator()));

  connect(m_mapView, &MapQuickView::identifyLayerCompleted, this, [this](QUuid, Esri::ArcGISRuntime::IdentifyLayerResult *rawResult)
  {
    auto result = std::unique_ptr<IdentifyLayerResult>(rawResult);

    // if not clicked on KML feature then close callout
    if (result->geoElements().length() < 1)
    {
      m_mapView->calloutData()->setVisible(false);
      return;
    }

    // find the first geoElement that is a KML placemark
    for (GeoElement* geoElement : result->geoElements())
    {
      if (KmlPlacemark* placemark = dynamic_cast<KmlPlacemark*>(geoElement))
      {
        // Google Earth only displays the placemarks with description or extended data. To
        // match its behavior, add a description placeholder if the data source is empty
        if (placemark->description().isEmpty())
          placemark->setDescription("Weather condition");

        m_calloutText = placemark->balloonContent();
        m_mapView->calloutData()->setLocation(m_clickedPoint);
        m_mapView->calloutData()->setVisible(true);

        emit calloutDataChanged();
        emit calloutTextChanged();
        return;
      }
    }
  });

  // identify clicked features
  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent& e)
  {
    m_clickedPoint = m_mapView->screenToLocation(e.x(), e.y());
    m_mapView->identifyLayer(m_forecastLayer, e.x(), e.y(), 15, false);
  });

  emit mapViewChanged();
}

CalloutData* IdentifyKmlFeatures::calloutData() const
{
  return m_calloutData;
}

QString IdentifyKmlFeatures::calloutText() const
{
  return m_calloutText;
}
