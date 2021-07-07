// [WriteFile Name=DisplayOgcApiFeatureCollection, Category=Layers]
// [Legal]
// Copyright 2021 Esri.

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

#ifndef DisplayOgcApiFeatureCollection_H
#define DisplayOgcApiFeatureCollection_H

#include "QueryParameters.h"

namespace Esri
{
namespace ArcGISRuntime
{
class FeatureLayer;
class Map;
class MapQuickView;
class OgcFeatureCollectionTable;
class QueryParameters;
}
}

#include <QObject>

class DisplayOgcApiFeatureCollection : public QObject
{
  Q_OBJECT

  Q_PROPERTY(Esri::ArcGISRuntime::MapQuickView* mapView READ mapView WRITE setMapView NOTIFY mapViewChanged)

public:
  explicit DisplayOgcApiFeatureCollection(QObject* parent = nullptr);
  ~DisplayOgcApiFeatureCollection();

  static void init();

signals:
  void mapViewChanged();

private:
  Esri::ArcGISRuntime::MapQuickView* mapView() const;
  void setMapView(Esri::ArcGISRuntime::MapQuickView* mapView);
  void createQueryConnection();

  Esri::ArcGISRuntime::FeatureLayer* m_featureLayer = nullptr;
  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
  Esri::ArcGISRuntime::OgcFeatureCollectionTable* m_ogcFeatureCollectionTable = nullptr;
};

#endif // DisplayOgcApiFeatureCollection_H
