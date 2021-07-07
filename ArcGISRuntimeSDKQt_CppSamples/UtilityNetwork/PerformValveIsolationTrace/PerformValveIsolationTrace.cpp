// [WriteFile Name=PerformValveIsolationTrace, Category=UtilityNetwork]
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

#include "PerformValveIsolationTrace.h"

#include "ArcGISFeatureListModel.h"
#include "FeatureLayer.h"
#include "FeatureQueryResult.h"
#include "Graphic.h"
#include "GraphicsOverlay.h"
#include "Map.h"
#include "MapQuickView.h"
#include "Point.h"
#include "QueryParameters.h"
#include "ServiceFeatureTable.h"
#include "ServiceGeodatabase.h"
#include "SimpleMarkerSymbol.h"
#include "SimpleRenderer.h"
#include "UtilityTraceResultListModel.h"
#include "UtilityAssetGroup.h"
#include "UtilityAssetType.h"
#include "UtilityCategory.h"
#include "UtilityCategoryComparison.h"
#include "UtilityDomainNetwork.h"
#include "UtilityElement.h"
#include "UtilityElementTraceResult.h"
#include "UtilityNetwork.h"
#include "UtilityNetworkDefinition.h"
#include "UtilityNetworkSource.h"
#include "UtilityNetworkTypes.h"
#include "UtilityTerminal.h"
#include "UtilityTerminalConfiguration.h"
#include "UtilityTier.h"
#include "UtilityTraceConfiguration.h"
#include "UtilityTraceFilter.h"
#include "UtilityTraceParameters.h"
#include "GeometryEngine.h"

#include <QUuid>

using namespace Esri::ArcGISRuntime;

namespace 
{
const QString featureServiceUrl = QStringLiteral("https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleGas/FeatureServer");
const QString domainNetworkName = QStringLiteral("Pipeline");
const QString tierName = QStringLiteral("Pipe Distribution System");
const QString networkSourceName = QStringLiteral("Gas Device");
const QString assetGroupName = QStringLiteral("Meter");
const QString assetTypeName = QStringLiteral("Customer");
const QString globalId = QStringLiteral("{98A06E95-70BE-43E7-91B7-E34C9D3CB9FF}");
const QString sampleServer7Username = QStringLiteral("viewer01");
const QString sampleServer7Password = QStringLiteral("I68VGU^nMurF");
}

namespace
{
// Convenient RAII template struct that deletes all pointers in a given container.
template <typename T>
struct ScopedCleanup
{
  ScopedCleanup(const QList<T*>& list) : results(list) { }
  ~ScopedCleanup() { qDeleteAll(results); }
  const QList<T*>& results;
};
}

PerformValveIsolationTrace::PerformValveIsolationTrace(QObject* parent /* = nullptr */):
  QObject(parent),
  m_map(new Map(BasemapStyle::ArcGISStreetsNight, this)),
  m_startingLocationOverlay(new GraphicsOverlay(this)),
  m_filterBarriersOverlay(new GraphicsOverlay(this)),
  m_cred(new Credential{sampleServer7Username, sampleServer7Password, this}),
  m_graphicParent(new QObject())
{
  // create service geodatabase with the feature service url
  m_serviceGeodatabase = new ServiceGeodatabase(featureServiceUrl, m_cred, this);

  // disable UI while loading service geodatabase and utility network
  m_tasksRunning = true;
  emit tasksRunningChanged();

  connect(m_serviceGeodatabase, &ServiceGeodatabase::doneLoading, this, [this](Error error)
  {
    if (m_utilityNetwork->loadStatus() == LoadStatus::Loaded)
    {
      // re-enable UI if both service geodatabase and utility network are loaded
      m_tasksRunning = false;
      emit tasksRunningChanged();
    }

    if (!error.isEmpty())
      return;

    // obtain service feature tables from the service geodatabase
    ServiceFeatureTable* lineLayerTable = m_serviceGeodatabase->table(3);
    ServiceFeatureTable* deviceLayerTable = m_serviceGeodatabase->table(0);

    // create feature layers from the service feature tables
    FeatureLayer* lineLayer = new FeatureLayer(lineLayerTable, this);
    FeatureLayer* deviceLayer = new FeatureLayer(deviceLayerTable, this);

    // add the feature layers to the map
    m_map->operationalLayers()->append(lineLayer);
    m_map->operationalLayers()->append(deviceLayer);
  });
  m_serviceGeodatabase->load();

  m_utilityNetwork = new UtilityNetwork(featureServiceUrl, m_map, m_cred, this);
  connectSignals();
  m_utilityNetwork->load();
}

