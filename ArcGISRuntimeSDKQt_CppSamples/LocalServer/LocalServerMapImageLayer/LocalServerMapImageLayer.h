// [WriteFile Name=LocalServerMapImageLayer, Category=LocalServer]
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

#ifndef LOCAL_SERVER_MAPIMAGELAYER_H
#define LOCAL_SERVER_MAPIMAGELAYER_H

namespace Esri
{
  namespace ArcGISRuntime
  {
    class Map;
    class MapQuickView;
    class LocalServer;
    class LocalMapService;
  }
}

class QTemporaryDir;

#include <QQuickItem>

class LocalServerMapImageLayer : public QQuickItem
{
  Q_OBJECT

public:
  explicit LocalServerMapImageLayer(QQuickItem* parent = nullptr);
  ~LocalServerMapImageLayer() override;

  void componentComplete() override;
  static void init();

private:
  void connectSignals();
  QString shortestTempPath();

private:
  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
  Esri::ArcGISRuntime::LocalMapService* m_localMapService = nullptr;
  std::unique_ptr<QTemporaryDir> m_tempDir;
};

#endif // LOCAL_SERVER_MAPIMAGELAYER_H

