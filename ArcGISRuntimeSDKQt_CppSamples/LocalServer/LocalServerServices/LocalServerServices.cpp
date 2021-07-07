// [WriteFile Name=LocalServerServices, Category=LocalServer]
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

#include "LocalServerServices.h"

#include "Basemap.h"
#include "LocalServer.h"
#include "LocalMapService.h"
#include "LocalFeatureService.h"
#include "LocalGeoprocessingService.h"

#include <QDesktopServices>
#include <QDir>
#include <QTemporaryDir>

using namespace Esri::ArcGISRuntime;

LocalServerServices::LocalServerServices(QQuickItem* parent) :
  QQuickItem(parent),
  m_dataPath(QDir::homePath() + "/ArcGIS/Runtime/Data")
{
  // Create a temporary directory for the local server if one has not already been created
  if (!LocalServer::appDataPath().isEmpty() && !LocalServer::tempDataPath().isEmpty())
    return;

  // create temp/data path
  const QString tempPath = LocalServerServices::shortestTempPath() + "/EsriQtSample";

  // create the directory
  m_tempDir = std::make_unique<QTemporaryDir>(tempPath);

  // set the temp & app data path for the local server
  LocalServer::instance()->setTempDataPath(m_tempDir->path());
  LocalServer::instance()->setAppDataPath(m_tempDir->path());
}

LocalServerServices::~LocalServerServices() = default;

void LocalServerServices::init()
{
  qmlRegisterType<LocalServerServices>("Esri.Samples", 1, 0, "LocalServerServicesSample");
}

void LocalServerServices::componentComplete()
{
  QQuickItem::componentComplete();

  QString dataPath = QDir::homePath() + "/ArcGIS/Runtime/Data";
  // create a map service
  m_localMapService = new LocalMapService(dataPath + "/mpkx/PointsofInterest.mpkx", this);
  // create a feature service
  m_localFeatureService = new LocalFeatureService(dataPath + "/mpkx/PointsofInterest.mpkx", this);
  // create a gp service
  m_localGPService = new LocalGeoprocessingService(dataPath + "/gpkx/Contour.gpkx", this);

  if (LocalServer::instance()->isInstallValid())
  {
    if (LocalServer::status() == LocalServerStatus::Started)
      LocalServer::stop();

    connectSignals();
  }
}

void LocalServerServices::connectSignals()
{
  // local server status
  connect(LocalServer::instance(), &LocalServer::statusChanged, this, [this]()
  {
    // append to the status string
    switch (LocalServer::status())
    {
      case LocalServerStatus::Starting:
      {
        m_serverStatus.append("Server Status: STARTING\n");
        break;
      }
      case LocalServerStatus::Started:
      {
        m_serverStatus.append("Server Status: STARTED\n");
        m_isServerRunning = true;
        emit isServerRunningChanged();
        break;
      }
      case LocalServerStatus::Stopping:
      {
        m_serverStatus.append("Server Status: STOPPING\n");
        break;
      }
      case LocalServerStatus::Stopped:
      {
        m_serverStatus.append("Server Status: STOPPED\n");
        m_isServerRunning = false;
        emit isServerRunningChanged();
        break;
      }
      case LocalServerStatus::Failed:
      {
        m_serverStatus.append("Server Status: FAILED\n");
        break;
      }
      default:
        break;
    }
    emit serverStatusChanged();
  });

  connect(m_localMapService, &LocalMapService::statusChanged, this, [this]()
  {
    updateStatus(m_localMapService, "Map");
  });

  connect(m_localFeatureService, &LocalFeatureService::statusChanged, this, [this]()
  {
    updateStatus(m_localFeatureService, "Feature");
  });

  connect(m_localGPService, &LocalGeoprocessingService::statusChanged, this, [this]()
  {
    updateStatus(m_localGPService, "Geoprocessing");
  });
}

