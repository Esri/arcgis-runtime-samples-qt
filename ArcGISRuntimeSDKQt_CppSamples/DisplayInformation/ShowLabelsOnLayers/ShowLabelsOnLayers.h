// [WriteFile Name=ShowLabelsOnLayers, Category=DisplayInformation]
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

#ifndef SHOWLABELSONLAYERS_H
#define SHOWLABELSONLAYERS_H

namespace Esri
{
namespace ArcGISRuntime
{
class Map;
class MapQuickView;
class LabelDefinition;
}
}

#include <QQuickItem>

class ShowLabelsOnLayers : public QQuickItem
{
  Q_OBJECT

public:
  explicit ShowLabelsOnLayers(QQuickItem* parent = nullptr);
  ~ShowLabelsOnLayers() override = default;

  void componentComplete() override;
  static void init();

private:
  Esri::ArcGISRuntime::LabelDefinition* createRepublicanLabelDefinition();
  Esri::ArcGISRuntime::LabelDefinition* createDemocratLabelDefinition();

  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
};

#endif // SHOWLABELSONLAYERS_H
