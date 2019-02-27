// [WriteFile Name=GetElevationAtPoint, Category=Analysis]
// [Legal]
// Copyright 2018 Esri.

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

#include "GetElevationAtPoint.h"

#include "ArcGISTiledElevationSource.h"
#include "Scene.h"
#include "SceneQuickView.h"
#include "Surface.h"
#include "GraphicsOverlay.h"
#include "SimpleMarkerSymbol.h"
#include <QQuickView>

using namespace Esri::ArcGISRuntime;

GetElevationAtPoint::GetElevationAtPoint(QObject* parent /* = nullptr */):
  QObject(parent),
  m_scene(new Scene(Basemap::imagery(this), this))
{
  // create a new elevation source from Terrain3D REST service
  ArcGISTiledElevationSource* elevationSource = new ArcGISTiledElevationSource(
        QUrl("https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer"), this);

  // add the elevation source to the scene to display elevation
  m_scene->baseSurface()->elevationSources()->append(elevationSource);

  // create a graphics overlay to display the elevation marker
  m_graphicsOverlay = new GraphicsOverlay(this);

  // create red circle graphic to mark altitude, position is set in response to input
  m_elevationMarker = new Graphic(this);
  SimpleMarkerSymbol* redCircleSymbol = new SimpleMarkerSymbol(SimpleMarkerSymbolStyle::Circle, QColor("red"), 12, this);
  m_elevationMarker->setSymbol(redCircleSymbol);

  //Set the marker to be invisible initially, will be flaggd visible when user interacts with scene for the first time, to visualise clicked position
  m_elevationMarker->setVisible(false);

  //Add the marker to the graphics overlay so it will be displayed. Graphics overlay is attached to the sceneView in ::setSceneView()
  m_graphicsOverlay->graphics()->append(m_elevationMarker);
}

GetElevationAtPoint::~GetElevationAtPoint() = default;

void GetElevationAtPoint::init()
{
  // Register classes for QML
  qmlRegisterType<SceneQuickView>("Esri.Samples", 1, 0, "SceneView");
  qmlRegisterType<GetElevationAtPoint>("Esri.Samples", 1, 0, "GetElevationAtPointSample");
}

SceneQuickView* GetElevationAtPoint::sceneView() const
{
  return m_sceneView;
}

// Set the view (created in QML)
void GetElevationAtPoint::setSceneView(SceneQuickView* sceneView)
{
  if (!sceneView || sceneView == m_sceneView)
  {
    return;
  }

  m_sceneView = sceneView;
  m_sceneView->setArcGISScene(m_scene);

  //Create a camera, looking at a mountain range in Nepal.
  const double latitude = 28.4;
  const double longitude = 83.9;
  const double altitude = 10000.0;
  const double heading = 10.0;
  const double pitch = 80.0;
  const double roll = 0.0;
  Camera camera(latitude, longitude, altitude, heading, pitch, roll);

  //Set the sceneview to use above camera, waits for load so scene is immediately displayed in appropriate place.
  m_sceneView->setViewpointCameraAndWait(camera);

  //Append the graphics overlays to the sceneview, so we can visualise elevation on click
  m_sceneView->graphicsOverlays()->append(m_graphicsOverlay);

  connect(sceneView, &SceneQuickView::mouseClicked, this, &GetElevationAtPoint::displayElevationOnClick);

  emit sceneViewChanged();
}


void GetElevationAtPoint::displayElevationOnClick(QMouseEvent& mouseEvent)
{
  const Point baseSurfacePos = m_sceneView->screenToBaseSurface(mouseEvent.screenPos().x(), mouseEvent.screenPos().y());

  //Connect to callback for elevation query, which places marker and sets elevation
  connect(m_scene->baseSurface(), &Surface::locationToElevationCompleted,
          this, [baseSurfacePos, this](QUuid /*taskId*/, double elevation)
  {
    //Place the elevation marker circle at the clicked positions
    m_elevationMarker->setGeometry(baseSurfacePos);
    m_elevationMarker->setVisible(true);

    m_elevation = elevation;
    emit elevationChanged(elevation);
  });

  //Invoke get elevation query
  TaskWatcher locationToElevationQueryTask = m_scene->baseSurface()->locationToElevation(baseSurfacePos);
}

double GetElevationAtPoint::elevation() const
{
  return m_elevation;
}