// start the server
void LocalServerServices::startLocalServer()
{
  if (m_isServerRunning)
    return;

  // clear all the status messages
  m_serverStatus.clear();
  // start local server
  LocalServer::start();
}

// stop the server
void LocalServerServices::stopLocalServer()
{
  LocalServer::stop();
}

// start a service
void LocalServerServices::startService(const QString& serviceName, const QUrl& filePath)
{
  QString path;
  if (!filePath.isEmpty())
    path = QUrl(filePath).toLocalFile();

  if (serviceName == "Map Service")
  {
    if (path.isEmpty())
    {
      if (m_localMapService->status() == LocalServerStatus::Started)
        return;

      m_localMapService->start();
    }
    else
    {
      LocalMapService* mapService = new LocalMapService(path, this);
      connect(mapService, &LocalMapService::statusChanged, this, [this, mapService]()
      {
        updateStatus(mapService, "Map");
      });
      mapService->start();
    }
  }
  else if (serviceName == "Feature Service")
  {
    if (path.isEmpty())
    {
      if (m_localFeatureService->status() == LocalServerStatus::Started)
        return;

      m_localFeatureService->start();
    }
    else
    {
      LocalFeatureService* featureService = new LocalFeatureService(path, this);
      connect(featureService, &LocalFeatureService::statusChanged, this, [this, featureService]()
      {
        updateStatus(featureService, "Feature");
      });
      featureService->start();
    }
  }
  else if (serviceName == "Geoprocessing Service")
  {
    if (path.isEmpty())
    {
      if (m_localGPService->status() == LocalServerStatus::Started)
        return;

      m_localGPService->start();
    }
    else
    {
      LocalGeoprocessingService* gpService = new LocalGeoprocessingService(path, this);
      connect(gpService, &LocalGeoprocessingService::statusChanged, this, [this, gpService]()
      {
        updateStatus(gpService, "Geoprocessing");
      });
      gpService->start();
    }
  }
}

// stop any service
void LocalServerServices::stopService(const QUrl& serviceUrl)
{
  if (serviceUrl.isEmpty())
    return;

  LocalService* serviceToStop = m_servicesHash[serviceUrl];
  serviceToStop->stop();
}

// open the link in a browser
void LocalServerServices::openURL(const QString& serviceURL)
{
  QDesktopServices::openUrl(QUrl(serviceURL));
}

// check if any one of the services is running
bool LocalServerServices::isAnyServiceRunning()
{
  return LocalServer::services().size() > 0;
}

// get the current list of services from local server
void LocalServerServices::getCurrentServices()
{
  // get the service names by looping through the services
  m_services.clear();
  for (const LocalService* service : LocalServer::services())
  {
    m_services << service->url().toString();
  }
  emit servicesChanged();
}

// get the current status of any service
void LocalServerServices::updateStatus(LocalService* service, const QString& serviceName)
{
  switch (service->status())
  {
    case LocalServerStatus::Starting:
    {
      m_serverStatus.append(serviceName + " Service Status: STARTING\n");
      break;
    }
    case LocalServerStatus::Started:
    {
      m_serverStatus.append(serviceName + " Service Status: STARTED\n");
      m_isServiceRunning = true;
      emit isServiceRunningChanged();

      getCurrentServices();
      m_servicesHash.insert(service->url(), service);
      break;
    }
    case LocalServerStatus::Stopping:
    {
      m_serverStatus.append(serviceName + " Service Status: STOPPING\n");
      break;
    }
    case LocalServerStatus::Stopped:
    {
      m_serverStatus.append(serviceName + " Service Status: STOPPED\n");
      if (!isAnyServiceRunning())
      {
        m_isServiceRunning = false;
        emit isServiceRunningChanged();
      }

      getCurrentServices();
      m_servicesHash.remove(service->url());
      break;
    }
    default:
      break;
  }
  emit serverStatusChanged();
}

QString LocalServerServices::shortestTempPath()
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
