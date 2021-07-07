// [WriteFile Name=DisplayUtilityAssociations, Category=UtilityNetwork]
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

#include "DisplayUtilityAssociations.h"
#include "SymbolImageProvider.h"

#include "ArcGISFeatureTable.h"
#include "AttributeListModel.h"
#include "FeatureLayer.h"
#include "GraphicsOverlay.h"
#include "Map.h"
#include "MapQuickView.h"
#include "SimpleLineSymbol.h"
#include "UniqueValueRenderer.h"
#include "UtilityAssociation.h"
#include "UtilityElement.h"
#include "UtilityNetwork.h"
#include "UtilityNetworkDefinition.h"
#include "UtilityNetworkSource.h"
#include "UtilityNetworkTypes.h"

#include <QList>
#include <QImage>
#include <QQmlContext>

using namespace Esri::ArcGISRuntime;

namespace
{
const QString featureServerUrl("https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer");
const int maxScale = 2000;
constexpr int targetScale = 50;
}
DisplayUtilityAssociations::DisplayUtilityAssociations(QObject* parent /* = nullptr */):
  QObject(parent),
  m_map(new Map(BasemapStyle::ArcGISTopographic, this)),
  m_cred(new Credential("viewer01", "I68VGU^nMurF", this)),
  m_associationsOverlay(new GraphicsOverlay(this))
{
  m_utilityNetwork = new UtilityNetwork(featureServerUrl, m_cred, this);

  // create symbols for the associations
  m_attachmentSymbol = new SimpleLineSymbol(SimpleLineSymbolStyle::Dot, Qt::green, 5, this);
  m_connectivitySymbol = new SimpleLineSymbol(SimpleLineSymbolStyle::Dot, Qt::red, 5, this);

  connectSignals();
}

void DisplayUtilityAssociations::addAssociations()
{
  // check if current viewpoint is outside the max scale
  if(m_mapView->currentViewpoint(ViewpointType::CenterAndScale).targetScale() >= maxScale)
  {
    return;
  }

  // check if current viewpoint has a valid extent
  const Envelope extent = m_mapView->currentViewpoint(ViewpointType::BoundingGeometry).targetGeometry().extent();
  if (!extent.isValid())
  {
    qDebug("Extent not valid");
    return;
  }

  // get all the associations in the extent of the viewpoint
  m_utilityNetwork->associations(extent);
}

DisplayUtilityAssociations::~DisplayUtilityAssociations() = default;

void DisplayUtilityAssociations::init()
{
  // Register the map view for QML
  qmlRegisterType<MapQuickView>("Esri.Samples", 1, 0, "MapView");
  qmlRegisterType<DisplayUtilityAssociations>("Esri.Samples", 1, 0, "DisplayUtilityAssociationsSample");
}

MapQuickView* DisplayUtilityAssociations::mapView() const
{
  return m_mapView;
}

// Set the view (created in QML)
void DisplayUtilityAssociations::setMapView(MapQuickView* mapView)
{
  if (!mapView || mapView == m_mapView)
    return;

  m_mapView = mapView;
  m_mapView->setMap(m_map);

  m_mapView->graphicsOverlays()->append(m_associationsOverlay);

  // Get the image provider from the QML Engine
  QQmlEngine* engine = QQmlEngine::contextForObject(this)->engine();
  m_symbolImageProvider = new SymbolImageProvider();
  engine->addImageProvider(SymbolImageProvider::imageProviderId(), m_symbolImageProvider);

  connect(m_mapView, &MapQuickView::setViewpointCompleted, this, [this](bool succeeded)
  {
    if (!succeeded)
      return;

    addAssociations();
  });

  connect(m_mapView, &MapQuickView::navigatingChanged, this, [this]()
  {
    if (!m_mapView->isNavigating())
    {
      addAssociations();
    }
  });

  m_utilityNetwork->load();

  emit mapViewChanged();
}

