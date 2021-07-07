// [WriteFile Name=FindPlace, Category=Search]
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

#ifndef FINDPLACE_H
#define FINDPLACE_H

namespace Esri
{
  namespace ArcGISRuntime
  {
    class CalloutData;
    class Map;
    class MapQuickView;
    class GraphicsOverlay;
    class LocatorTask;
  }
}

#include "Point.h"
#include "Envelope.h"
#include "GeocodeParameters.h"

#include <QAbstractListModel>
#include <QQuickItem>

class FindPlace : public QQuickItem
{
  Q_OBJECT

  Q_PROPERTY(QAbstractListModel* suggestions MEMBER m_suggestListModel NOTIFY suggestionsChanged)
  Q_PROPERTY(bool poiTextHasFocus READ poiTextHasFocus WRITE setPoiTextHasFocus NOTIFY poiTextHasFocusChanged)

public:
  explicit FindPlace(QQuickItem* parent = nullptr);
  ~FindPlace() override;

  enum class SearchMode
  {
    CurrentLocation,
    MapExtent
  };
  Q_ENUM(SearchMode)

  void componentComplete() override;
  static void init();
  Q_INVOKABLE void setSuggestionsText(const QString& searchText);
  Q_INVOKABLE void geocodePOIs(const QString& poi, const QString& location);
  Q_INVOKABLE void geocodePOIs(const QString& poi, const Esri::ArcGISRuntime::Point& location);
  Q_INVOKABLE void geocodePOIs(const QString& poi, SearchMode mode);
  Q_INVOKABLE void geocodePOIs(const QString& poi);

signals:
  void suggestionsChanged();
  void poiTextHasFocusChanged();
  void hideSuggestionView();
  void hideCallout();
  void showCallout();
  void showExtentButton();

private:
  void addGraphicsOverlay();
  void createLocator();
  void connectSignals();
  bool poiTextHasFocus() const { return m_poiTextHasFocus; }
  void setPoiTextHasFocus(bool hasFocus);
  Esri::ArcGISRuntime::GeocodeParameters createParameters();

private:
  Esri::ArcGISRuntime::Map* m_map = nullptr;
  Esri::ArcGISRuntime::MapQuickView* m_mapView = nullptr;
  Esri::ArcGISRuntime::GraphicsOverlay* m_graphicsOverlay = nullptr;
  Esri::ArcGISRuntime::CalloutData* m_calloutData = nullptr;
  Esri::ArcGISRuntime::LocatorTask* m_locatorTask = nullptr;
  QAbstractListModel* m_suggestListModel = nullptr;
  bool m_poiTextHasFocus = true;
  bool m_isSearchingLocation = false;
  QString m_poiSearchText;
  QString m_currentLocationText = QStringLiteral("Current Location");
  QObject* m_graphicParent = nullptr;
};

#endif // FINDPLACE_H
