#-------------------------------------------------
# Copyright 2020 Esri.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------

contains(QMAKE_HOST.os, Windows):{
  iniPath = $$(ALLUSERSPROFILE)\EsriRuntimeQt\ArcGIS Runtime SDK for Qt $${ARCGIS_RUNTIME_VERSION}.ini
}
else {
  userHome = $$system(echo $HOME)
  iniPath = $${userHome}/.config/EsriRuntimeQt/ArcGIS Runtime SDK for Qt $${ARCGIS_RUNTIME_VERSION}.ini
}
iniLine = $$cat($${iniPath}, "lines")
dirPath = $$find(iniLine, "InstallDir")
cleanDirPath = $$replace(dirPath, "InstallDir=", "")
priLocation = $$replace(cleanDirPath, '"', "")
!include($$priLocation/sdk/ideintegration/arcgis_runtime_qml.pri) {
  message("Error. Cannot locate ArcGIS Runtime PRI file")
}
