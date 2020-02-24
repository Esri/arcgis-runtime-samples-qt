// [WriteFile Name=ConvexHull, Category=Geometry]
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

#include "ConvexHull.h"

#include "GeometryEngine.h"
#include "Graphic.h"
#include "GraphicsOverlay.h"
#include "Map.h"
#include "MapQuickView.h"
#include "MultipointBuilder.h"
#include "PointCollection.h"
#include "SimpleFillSymbol.h"
#include "SimpleMarkerSymbol.h"

using namespace Esri::ArcGISRuntime;

ConvexHull::ConvexHull(QObject* parent /* = nullptr */):
  QObject(parent),
  m_map(new Map(Basemap::topographic(this), this))
{

}

ConvexHull::~ConvexHull() = default;

void ConvexHull::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<ConvexHull>("Esri.Samples", 1, 0, "ConvexHullSample");
}

MapQuickView* ConvexHull::mapView() const
{
  return m_mapView;
}

void ConvexHull::displayConvexHull()
{
  Geometry convexHull = GeometryEngine::convexHull(m_inputsGraphic->geometry());

  // change the symbol based on the returned geometry type
  if (convexHull.geometryType() == GeometryType::Point)
  {
    m_convexHullGraphic->setSymbol(m_markerSymbol);
  }
  else if (convexHull.geometryType() == GeometryType::Polyline)
  {
    m_convexHullGraphic->setSymbol(m_lineSymbol);
  }
  else if (convexHull.geometryType() == GeometryType::Polygon)
  {
    m_convexHullGraphic->setSymbol(m_fillSymbol);
  }

  m_convexHullGraphic->setGeometry(convexHull);
  return;
  }

void ConvexHull::clearGraphics()
{
  m_inputs.clear();
  m_inputsGraphic->setGeometry(Geometry());
  m_convexHullGraphic->setGeometry(Geometry());
}

void ConvexHull::setupGraphics()
{
  // graphics overlay to show clicked points and convex hull
  m_graphicsOverlay = new GraphicsOverlay(this);

  // create a graphic to show clicked points
  m_markerSymbol = new SimpleMarkerSymbol(SimpleMarkerSymbolStyle::Circle, Qt::red, 10, this);
  m_inputsGraphic = new Graphic(this);
  m_inputsGraphic->setSymbol(m_markerSymbol);
  m_graphicsOverlay->graphics()->append(m_inputsGraphic);

  // create a graphic to display the convex hull
  m_convexHullGraphic = new Graphic(this);
  m_graphicsOverlay->graphics()->append(m_convexHullGraphic);

  // create a graphic to show the convex hull
  m_lineSymbol = new SimpleLineSymbol(SimpleLineSymbolStyle::Solid, Qt::blue, 3, this);
  m_fillSymbol = new SimpleFillSymbol(SimpleFillSymbolStyle::Null, Qt::transparent, m_lineSymbol, this);
}

void ConvexHull::getInputs()
{
  // show clicked points on MapView
  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent& e){
    e.accept();

    const Point clickedPoint = m_mapView->screenToLocation(e.x(), e.y());
    m_inputs.push_back(clickedPoint);

    PointCollection* pointCollection = new PointCollection(m_mapView->spatialReference(), this);
    pointCollection->addPoints(m_inputs);
    MultipointBuilder* multipointBuilder = new MultipointBuilder(m_mapView->spatialReference(), this);
    multipointBuilder->setPoints(pointCollection);
    m_inputsGraphic->setGeometry(multipointBuilder->toGeometry());
  });
}

// Set the view (created in QML)
void ConvexHull::setMapView(MapQuickView* mapView)
{
  if (!mapView || mapView == m_mapView)
    return;

  m_mapView = mapView;
  m_mapView->setMap(m_map);

  setupGraphics();
  getInputs();

  m_mapView->graphicsOverlays()->append(m_graphicsOverlay);
  emit mapViewChanged();
}
