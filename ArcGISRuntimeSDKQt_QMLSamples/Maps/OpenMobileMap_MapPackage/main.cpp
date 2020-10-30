// Copyright 2015 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <QGuiApplication>
#include <QQuickView>
#include <QUrl>
#include <QCoreApplication>
#include <QDir>
#include <QQmlEngine>

#define STRINGIZE(x) #x
#define QUOTE(x) STRINGIZE(x)

int main(int argc, char *argv[])
{
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication app(argc, argv);
    app.setApplicationName("OpenMobileMap_MapPackage - QML");

    // Initialize application view
    QQuickView view;
    view.setResizeMode(QQuickView::SizeRootObjectToView);

    // Add the import Path
    view.engine()->addImportPath(QDir(QCoreApplication::applicationDirPath()).filePath("qml"));

    QString arcGISRuntimeImportPath = QUOTE(ARCGIS_RUNTIME_IMPORT_PATH);
    

#if defined(LINUX_PLATFORM_REPLACEMENT)
    // on some linux platforms the string 'linux' is replaced with 1
    // fix the replacement paths which were created
    QString replaceString = QUOTE(LINUX_PLATFORM_REPLACEMENT);
    arcGISRuntimeImportPath = arcGISRuntimeImportPath.replace(replaceString, "linux", Qt::CaseSensitive);

#endif

    // Add the Runtime and Extras path
    view.engine()->addImportPath(arcGISRuntimeImportPath);
    // Add the Toolkit path


    // Set the source
    view.setSource(QUrl("qrc:/Samples/Maps/OpenMobileMap_MapPackage/OpenMobileMap_MapPackage.qml"));

    view.show();

    return app.exec();
}
