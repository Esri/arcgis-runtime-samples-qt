// [WriteFile Name=EditAndSyncFeatures, Category=EditData]
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

#include "EditAndSyncFeatures.h"

#include "Map.h"
#include "MapQuickView.h"
#include "TileCache.h"
#include "ArcGISTiledLayer.h"
#include "Basemap.h"
#include "Viewpoint.h"
#include "Envelope.h"
#include "GenerateGeodatabaseParameters.h"
#include "ServiceFeatureTable.h"
#include "FeatureLayer.h"
#include "GeodatabaseSyncTask.h"
#include "GeodatabaseFeatureTable.h"
#include "GeometryEngine.h"
#include "Geodatabase.h"
#include "Point.h"

#include <QUrl>
#include <QDir>
#include <QtCore/qglobal.h>

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

EditAndSyncFeatures::EditAndSyncFeatures(QQuickItem* parent /* = nullptr */):
  QQuickItem(parent),
  m_dataPath(defaultDataPath() + "/ArcGIS/Runtime/Data/")
{
}

EditAndSyncFeatures::~EditAndSyncFeatures()
{
  // unregister geodatabase
  m_syncTask->unregisterGeodatabase(m_offlineGdb);
}

void EditAndSyncFeatures::init()
{
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<EditAndSyncFeatures>("Esri.Samples", 1, 0, "EditAndSyncFeaturesSample");
}

void EditAndSyncFeatures::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");
  m_mapView->setWrapAroundMode(WrapAroundMode::Disabled);

  // Create a map using a local tile package
  TileCache* tileCache = new TileCache(m_dataPath + "tpkx/SanFrancisco.tpkx", this);
  ArcGISTiledLayer* tiledLayer = new ArcGISTiledLayer(tileCache, this);
  Basemap* basemap = new Basemap(tiledLayer, this);
  m_map = new Map(basemap, this);

  // add a feature service to the map
  ServiceFeatureTable* featureTable = new ServiceFeatureTable(QUrl(m_featureServiceUrl + QString::number(m_featureLayerId)), this);
  FeatureLayer* featureLayer = new FeatureLayer(featureTable, this);
  m_map->operationalLayers()->append(featureLayer);

  // set an initial viewpoint
  Envelope env(-122.50017, 37.74500, -122.43843, 37.81638, SpatialReference(4326));
  Viewpoint viewpoint(env);
  m_map->setInitialViewpoint(viewpoint);

  // Set map to map view
  m_mapView->setMap(m_map);

  // create the GeodatabaseSyncTask
  m_syncTask = new GeodatabaseSyncTask(QUrl(m_featureServiceUrl), this);

  connectSignals();
}

void EditAndSyncFeatures::connectSignals()
{
  // lambda expression for the mouse clicked signal on the mapview
  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent& mouseEvent)
  {
    if (m_isOffline)
    {
      if (!m_selectedFeature)
      {
        m_mapView->identifyLayer(m_map->operationalLayers()->first(), mouseEvent.x(), mouseEvent.y(), 5, false, 1);
      }
      else
      {
        // connect to feature table signal
        FeatureLayer* featureLayer = static_cast<FeatureLayer*>(m_map->operationalLayers()->at(0));
        connect(featureLayer->featureTable(), &GeodatabaseFeatureTable::updateFeatureCompleted, this, [this, featureLayer](QUuid, bool success)
        {
          if (success)
          {
            featureLayer->clearSelection();
            m_selectedFeature = nullptr;
            emit updateInstruction("Tap the sync button");
            emit showButton();
          }
        });

        // get the point from the mouse point
        Point mapPoint = m_mapView->screenToLocation(mouseEvent.x(), mouseEvent.y());
        m_selectedFeature->setGeometry(mapPoint);
        featureLayer->featureTable()->updateFeature(m_selectedFeature);
      }
    }
  });

  // once the identify is done
  connect(m_mapView, &MapQuickView::identifyLayerCompleted, this, [this](QUuid, Esri::ArcGISRuntime::IdentifyLayerResult* identifyResult)
  {
    if (!identifyResult)
      return;

    // clear any existing selection
    FeatureLayer* featureLayer = static_cast<FeatureLayer*>(m_map->operationalLayers()->first());
    featureLayer->clearSelection();
    m_selectedFeature = nullptr;

    if (identifyResult->geoElements().length() > 0)
    {
      GeoElement* geoElement = identifyResult->geoElements().at(0);
      m_selectedFeature = static_cast<ArcGISFeature*>(geoElement);
      featureLayer->selectFeature(m_selectedFeature);
      emit updateInstruction("Tap on map to move feature");
    }
  });
}

