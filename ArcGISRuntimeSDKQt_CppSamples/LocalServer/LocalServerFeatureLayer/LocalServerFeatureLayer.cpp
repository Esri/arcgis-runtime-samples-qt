// [WriteFile Name=LocalServerFeatureLayer, Category=LocalServer]
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

#include "LocalServerFeatureLayer.h"

#include "Basemap.h"
#include "MapQuickView.h"
#include "Map.h"
#include "LocalServer.h"
#include "LocalFeatureService.h"
#include "ServiceFeatureTable.h"
#include "FeatureLayer.h"
#include "Viewpoint.h"

#include <QDir>
#include <QTemporaryDir>
#include <QFile>

using namespace Esri::ArcGISRuntime;

LocalServerFeatureLayer::LocalServerFeatureLayer(QQuickItem* parent) :
  QQuickItem(parent)
{
  // Create a temporary directory for the local server if one has not already been created
  if (!LocalServer::appDataPath().isEmpty() && !LocalServer::tempDataPath().isEmpty())
    return;

  // create temp/data path
  const QString tempPath = LocalServerFeatureLayer::shortestTempPath() + "/EsriQtTemp";

  // create the directory
  m_tempDir = std::unique_ptr<QTemporaryDir>(new QTemporaryDir(tempPath));

  // set the temp & app data path for the local server
  LocalServer::instance()->setTempDataPath(m_tempDir->path());
  LocalServer::instance()->setAppDataPath(m_tempDir->path());
}

LocalServerFeatureLayer::~LocalServerFeatureLayer() = default;

void LocalServerFeatureLayer::init()
{
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<LocalServerFeatureLayer>("Esri.Samples", 1, 0, "LocalServerFeatureLayerSample");
}

void LocalServerFeatureLayer::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");
  m_mapView->setWrapAroundMode(WrapAroundMode::Disabled);

  // Create a map using the topographic BaseMap
  m_map = new Map(BasemapStyle::ArcGISTopographic, this);

  // Set map to map view
  m_mapView->setMap(m_map);

  // Check for ArcGIS Pro map package files
  const QString fileName = "PointsofInterest.mpkx";
  const QString dataPath = QDir::homePath() + "/ArcGIS/Runtime/Data/mpkx/" + fileName;

  // Check to see if map package exists
  if (!QFile::exists(dataPath))
  {
    qDebug() << "ArcGIS Pro .mpkx file not found at" << dataPath;
  }

  // create a feature service
  m_localFeatureService = new LocalFeatureService(dataPath, this);

  if (LocalServer::instance()->isInstallValid())
  {
    connectSignals();
    if (LocalServer::status() == LocalServerStatus::Started)
    {
      qDebug() << "Local server was already running";

      // The local server can already be running if it was started in a different application.
      // We start up the local feature service here because there will be no status change signal to otherwise trigger it.

      startFeatureService();
    }
    else if (LocalServer::status() != LocalServerStatus::Starting)
    {
      LocalServer::start();
    }
  }
  else
    qDebug() << "Local server install invalid";
}

void LocalServerFeatureLayer::connectSignals()
{
  // Local server status
  connect(LocalServer::instance(), &LocalServer::statusChanged, this, [this]()
  {
    // If the local server was not previously running, our local feature service will start here if the local server has successfully started.
    if (LocalServer::status() == LocalServerStatus::Started)
    {
      startFeatureService();
    }
  });

  // local feature service status
  connect(m_localFeatureService, &LocalFeatureService::statusChanged, this, [this]()
  {
    if (m_localFeatureService->status() == LocalServerStatus::Starting)
    {
      qDebug() << "Local feature service starting up";
    }
    else if (m_localFeatureService->status() == LocalServerStatus::Started)
    {
      qDebug() << "Successfully hosting local feature service at:" << m_localFeatureService->url().toString();

      // create the feature layer
      ServiceFeatureTable* svt = new ServiceFeatureTable(QUrl(m_localFeatureService->url().toString() + "/0"), this);
      FeatureLayer* featureLayer = new FeatureLayer(svt, this);
      connect(featureLayer, &FeatureLayer::loadStatusChanged, this, [this, featureLayer](LoadStatus status)
      {
        if (status == LoadStatus::Loaded)
        {
          m_mapView->setViewpoint(Viewpoint(featureLayer->fullExtent()));
        }
      });
      m_map->operationalLayers()->append(featureLayer);
    }
    else if (m_localFeatureService->status() == LocalServerStatus::Failed)
    {
      qDebug() << "Local feature service failed to start";
    }
  });
}

void LocalServerFeatureLayer::startFeatureService() const
{
  if (m_localFeatureService->status() != LocalServerStatus::Started || m_localFeatureService->status() != LocalServerStatus::Starting)
    m_localFeatureService->start();
}

QString LocalServerFeatureLayer::shortestTempPath()
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
