// [WriteFile Name=GetElevationAtPoint, Category=Analysis]
// [Legal]
// Copyright 2018 Esri.

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

#ifndef GETELEVATIONATPOINT_H
#define GETELEVATIONATPOINT_H

namespace Esri
{
  namespace ArcGISRuntime
  {
    class Scene;
    class SceneQuickView;
    class GraphicsOverlay;
    class Graphic;
  }
}

class QMouseEvent;

#include <QObject>
#include <QUuid>


class GetElevationAtPoint : public QObject
{
    Q_OBJECT

    Q_PROPERTY(Esri::ArcGISRuntime::SceneQuickView* sceneView READ sceneView WRITE setSceneView NOTIFY sceneViewChanged)
    Q_PROPERTY(double elevation READ elevation NOTIFY elevationChanged)

public:
    explicit GetElevationAtPoint(QObject* parent = nullptr);
    ~GetElevationAtPoint();

    static void init();


private slots:
     void displayElevationOnClick(QMouseEvent& mouseEvent);

signals:
    void sceneViewChanged();
    void elevationChanged(double newElevation);

private:
    Esri::ArcGISRuntime::SceneQuickView* sceneView() const;
    void setSceneView(Esri::ArcGISRuntime::SceneQuickView* sceneView);

    Esri::ArcGISRuntime::Scene* m_scene = nullptr;
    Esri::ArcGISRuntime::SceneQuickView* m_sceneView = nullptr;

    Esri::ArcGISRuntime::GraphicsOverlay* m_graphicsOverlay = nullptr;
    Esri::ArcGISRuntime::Graphic* m_elevationMarker = nullptr;

    double elevation() const;
    double m_elevation = 0.0;
};

#endif // GETELEVATIONATPOINT_H