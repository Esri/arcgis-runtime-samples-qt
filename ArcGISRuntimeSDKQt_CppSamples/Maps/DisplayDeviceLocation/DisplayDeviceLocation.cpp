// [WriteFile Name=DisplayDeviceLocation, Category=Maps]
// [Legal]
// Copyright 2016 Esri.

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

#include "DisplayDeviceLocation.h"

#include "Map.h"
#include "MapQuickView.h"
#include "Basemap.h"

using namespace Esri::ArcGISRuntime;

const QString DisplayDeviceLocation::s_compassMode = QStringLiteral("Compass");
const QString DisplayDeviceLocation::s_navigationMode = QStringLiteral("Navigation");
const QString DisplayDeviceLocation::s_recenterMode = QStringLiteral("Re-Center");
const QString DisplayDeviceLocation::s_onMode = QStringLiteral("On");
const QString DisplayDeviceLocation::s_stopMode = QStringLiteral("Stop");
const QString DisplayDeviceLocation::s_closeMode = QStringLiteral("Close");

DisplayDeviceLocation::DisplayDeviceLocation(QQuickItem* parent) :
  QQuickItem(parent)
{
}

DisplayDeviceLocation::~DisplayDeviceLocation()
{
  m_mapView->locationDisplay()->stop();
}

void DisplayDeviceLocation::init()
{
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<DisplayDeviceLocation>("Esri.Samples", 1, 0, "DisplayDeviceLocationSample");
}

void DisplayDeviceLocation::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");

  // create a new basemap instance
  Basemap* basemap = new Basemap(BasemapStyle::ArcGISImageryStandard, this);

  // create a new map instance
  m_map = new Map(basemap, this);

  // set map on the map view
  m_mapView->setMap(m_map);
}

void DisplayDeviceLocation::startLocationDisplay()
{
  //! [start location display api snippet]
  // turn on the location display
  m_mapView->locationDisplay()->start();
  //! [start location display api snippet]
}

void DisplayDeviceLocation::stopLocationDisplay()
{
  // stop location display
  m_mapView->locationDisplay()->stop();
}

void DisplayDeviceLocation::setAutoPanMode(QString autoPanMode)
{
  // set the correct auto pan mode on the location display
  if (autoPanMode == compassMode())
  {
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::CompassNavigation);
  }
  else if (autoPanMode == navigationMode())
  {
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::Navigation);
  }
  else if (autoPanMode == recenterMode())
  {
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::Recenter);
  }
  else if (autoPanMode == stopMode())
  {
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::Off);
  }
  else if (autoPanMode == onMode())
  {
    m_mapView->locationDisplay()->setAutoPanMode(LocationDisplayAutoPanMode::Off);
  }
}

const QString DisplayDeviceLocation::compassMode()
{
  return s_compassMode;
}

const QString DisplayDeviceLocation::navigationMode()
{
  return s_navigationMode;
}

const QString DisplayDeviceLocation::recenterMode()
{
  return s_recenterMode;
}

const QString DisplayDeviceLocation::onMode()
{
  return s_onMode;
}

const QString DisplayDeviceLocation::stopMode()
{
  return s_stopMode;
}

const QString DisplayDeviceLocation::closeMode()
{
  return s_closeMode;
}