PerformValveIsolationTrace::~PerformValveIsolationTrace() = default;

void PerformValveIsolationTrace::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<PerformValveIsolationTrace>("Esri.Samples", 1, 0, "PerformValveIsolationTraceSample");
}

MapQuickView* PerformValveIsolationTrace::mapView() const
{
  return m_mapView;
}

// Set the view (created in QML)
void PerformValveIsolationTrace::setMapView(MapQuickView* mapView)
{
  if (!mapView || mapView == m_mapView)
    return;

  m_mapView = mapView;
  m_mapView->setMap(m_map);

  connect(m_mapView, &MapQuickView::mouseClicked, this, [this](QMouseEvent mouseEvent)
  {
    if (m_map->loadStatus() != LoadStatus::Loaded)
      return;

    constexpr double tolerance = 10.0;
    constexpr bool returnPopups = false;
    m_clickPoint = m_mapView->screenToLocation(mouseEvent.x(), mouseEvent.y());
    m_mapView->identifyLayers(mouseEvent.x(), mouseEvent.y(), tolerance, returnPopups);
  });

  // handle the identify resultss
  connect(m_mapView, &MapQuickView::identifyLayersCompleted, this, &PerformValveIsolationTrace::onIdentifyLayersCompleted);

  // apply renderers
  SimpleMarkerSymbol* startingPointSymbol = new SimpleMarkerSymbol(SimpleMarkerSymbolStyle::Cross, Qt::green, 25, this);
  m_startingLocationOverlay->setRenderer(new SimpleRenderer(startingPointSymbol, this));

  SimpleMarkerSymbol* filterBarrierSymbol = new SimpleMarkerSymbol(SimpleMarkerSymbolStyle::X, Qt::red, 25, this);
  m_filterBarriersOverlay->setRenderer(new SimpleRenderer(filterBarrierSymbol, this));

  m_mapView->graphicsOverlays()->append(m_startingLocationOverlay);
  m_mapView->graphicsOverlays()->append(m_filterBarriersOverlay);

  emit mapViewChanged();
}

QStringList PerformValveIsolationTrace::categoriesList() const
{
  if (!m_utilityNetwork)
    return { };

  if (m_utilityNetwork->loadStatus() != LoadStatus::Loaded)
    return { };

  const QList<UtilityCategory*> categories = m_utilityNetwork->definition()->categories();
  QStringList strList;
  for (UtilityCategory* category : categories)
  {
    strList << category->name();
  }
  return strList;
}

void PerformValveIsolationTrace::performTrace()
{
  if (m_selectedIndex < 0)
    return;

  // disable UI while trace is run
  m_tasksRunning = true;
  emit tasksRunningChanged();

  for (Layer* layer : *m_map->operationalLayers())
  {
    // clear previous selection from the feature layers
    FeatureLayer* featureLayer = dynamic_cast<FeatureLayer*>(layer);
   if (featureLayer)
     featureLayer->clearSelection();
  }

  const QList<UtilityCategory*> categories = m_utilityNetwork->definition()->categories();

  // get the selected utility category
  if (categories[m_selectedIndex] != nullptr)
  {
    // set whether to include isolated features
    m_traceConfiguration->setIncludeIsolatedFeatures(m_isolateFeatures);

    UtilityTraceParameters* traceParameters = new UtilityTraceParameters(UtilityTraceType::Isolation, QList<UtilityElement*> {m_startingLocation}, this);
    traceParameters->setTraceConfiguration(m_traceConfiguration);

    // reset trace configuration filter barriers
    m_traceConfiguration->setFilter(new UtilityTraceFilter(this));

    // set the user selected filter barriers otherwise
    // set the category comparison to the barriers of the configuration's trace filter
    if (!m_filterBarriers.empty())
    {
      traceParameters->setFilterBarriers(m_filterBarriers);
    }
    else
    {
      UtilityCategory* selectedCategory = categories[m_selectedIndex];
      UtilityCategoryComparison* categoryComparison = new UtilityCategoryComparison(selectedCategory, UtilityCategoryComparisonOperator::Exists, this);
      traceParameters->traceConfiguration()->filter()->setBarriers(categoryComparison);
    }
    m_utilityNetwork->trace(traceParameters);
  }
}