void DisplayUtilityAssociations::connectSignals()
{
  connect(m_utilityNetwork, &UtilityNetwork::doneLoading, this, [this](const Error& error)
  {
    if (!error.isEmpty())
    {
      qDebug() << error.message() << error.additionalMessage();
      return;
    }

    m_mapView->setViewpoint(Viewpoint(Point(-9812698.37297436, 5131928.33743317, SpatialReference::webMercator()), targetScale));

    // get all the edges and junctions in the network
    QList<UtilityNetworkSource*> edges;
    QList<UtilityNetworkSource*> junctions;
    QList<UtilityNetworkSource*> allSources = m_utilityNetwork->definition()->networkSources();

    for (UtilityNetworkSource* networkSource : allSources)
    {
      if (networkSource->sourceType() == UtilityNetworkSourceType::Edge)
      {
        edges.append(networkSource);
      }
      else if (networkSource->sourceType() == UtilityNetworkSourceType::Junction)
      {
        junctions.append(networkSource);
      }
    }

    // add all edges that are not subnet lines to the map
    for (UtilityNetworkSource* source : edges)
    {
      if (source->sourceUsageType() != UtilityNetworkSourceUsageType::SubnetLine && source->featureTable() != nullptr)
      {
        m_map->operationalLayers()->append(new FeatureLayer(source->featureTable(), this));
      }
    }

    // add all junctions to the map
    for (UtilityNetworkSource* source : junctions)
    {
      if (source->featureTable())
      {
        m_map->operationalLayers()->append(new FeatureLayer(source->featureTable(), this));
      }
    }

    // create a renderer for the associations
    UniqueValue* attachmentValue = new UniqueValue("Attachment", "",
                                                   QVariantList{static_cast<int>(UtilityAssociationType::Attachment)}, m_attachmentSymbol, this);
    UniqueValue* connectivityValue = new UniqueValue("Connectivity", "",
                                                     QVariantList{static_cast<int>(UtilityAssociationType::Connectivity)}, m_connectivitySymbol, this);
    UniqueValueRenderer* uniqueValueRenderer = new UniqueValueRenderer("", nullptr,
                                                                       QStringList{"AssociationType"}, QList<UniqueValue*>{attachmentValue, connectivityValue}, this);
    m_associationsOverlay->setRenderer(uniqueValueRenderer);

    // populate the legend
    m_attachmentSymbol->createSwatch();
    m_connectivitySymbol->createSwatch();
  });

  connect(m_utilityNetwork, &UtilityNetwork::associationsCompleted, this, [this](QUuid, const QList<UtilityAssociation*>& associations)
  {
    const GraphicListModel* graphics = m_associationsOverlay->graphics();

    for (UtilityAssociation* association : associations)
    {

      // check if the graphics overlay already contains the association
      const bool uniqueGraphic = std::none_of(graphics->begin(), graphics->end(), [association](const Graphic* graphic)
      {
        const AttributeListModel* attributes = graphic->attributes();
        return attributes->containsAttribute("GlobalId") && qvariant_cast<QUuid>((*graphic->attributes())["GlobalId"]) == association->globalId();
      });

      if (uniqueGraphic)
      {
        // add a graphic for the association
        QVariantMap graphicAttributes;
        graphicAttributes["GlobalId"] = association->globalId();
        graphicAttributes["AssociationType"] = static_cast<int>(association->associationType());
        Graphic* graphic = new Graphic(association->geometry(), graphicAttributes, this);

        m_associationsOverlay->graphics()->append(graphic);
      }
    }
  });

  connect(m_attachmentSymbol, &Symbol::createSwatchCompleted, this, [this](QUuid id, QImage image)
  {
    if (!m_symbolImageProvider)
      return;

    // convert the QUuid into a QString
    const QString imageId = id.toString().remove("{").remove("}");

    // add the image to the provider
    m_symbolImageProvider->addImage(imageId, image);

    // update the URL with the unique id
    m_attachmentSymbolUrl = QString("image://%1/%2").arg(SymbolImageProvider::imageProviderId(), imageId);

    // emit the signal to trigger the QML Image to update
    emit attachmentSymbolUrlChanged();
  });

  connect(m_connectivitySymbol, &Symbol::createSwatchCompleted, this, [this](QUuid id, QImage image)
  {
    if (!m_symbolImageProvider)
      return;

    // convert the QUuid into a QString
    const QString imageId = id.toString().remove("{").remove("}");

    // add the image to the provider
    m_symbolImageProvider->addImage(imageId, image);

    // update the URL with the unique id
    m_connectivitySymbolUrl = QString("image://%1/%2").arg(SymbolImageProvider::imageProviderId(), imageId);

    // emit the signal to trigger the QML Image to update
    emit connectivitySymbolUrlChanged();
  });
}

QString DisplayUtilityAssociations::attachmentSymbolUrl() const
{
  return m_attachmentSymbolUrl;
}

QString DisplayUtilityAssociations::connectivitySymbolUrl() const
{
  return m_connectivitySymbolUrl;
}