//! [EditAndSyncFeatures parameters generate]
GenerateGeodatabaseParameters EditAndSyncFeatures::getGenerateParameters(Envelope gdbExtent)
{
  // create the parameters
  GenerateGeodatabaseParameters params;
  params.setReturnAttachments(false);
  params.setOutSpatialReference(SpatialReference::webMercator());
  params.setExtent(gdbExtent);

  // set the layer options for 1 layer
  QList<GenerateLayerOption> layerOptions;
  GenerateLayerOption generateLayerOption(m_featureLayerId);
  layerOptions << generateLayerOption;
  params.setLayerOptions(layerOptions);

  return params;
}
//! [EditAndSyncFeatures parameters generate]

//! [EditAndSyncFeatures parameters sync]
SyncGeodatabaseParameters EditAndSyncFeatures::getSyncParameters()
{
  // create the parameters
  SyncGeodatabaseParameters params;
  params.setGeodatabaseSyncDirection(SyncDirection::Bidirectional);

  // set the layer options for 1 layer
  QList<SyncLayerOption> layerOptions;
  SyncLayerOption syncLayerOption(m_featureLayerId);
  layerOptions << syncLayerOption;
  params.setLayerOptions(layerOptions);

  return params;
}
//! [EditAndSyncFeatures parameters sync]

//! [EditAndSyncFeatures generate]
void EditAndSyncFeatures::generateGeodatabaseFromCorners(double xCorner1, double yCorner1, double xCorner2, double yCorner2)
{
  // create an envelope from the QML rectangle corners
  const Point corner1 = m_mapView->screenToLocation(xCorner1, yCorner1);
  const Point corner2 = m_mapView->screenToLocation(xCorner2, yCorner2);
  const Envelope extent(corner1, corner2);
  const Geometry geodatabaseExtent = GeometryEngine::project(extent, SpatialReference::webMercator());

  // get the updated parameters
  GenerateGeodatabaseParameters params = getGenerateParameters(geodatabaseExtent);

  // execute the task and obtain the job
  const QString outputGdb = m_temporaryDir.path() + "/Wildfire.geodatabase";
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
        m_isOffline = true;
        m_offlineGdb = generateJob->result();
        emit isOfflineChanged();
        emit updateStatus("Complete");
        emit hideWindow(1500, true);
        emit updateInstruction("Tap on a feature");
        addOfflineData();
        break;
      default:
        break;
      }
    });

    // start the generate job
    generateJob->start();
  }
  //! [EditAndSyncFeatures generate]
  else
  {
    emit updateStatus("Generate failed");
    emit hideWindow(5000, false);
  }
}

void EditAndSyncFeatures::addOfflineData()
{
  // remove the original online feature layers
  m_map->operationalLayers()->clear();

  // load the geodatabase
  connect(m_offlineGdb, &Geodatabase::doneLoading, this, [this](Error)
  {
    // create a feature layer from each feature table, and add to the map
    for (GeodatabaseFeatureTable* featureTable : m_offlineGdb->geodatabaseFeatureTables())
    {
      FeatureLayer* featureLayer = new FeatureLayer(featureTable, this);
      m_map->operationalLayers()->append(featureLayer);
    }
  });
  m_offlineGdb->load();
}

bool EditAndSyncFeatures::isOffline() const
{
  return m_isOffline;
}

//! [EditAndSyncFeatures executeSync]
void EditAndSyncFeatures::executeSync()
{
  // get the updated parameters
  SyncGeodatabaseParameters params = getSyncParameters();

  // execute the task and obtain the job
  SyncGeodatabaseJob* syncJob = m_syncTask->syncGeodatabase(params, m_offlineGdb);

  // connect to the job's status changed signal
  if (syncJob)
  {
    connect(syncJob, &GenerateGeodatabaseJob::jobStatusChanged, this, [this, syncJob]()
    {
      // connect to the job's status changed signal to know once it is done
      switch (syncJob->jobStatus()) {
      case JobStatus::Failed:
        emit updateStatus("Sync failed");
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
        m_isOffline = true;
        emit isOfflineChanged();
        emit updateStatus("Complete");
        emit hideWindow(1500, true);
        emit updateInstruction("Tap on a feature");
        break;
      default:
        break;
      }
    });

    // start the sync job
    syncJob->start();
  }
  //! [EditAndSyncFeatures executeSync]
  else
  {
    emit updateStatus("Sync failed");
    emit hideWindow(5000, false);
  }
}

