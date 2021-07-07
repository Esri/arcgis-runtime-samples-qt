// [WriteFile Name=LocalServerGeoprocessing, Category=LocalServer]
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

#include "LocalServerGeoprocessing.h"

#include "Basemap.h"
#include "MapQuickView.h"
#include "Map.h"
#include "LocalServer.h"
#include "Viewpoint.h"
#include "TileCache.h"
#include "LocalGeoprocessingService.h"
#include "ArcGISTiledLayer.h"
#include "GeoprocessingTask.h"
#include "GeoprocessingJob.h"
#include "GeoprocessingParameter.h"
#include "GeoprocessingParameters.h"
#include "GeoprocessingDouble.h"
#include "ArcGISMapImageLayer.h"

#include <QDir>
#include <QTemporaryDir>

using namespace Esri::ArcGISRuntime;

// constructor
LocalServerGeoprocessing::LocalServerGeoprocessing(QQuickItem* parent) :
  QQuickItem(parent)
{
  // Create a temporary directory for the local server if one has not already been created
  if (!LocalServer::appDataPath().isEmpty() && !LocalServer::tempDataPath().isEmpty())
    return;

  // create temp/data path
  const QString tempPath = LocalServerGeoprocessing::shortestTempPath() + "/EsriQtTemp";

  // create the directory
  m_tempDir = std::make_unique<QTemporaryDir>(tempPath);

  // set the temp & app data path for the local server
  LocalServer::instance()->setTempDataPath(m_tempDir->path());
  LocalServer::instance()->setAppDataPath(m_tempDir->path());
}

// destructor
LocalServerGeoprocessing::~LocalServerGeoprocessing() = default;

void LocalServerGeoprocessing::init()
{
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<LocalServerGeoprocessing>("Esri.Samples", 1, 0, "LocalServerGeoprocessingSample");
}

void LocalServerGeoprocessing::componentComplete()
{
  QQuickItem::componentComplete();

  QString dataPath = QDir::homePath() + "/ArcGIS/Runtime/Data";

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");
  m_mapView->setWrapAroundMode(WrapAroundMode::Disabled);

  // Create a map using the topographic BaseMap
  m_map = new Map(BasemapStyle::ArcGISLightGray, this);

  // Set map to map view
  m_mapView->setMap(m_map);

  TileCache* tileCache = new TileCache(dataPath + "/tpkx/RasterHillshade.tpkx", this);
  m_tiledLayer = new ArcGISTiledLayer(tileCache, this);
  m_map->operationalLayers()->append(m_tiledLayer);

  // create a gp service
  m_localGPService = new LocalGeoprocessingService(dataPath + "/gpkx/Contour.gpkx", this);
  m_localGPService->setServiceType(GeoprocessingServiceType::AsynchronousSubmitWithMapServerResult);

  if (LocalServer::instance()->isInstallValid())
  {
    connectSignals();
    if (LocalServer::instance()->status() == LocalServerStatus::Started)
      m_localGPService->start();
    else
      LocalServer::start();
  }
}

void LocalServerGeoprocessing::connectSignals()
{
  connect (m_tiledLayer, &ArcGISTiledLayer::loadStatusChanged, this, [this](LoadStatus status)
  {
    if (status == LoadStatus::Loaded)
    {
      m_mapView->setViewpoint(Viewpoint(m_tiledLayer->fullExtent()));
    }
  });

  // start the gp service once local server has started
  connect(LocalServer::instance(), &LocalServer::statusChanged, this, [this]()
  {
    if (LocalServer::status() == LocalServerStatus::Started)
    {
      // start the service
      m_localGPService->start();
      m_isReady = false;
      emit isReadyChanged();
    }
  });

  // local gp service status
  connect(m_localGPService, &LocalGeoprocessingService::statusChanged, this, [this]()
  {
    if (m_localGPService->status() == LocalServerStatus::Started)
    {
      m_gpTask = new GeoprocessingTask(QUrl(m_localGPService->url().toString() + "/Contour"), this);
      m_isReady = true;
      emit isReadyChanged();
    }
  });
}

void LocalServerGeoprocessing::generateContours(double interval)
{
  m_isReady = false;
  emit isReadyChanged();
  GeoprocessingParameters gpParams(GeoprocessingExecutionType::AsynchronousSubmit);
  QMap<QString, GeoprocessingParameter*> inputs = gpParams.inputs();
  inputs.insert("ContourInterval", new GeoprocessingDouble(interval, this));
  gpParams.setInputs(inputs);

  GeoprocessingJob* gpJob = m_gpTask->createJob(gpParams);

  connect(gpJob, &GeoprocessingJob::jobDone, this, [this, gpJob]()
  {
    if (gpJob->jobStatus() == JobStatus::Succeeded)
    {
      QString url = m_localGPService->url().toString().replace("GPServer", "MapServer/jobs/" + gpJob->serverJobId());
      ArcGISMapImageLayer* mapImageLayer = new ArcGISMapImageLayer(QUrl(url), this);
      m_map->operationalLayers()->append(mapImageLayer);
      m_isReady = true;
      emit isReadyChanged();
    }
  });

  gpJob->start();
}

void LocalServerGeoprocessing::clearResults()
{
  if (m_mapView->map()->operationalLayers()->size() > 1)
    m_mapView->map()->operationalLayers()->removeAt(1);
}

QString LocalServerGeoprocessing::shortestTempPath()
{
  // get tmp and home paths
  const QString tmpPath = QDir::tempPath();
  const QString homePath = QDir::homePath();

  // return whichever is shorter, temp or home path
  if (homePath.length() > tmpPath.length())
    return tmpPath;
  else
    return homePath;
}