void PerformValveIsolationTrace::performReset()
{
  m_filterBarriersOverlay->graphics()->clear();
  m_filterBarriers.clear();
  m_traceConfiguration->setFilter(new UtilityTraceFilter(this));
  m_graphicParent.reset(new QObject());

  for (Layer* layer : *m_map->operationalLayers())
  {
    // clear previous selection from the feature layers
    FeatureLayer* featureLayer = dynamic_cast<FeatureLayer*>(layer);
   if (featureLayer)
     featureLayer->clearSelection();
  }
}

void PerformValveIsolationTrace::connectSignals()
{
  connect(m_utilityNetwork, &UtilityNetwork::doneLoading, this, [this](const Error& error)
  {
    if (m_serviceGeodatabase->loadStatus() == LoadStatus::Loaded)
    {
      // re-enable UI if both service geodatabase and utility network are loaded
      m_tasksRunning = false;
      emit tasksRunningChanged();
    }

    if (!error.isEmpty())
    {
      qDebug() << error.message() << error.additionalMessage();
      return;
    }

    if (m_utilityNetwork->loadStatus() != LoadStatus::Loaded)
      return;

    // get a trace configuration from a tier
    UtilityNetworkDefinition* networkDefinition = m_utilityNetwork->definition();
    UtilityDomainNetwork* domainNetwork = networkDefinition->domainNetwork(domainNetworkName);
    if (domainNetwork)
    {
      UtilityTier* tier = domainNetwork->tier(tierName);
      if (tier)
      {
        m_traceConfiguration = tier->traceConfiguration();
      }
    }

    if (!m_traceConfiguration)
      return;

    // create a trace filter
    m_traceConfiguration->setFilter(new UtilityTraceFilter(this));

    // get a default starting location
    UtilityNetworkSource* networkSource = networkDefinition->networkSource(networkSourceName);
    if (networkSource)
    {
      UtilityAssetGroup* assetGroup = networkSource->assetGroup(assetGroupName);
      if (assetGroup)
      {
        UtilityAssetType* assetType = assetGroup->assetType(assetTypeName);
        if (assetType)
        {
          m_startingLocation = m_utilityNetwork->createElementWithAssetType(assetType, QUuid(globalId), nullptr, this);
        }
      }
    }

    if (!m_startingLocation)
      return;

    // display starting location
    m_utilityNetwork->featuresForElements(QList<UtilityElement*> {m_startingLocation});

    // populate the combo box choices
    m_categoriesList = categoriesList();
    emit categoriesListChanged();
  });

  connect(m_utilityNetwork, &UtilityNetwork::traceCompleted, this, [this](QUuid)
  {
    // local paret to clean up UtilityElementTraceResult when we leave scope.
    QObject localParent;

    m_tasksRunning = false;
    emit tasksRunningChanged();

    UtilityTraceResultListModel* utilityTraceResultList = m_utilityNetwork->traceResult();

    if (utilityTraceResultList->isEmpty())
    {
      m_noResults = true;
      emit noResultsChanged();
      return;
    }

    UtilityElementTraceResult* utilityElementTraceResult = dynamic_cast<UtilityElementTraceResult*>(utilityTraceResultList->at(0));
    if (utilityElementTraceResult)
    {
      // given local parent to clean up once we leave scope
      utilityElementTraceResult->setParent(&localParent);

      QList<UtilityElement*> utilityElementList = utilityElementTraceResult->elements(this);

      // A convenience wrapper that deletes the contents of utilityElementList when we leave scope.
      ScopedCleanup<UtilityElement> utilityElementListCleanUp(utilityElementList);

      if (utilityElementList.empty())
      {
        m_noResults = true;
        emit noResultsChanged();
        return;
      }

      // iterate through the map's features
      for (Layer* layer : *m_map->operationalLayers())
      {
        FeatureLayer* featureLayer = dynamic_cast<FeatureLayer*>(layer);
        if (featureLayer)
        {
          // create query parameters to find features whose network source names match layer's feature table name
          QueryParameters queryParameters;
          QList<qint64> objectIds = {};

          for (UtilityElement* utilityElement : utilityElementList)
          {
            const QString networkSourceName = utilityElement->networkSource()->name();
            const QString featureTableName = featureLayer->featureTable()->tableName();
            if (networkSourceName == featureTableName)
            {
              objectIds.append(utilityElement->objectId());
            }
          }
          queryParameters.setObjectIds(objectIds);
          featureLayer->selectFeatures(queryParameters, SelectionMode::New);
        }
      }
    }
  });

  connect(m_utilityNetwork, &UtilityNetwork::featuresForElementsCompleted, this, [this](QUuid)
  {
    // display starting location
    ArcGISFeatureListModel* elementFeaturesList = m_utilityNetwork->featuresForElementsResult();
    const Point startingLocationGeometry = elementFeaturesList->first()->geometry();
    Graphic* graphic = new Graphic(startingLocationGeometry, m_graphicParent.get());
    m_startingLocationOverlay->graphics()->append(graphic);

    constexpr double scale = 3000.0;
    m_mapView->setViewpointCenter(startingLocationGeometry, scale);
    m_tasksRunning = false;
    emit tasksRunningChanged();
  });
}

