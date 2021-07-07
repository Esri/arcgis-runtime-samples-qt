// [WriteFile Name=CreateTerrainSurfaceFromLocalTilePackage, Category=Scenes]
// [Legal]
// Copyright 2019 Esri.

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

#include "CreateTerrainSurfaceFromLocalTilePackage.h"

#include "ArcGISTiledElevationSource.h"
#include "Scene.h"
#include "SceneQuickView.h"

#include <QDir>
#include <QUrl>

#ifdef Q_OS_IOS
#include <QStandardPaths>
#endif

using namespace Esri::ArcGISRuntime;

// helper method to get cross platform data path
namespace
{
  QString defaultDataPath()
  {
    QString dataPath;

    #ifdef Q_OS_ANDROID
      dataPath = "/sdcard";
    #elif defined Q_OS_IOS
      dataPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    #else
      dataPath = QDir::homePath();
    #endif

    return dataPath;
  }
}

using namespace Esri::ArcGISRuntime;

CreateTerrainSurfaceFromLocalTilePackage::CreateTerrainSurfaceFromLocalTilePackage(QObject* parent /* = nullptr */):
  QObject(parent),
  m_scene(new Scene(BasemapStyle::ArcGISImageryStandard, this))
{
  // create the MontereyElevation data path
  // data is downloaded automatically by the sample viewer app. Instructions to download
  // separately are specified in the readme.
  const QString montereyTileElevationPath = QString{defaultDataPath() + "/ArcGIS/Runtime/Data/tpkx/MontereyElevation.tpkx"};

  // Before attempting to add any layers, check that the file for the elevation source exists at all.
  const bool srcElevationFileExists = QFileInfo::exists(montereyTileElevationPath);

  if(srcElevationFileExists)
  {
    // Create the elevation source from the local raster(s). RasterElevationSource can take multiple files as inputs, but in this case only takes one.
    ArcGISTiledElevationSource* elevationSrc = new ArcGISTiledElevationSource{montereyTileElevationPath, this};

    // When the elevation source is finished loading, call the elevationSrcFinishedLoading callback, so we can tell if it loaded succesfully.
    connect(elevationSrc, &ArcGISTiledElevationSource::doneLoading, this, &CreateTerrainSurfaceFromLocalTilePackage::elevationSrcFinishedLoading);

    // add the elevation source to the scene to display elevation
    m_scene->baseSurface()->elevationSources()->append(elevationSrc);
  }
  else
  {
    qDebug() << "Could not find file at : " << montereyTileElevationPath << ". Elevation source not set.";
  }
}

void CreateTerrainSurfaceFromLocalTilePackage::elevationSrcFinishedLoading(Esri::ArcGISRuntime::Error loadError)
{
  if(loadError.isEmpty())
  {
    // Succesful load
    qDebug() << "Loaded tile elevation source succesfully";
  }
  else {
    // Log failure to load
    qDebug() << "Error loading elevation source : " << loadError.message();
  }
}

CreateTerrainSurfaceFromLocalTilePackage::~CreateTerrainSurfaceFromLocalTilePackage() = default;

void CreateTerrainSurfaceFromLocalTilePackage::init()
{
  // Register classes for QML
  qmlRegisterType<SceneQuickView>("Esri.Samples", 1, 0, "SceneView");
  qmlRegisterType<CreateTerrainSurfaceFromLocalTilePackage>("Esri.Samples", 1, 0, "CreateTerrainSurfaceFromLocalTilePackageSample");
}

SceneQuickView* CreateTerrainSurfaceFromLocalTilePackage::sceneView() const
{
  return m_sceneView;
}

// Set the view (created in QML)
void CreateTerrainSurfaceFromLocalTilePackage::setSceneView(SceneQuickView* sceneView)
{
  if (!sceneView || sceneView == m_sceneView)
  {
    return;
  }

  m_sceneView = sceneView;
  m_sceneView->setArcGISScene(m_scene);

  // Create a camera, looking at Monterey, California.
  constexpr double latitude = 36.51;
  constexpr double longitude = -121.80;
  constexpr double altitude = 300.0;
  constexpr double heading = 0.0;
  constexpr double pitch = 70.0;
  constexpr double roll = 0.0;
  Camera camera{latitude, longitude, altitude, heading, pitch, roll};

  // Set the sceneview to use above camera, waits for load so scene is immediately displayed in appropriate place.
  m_sceneView->setViewpointCameraAndWait(camera);

  emit sceneViewChanged();
}

