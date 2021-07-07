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

#ifdef PCH_BUILD
#include "pch.hpp"
#endif // PCH_BUILD

#include "ShowLabelsOnLayers.h"

#include "ArcadeLabelExpression.h"
#include "FeatureLayer.h"
#include "LabelDefinition.h"
#include "Map.h"
#include "MapQuickView.h"
#include "ServiceFeatureTable.h"
#include "TextSymbol.h"

using namespace Esri::ArcGISRuntime;

ShowLabelsOnLayers::ShowLabelsOnLayers(QQuickItem* parent /* = nullptr */):
  QQuickItem(parent)
{
}

void ShowLabelsOnLayers::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<ShowLabelsOnLayers>("Esri.Samples", 1, 0, "ShowLabelsOnLayersSample");
}

void ShowLabelsOnLayers::componentComplete()
{
  QQuickItem::componentComplete();

  // find QML MapView component
  m_mapView = findChild<MapQuickView*>("mapView");

  // Create a map using the light gray basemap
  m_map = new Map(BasemapStyle::ArcGISLightGray, this);

  // Create a feature layer
  ServiceFeatureTable* featureTable = new ServiceFeatureTable(QUrl("https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/USA_115th_Congressional_Districts/FeatureServer/0"), this);
  FeatureLayer* featureLayer = new FeatureLayer(featureTable, this);
  connect(featureLayer, &FeatureLayer::doneLoading, [this, featureLayer](Error e)
  {
    if (!e.isEmpty())
      return;

    m_mapView->setViewpoint(Viewpoint(featureLayer->fullExtent().center(), 56759600));
  });
  m_map->operationalLayers()->append(featureLayer);

  // Apply labels to the feature layer
  LabelDefinition* republicanLabelDef = createRepublicanLabelDefinition();
  LabelDefinition* democratLabelDef = createDemocratLabelDefinition();
  featureLayer->labelDefinitions()->append(republicanLabelDef);
  featureLayer->labelDefinitions()->append(democratLabelDef);
  featureLayer->setLabelsEnabled(true);

  // Set map to map view
  m_mapView->setViewpointCenter(Point(-10846309.950860, 4683272.219411, SpatialReference::webMercator()), 20000000);
  m_mapView->setMap(m_map);
}

LabelDefinition* ShowLabelsOnLayers::createRepublicanLabelDefinition()
{
  // This particular LabelDefinition will have the following characteristics:
  // (1) The 'ArcadeLabelExpression' defines that the label text displayed comes from the fields 'NAME',
  //     the first letter of PARTY' (R or D), and 'CDFIPS' in the feature service in the format:
  //         Firstname Lastname (R)
  //         District #
  // (2) The 'TextSymbol' for the labeled text will be red with a white halo centered in the target polygon.
  // (3) The 'where' clause of the 'LabelDefinition' restricts the labels to data from Republican districts.

  ArcadeLabelExpression* republicanArcadeLabelExpression = new ArcadeLabelExpression("$feature.NAME + ' (' + left($feature.PARTY,1) + ')\\nDistrict ' + $feature.CDFIPS", this);

  TextSymbol* republicanTextSymbol = new TextSymbol(this);
  republicanTextSymbol->setSize(11);
  republicanTextSymbol->setColor(Qt::red);
  republicanTextSymbol->setHaloColor(Qt::white);
  republicanTextSymbol->setHaloWidth(2);
  republicanTextSymbol->setHorizontalAlignment(HorizontalAlignment::Center);
  republicanTextSymbol->setVerticalAlignment(VerticalAlignment::Middle);

  LabelDefinition* republicanLabelDefinition = new LabelDefinition(republicanArcadeLabelExpression, republicanTextSymbol, this);
  republicanLabelDefinition->setWhereClause("PARTY = 'Republican'");

  return republicanLabelDefinition;
}

LabelDefinition* ShowLabelsOnLayers::createDemocratLabelDefinition()
{
  // This particular LabelDefinition will have the following characteristics:
  // (1) The 'ArcadeLabelExpression' defines that the label text displayed comes from the fields 'NAME',
  //     the first letter of PARTY' (R or D), and 'CDFIPS' in the feature service in the format:
  //         Firstname Lastname (D)
  //         District #
  // (2) The 'TextSymbol' for the labeled text will be blue with a white halo centered in the target polygon.
  // (3) The 'where' clause of the 'LabelDefinition' restricts the labels to data from Democrat districts.

  ArcadeLabelExpression* democratArcadeLabelExpression = new ArcadeLabelExpression("$feature.NAME + ' (' + left($feature.PARTY,1) + ')\\nDistrict ' + $feature.CDFIPS", this);

  TextSymbol* democratTextSymbol = new TextSymbol(this);
  democratTextSymbol->setSize(11);
  democratTextSymbol->setColor(Qt::blue);
  democratTextSymbol->setHaloColor(Qt::white);
  democratTextSymbol->setHaloWidth(2);
  democratTextSymbol->setHorizontalAlignment(HorizontalAlignment::Center);
  democratTextSymbol->setVerticalAlignment(VerticalAlignment::Middle);

  LabelDefinition* democratLabelDefinition = new LabelDefinition(democratArcadeLabelExpression, democratTextSymbol, this);
  democratLabelDefinition->setWhereClause("PARTY = 'Democrat'");

  return democratLabelDefinition;
}