bool PerformValveIsolationTrace::noResults() const
{
  return m_noResults;
}

bool PerformValveIsolationTrace::tasksRunning() const
{
  return m_tasksRunning;
}

void PerformValveIsolationTrace::onIdentifyLayersCompleted(QUuid, const QList<IdentifyLayerResult*>& results)
{
  // A convenience wrapper that deletes the contents of results when we leave scope.
  ScopedCleanup<IdentifyLayerResult> resultsScopedCleanup(results);

  // could not identify location
  if (results.isEmpty())
    return;

  const IdentifyLayerResult* result = results[0];
  ArcGISFeature* feature = static_cast<ArcGISFeature*>(result->geoElements()[0]);
  m_element = m_utilityNetwork->createElementWithArcGISFeature(feature);

  const UtilityNetworkSourceType elementSourceType = m_element->networkSource()->sourceType();

  if (elementSourceType == UtilityNetworkSourceType::Junction)
  {
    QList<UtilityTerminal*> terminals = m_element->assetType()->terminalConfiguration()->terminals();

    if (terminals.size() > 1)
    {
      m_terminals.clear();
      for (UtilityTerminal* terminal : terminals)
      {
        m_terminals.append(terminal->name());
      }
      emit terminalsChanged();
      return;
    }
  }
  else if (elementSourceType == UtilityNetworkSourceType::Edge)
  {
    if (feature->geometry().geometryType() == GeometryType::Polyline)
    {
      const Polyline line = GeometryEngine::removeZ(feature->geometry());
      // Set how far the element is along the edge.
      const double fraction = GeometryEngine::fractionAlong(line, m_clickPoint, -1);
      m_element->setFractionAlongEdge(fraction);
    }
  }

  m_filterBarriersOverlay->graphics()->append(new Graphic(m_clickPoint, m_graphicParent.get()));
  m_filterBarriers.append(m_element);
}

void PerformValveIsolationTrace::selectedTerminal(int index)
{
  UtilityTerminal* selectedTerminal = m_element->assetType()->terminalConfiguration()->terminals().at(index);
  m_element->setTerminal(selectedTerminal);

  m_filterBarriersOverlay->graphics()->append(new Graphic(m_clickPoint, m_graphicParent.get()));
  m_filterBarriers.append(m_element);
}
