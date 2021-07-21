// [WriteFile Name=SketchOnMap, Category=DisplayInformation]
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

#ifndef SKETCHONMAP_H
#define SKETCHONMAP_H

namespace Esri
{
namespace ArcGISRuntime
{
class Map;
class MapQuickView;
class Graphic;
class GraphicsOverlay;
class SketchEditor;
}
}

#include <QObject>

class SketchOnMap : public QObject
{
  Q_OBJECT

  Q_PROPERTY(Esri::ArcGISRuntime::MapQuickView* mapView READ mapView WRITE setMapView NOTIFY mapViewChanged)

public:
  explicit SketchOnMap(QObject* parent = nullptr);
  ~SketchOnMap();

  Q_ENUMS(SampleSketchMode)
  enum class SampleSketchMode {
    PointSketchMode,
    MultipointSketchMode,
    PolylineSketchMode,
    PolygonSketchMode
  };

  static void init();
  Q_INVOKABLE void setSketchCreationMode(SampleSketchMode sketchCreationMode);
  Q_INVOKABLE void stopSketching(bool saveGeometry);
  Q_INVOKABLE void clearGraphics();
  Q_INVOKABLE void undo();
  Q_INVOKABLE void redo();

signals:
  void mapViewChanged();

private:
  Esri::ArcGISRuntime::MapQuickView* mapView() const;
  void setMapView(Esri::ArcGISRuntime::MapQuickView* mapView);
  void createConnections();

  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
  Esri::ArcGISRuntime::GraphicsOverlay* m_sketchOverlay = nullptr;
  Esri::ArcGISRuntime::SketchEditor* m_sketchEditor = nullptr;
  Esri::ArcGISRuntime::Graphic* editingGraphic = nullptr;
};

#endif // SKETCHONMAP_H
