// [WriteFile Name=GenerateGeodatabase, Category=Features]
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

#include "GenerateGeodatabase.h"

#include "Map.h"
#include "MapQuickView.h"
#include "FeatureLayer.h"
#include "Basemap.h"
#include "SpatialReference.h"
#include "ServiceFeatureTable.h"
#include "ArcGISTiledLayer.h"
#include "ArcGISFeatureServiceInfo.h"
#include "Envelope.h"
#include "GenerateGeodatabaseParameters.h"
#include "GeodatabaseSyncTask.h"
#include "GeometryEngine.h"
#include "GenerateLayerOption.h"
#include "GeodatabaseFeatureTable.h"

#include <QDir>
#include <QtCore/qglobal.h>
#include <QUrl>

#ifdef Q_OS_IOS
#include <QStandardPaths>
#endif // Q_OS_IOS

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
} // namespace

GenerateGeodatabase::GenerateGeodatabase(QQuickItem* parent) :
  QQuickItem(parent),
  m_dataPath(defaultDataPath() + "/ArcGIS/Runtime/Data/")
{
}

GenerateGeodatabase::~GenerateGeodatabase() = default;

void GenerateGeodatabase::init()
{
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<GenerateGeodatabase>("Esri.Samples", 1, 0, "GenerateGeodatabaseSample");
}

void GenerateGeodatabase::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");
  m_mapView->setWrapAroundMode(WrapAroundMode::Disabled);

  //! [Create a map using a local tile package]
  TileCache* tileCache = new TileCache(m_dataPath + "tpkx/SanFrancisco.tpkx", this);
  ArcGISTiledLayer* tiledLayer = new ArcGISTiledLayer(tileCache, this);
  Basemap* basemap = new Basemap(tiledLayer, this);
  m_map = new Map(basemap, this);
  //! [Create a map using a local tile package]

  // set an initial viewpoint
  Envelope env(-122.50017, 37.74500, -122.43843, 37.81638, SpatialReference(4326));
  Viewpoint viewpoint(env);
  m_map->setInitialViewpoint(viewpoint);

  // Set map to map view
  m_mapView->setMap(m_map);

  //! [Features GenerateGeodatabase Part 1]
  // create the GeodatabaseSyncTask
  m_syncTask = new GeodatabaseSyncTask(QUrl(m_featureServiceUrl), this);
  //! [Features GenerateGeodatabase Part 1]

  // connect to sync task doneLoading signal
  connect(m_syncTask, &GeodatabaseSyncTask::doneLoading, this, [this](Error error)
  {
    if (!error.isEmpty())
    {
      emit updateStatus("Generate failed");
      emit hideWindow(5000, false);
      return;
    }

    // add online feature layers to the map, and obtain service IDs
    m_featureServiceInfo = m_syncTask->featureServiceInfo();
    for (const IdInfo& idInfo : m_featureServiceInfo.layerInfos())
    {
      // get the layer ID from the idInfo
      QString id = QString::number(idInfo.infoId());

      // add the layer to the map
      QUrl featureLayerUrl(m_featureServiceInfo.url().toString() + "/" + id);
      ServiceFeatureTable* serviceFeatureTable = new ServiceFeatureTable(featureLayerUrl, this);
      FeatureLayer* featureLayer = new FeatureLayer(serviceFeatureTable, this);
      m_map->operationalLayers()->append(featureLayer);

      // add the layer id to the string list
      m_serviceIds << id;
    }

  });

  // connect to map doneLoading signal
  connect(m_map, &Map::doneLoading, this, [this](Error error)
  {
    if (error.isEmpty())
    {
      // load the sync task once the map loads
      m_syncTask->load();
    }
  });
}

void GenerateGeodatabase::addFeatureLayers(const QString& serviceUrl, const QStringList& serviceIds)
{
  for (const QString& id : serviceIds)
  {
    ServiceFeatureTable* serviceFeatureTable = new ServiceFeatureTable(QUrl(serviceUrl + id), this);
    FeatureLayer* featureLayer = new FeatureLayer(serviceFeatureTable, this);
    m_map->operationalLayers()->append(featureLayer);
  }
}

//! [Features GenerateGeodatabase Part 2]
GenerateGeodatabaseParameters GenerateGeodatabase::getUpdatedParameters(Envelope gdbExtent)
{
  // create the parameters
  GenerateGeodatabaseParameters params;
  params.setReturnAttachments(false);
  params.setOutSpatialReference(SpatialReference::webMercator());
  params.setExtent(gdbExtent);

  // set the layer options for all of the service IDs
  QList<GenerateLayerOption> layerOptions;
  for (const QString& id : m_serviceIds)
  {
    GenerateLayerOption generateLayerOption(id.toInt());
    layerOptions << generateLayerOption;
  }
  params.setLayerOptions(layerOptions);

  return params;
}

void GenerateGeodatabase::generateGeodatabaseFromCorners(double xCorner1, double yCorner1, double xCorner2, double yCorner2)
{
  // create an envelope from the QML rectangle corners
  const Point corner1 = m_mapView->screenToLocation(xCorner1, yCorner1);
  const Point corner2 = m_mapView->screenToLocation(xCorner2, yCorner2);
  const Envelope extent(corner1, corner2);
  const Geometry geodatabaseExtent = GeometryEngine::project(extent, SpatialReference::webMercator());

  // get the updated parameters
  GenerateGeodatabaseParameters params = getUpdatedParameters(geodatabaseExtent);

  // execute the task and obtain the job
  const QString outputGdb = m_tempPath.path() + "/wildfire.geodatabase";
  GenerateGeodatabaseJob* generateJob = m_syncTask->generateGeodatabase(params, outputGdb);

  // connect to the job's status changed signal
  if (generateJob)
  {
    connect(generateJob, &GenerateGeodatabaseJob::jobStatusChanged, this, [this, generateJob]()
    {
      // connect to the job's status changed signal to know once it is done
      switch (generateJob->jobStatus()) {
      case JobStatus::Failed:
        emit updateStatus("Generate failed");
        emit hideWindow(5000, false);
        break;
      case JobStatus::NotStarted:
        emit updateStatus("Job not started");
        break;
      case JobStatus::Paused:
        emit updateStatus("Job paused");
        break;
      case JobStatus::Started:
        emit updateStatus("In progress...");
        break;
      case JobStatus::Succeeded:
        emit updateStatus("Complete");
        emit hideWindow(1500, true);
        addOfflineData(generateJob->result());
        break;
      default:
        break;
      }
    });

    // start the generate job
    generateJob->start();
  }
  else
  {
    emit updateStatus("Generate failed");
    emit hideWindow(5000, false);
  }
}
//! [Features GenerateGeodatabase Part 2]

void GenerateGeodatabase::addOfflineData(Geodatabase* gdb)
{
  // remove the original online feature layers
  m_map->operationalLayers()->clear();

  // load the geodatabase
  connect(gdb, &Geodatabase::doneLoading, this, [this, gdb](Error)
  {
    // create a feature layer from each feature table, and add to the map
    for (GeodatabaseFeatureTable* featureTable : gdb->geodatabaseFeatureTables())
    {
      FeatureLayer* featureLayer = new FeatureLayer(featureTable, this);
      m_map->operationalLayers()->append(featureLayer);
    }

    // unregister geodatabase since there will be no edits uploaded
    m_syncTask->unregisterGeodatabase(gdb);
  });
  gdb->load();
}
