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

#ifndef PERFORMVALVEISOLATIONTRACE_H
#define PERFORMVALVEISOLATIONTRACE_H

namespace Esri
{
namespace ArcGISRuntime
{
class ArcGISFeature;
class Credential;
class FeatureLayer;
class GraphicsOverlay;
class Map;
class MapQuickView;
class UtilityCategory;
class UtilityElement;
class UtilityNetwork;
class UtilityTraceConfiguration;
class UtilityTraceParameters;
class IdentifyLayerResult;
class ServiceGeodatabase;
}
}

#include <QObject>
#include <Point.h>

class PerformValveIsolationTrace : public QObject
{
  Q_OBJECT

  Q_PROPERTY(Esri::ArcGISRuntime::MapQuickView* mapView READ mapView WRITE setMapView NOTIFY mapViewChanged)
  Q_PROPERTY(QStringList categoriesList READ categoriesList NOTIFY categoriesListChanged)
  Q_PROPERTY(int selectedIndex MEMBER m_selectedIndex NOTIFY selectedIndexChanged)
  Q_PROPERTY(bool isolateFeatures MEMBER m_isolateFeatures NOTIFY isolateFeaturesChanged)
  Q_PROPERTY(bool tasksRunning READ tasksRunning NOTIFY tasksRunningChanged)
  Q_PROPERTY(bool noResults READ noResults NOTIFY noResultsChanged)
  Q_PROPERTY(QStringList terminals MEMBER m_terminals NOTIFY terminalsChanged)

public:
  explicit PerformValveIsolationTrace(QObject* parent = nullptr);
  ~PerformValveIsolationTrace();

  static void init();
  Q_INVOKABLE void performTrace();
  Q_INVOKABLE void performReset();
  Q_INVOKABLE void selectedTerminal(int index);

private slots:
  void onIdentifyLayersCompleted(QUuid, const QList<Esri::ArcGISRuntime::IdentifyLayerResult*>& results);

signals:
  void mapViewChanged();
  void categoriesListChanged();
  void selectedIndexChanged();
  void isolateFeaturesChanged();
  void tasksRunningChanged();
  void noResultsChanged();
  void terminalsChanged();

private:
  Esri::ArcGISRuntime::MapQuickView* mapView() const;
  void setMapView(Esri::ArcGISRuntime::MapQuickView* mapView);
  QStringList categoriesList() const;
  bool tasksRunning() const;
  bool noResults() const;
  void connectSignals();

  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::Credential* m_cred = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
  Esri::ArcGISRuntime::GraphicsOverlay* m_startingLocationOverlay = nullptr;
  Esri::ArcGISRuntime::GraphicsOverlay* m_filterBarriersOverlay = nullptr;
  Esri::ArcGISRuntime::UtilityElement* m_startingLocation = nullptr;
  Esri::ArcGISRuntime::UtilityElement* m_element = nullptr;
  Esri::ArcGISRuntime::UtilityNetwork* m_utilityNetwork = nullptr;
  Esri::ArcGISRuntime::UtilityTraceConfiguration* m_traceConfiguration = nullptr;
  Esri::ArcGISRuntime::ServiceGeodatabase* m_serviceGeodatabase = nullptr;
  Esri::ArcGISRuntime::Point m_clickPoint;
  QList<Esri::ArcGISRuntime::UtilityElement*> m_filterBarriers;
  QStringList m_terminals;
  QScopedPointer<QObject> m_graphicParent;
  QStringList m_categoriesList;
  int m_selectedIndex = -1;
  bool m_isolateFeatures = false;
  bool m_tasksRunning = false;
  bool m_traceRunning = false;
  bool m_noResults = false;
};

#endif // PERFORMVALVEISOLATIONTRACE_H
