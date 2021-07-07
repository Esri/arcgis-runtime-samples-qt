// [WriteFile Name=CreateLoadReport, Category=UtilityNetwork]
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

#ifdef PCH_BUILD
#include "pch.hpp"
#endif // PCH_BUILD

#include "CreateLoadReport.h"

#include "MapQuickView.h"

#include "CodedValueDomain.h"
#include "UtilityAssetGroup.h"
#include "UtilityAssetType.h"
#include "UtilityCategory.h"
#include "UtilityCategoryComparison.h"
#include "UtilityDomainNetwork.h"
#include "UtilityElementTraceResult.h"
#include "UtilityFunctionTraceResult.h"
#include "UtilityNetwork.h"
#include "UtilityNetworkAttribute.h"
#include "UtilityNetworkAttributeComparison.h"
#include "UtilityNetworkDefinition.h"
#include "UtilityNetworkSource.h"
#include "UtilityNetworkTypes.h"
#include "UtilityTerminal.h"
#include "UtilityTerminalConfiguration.h"
#include "UtilityTier.h"
#include "UtilityTraceConfiguration.h"
#include "UtilityTraceFunctionListModel.h"
#include "UtilityTraceFunctionOutput.h"
#include "UtilityTraceOrCondition.h"
#include "UtilityTraceParameters.h"
#include "UtilityTraceResultListModel.h"
#include "UtilityTraversability.h"

using namespace Esri::ArcGISRuntime;

CreateLoadReport::CreateLoadReport(QObject* parent /* = nullptr */):
  QObject(parent),
  m_cred(new Credential("viewer01", "I68VGU^nMurF", this))
{
  m_networkSourceName = "Electric Distribution Device";
  m_assetGroupName = "Circuit Breaker";
  m_assetTypeName = "Three Phase";
  m_terminalName = "Load";
  m_globalId = "{1CAF7740-0BF4-4113-8DB2-654E18800028}";
  m_domainNetworkName = "ElectricDistribution";
  m_tierName = "Medium Voltage Radial";
  m_serviceCategoryName = "ServicePoint";
  m_loadNetworkAttributeName = "Service Load";
  m_phasesNetworkAttributeName = "Phases Current";
  m_sampleStatus = CreateLoadReport::SampleNotLoaded;

  m_utilityNetwork = new UtilityNetwork(QUrl("https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer"), m_cred, this);

  connect(m_utilityNetwork, &UtilityNetwork::loadStatusChanged, this, [this]()
  {
    if (m_utilityNetwork->loadStatus() == LoadStatus::Loaded)
    {
      m_utilityAssetType = m_utilityNetwork
          ->definition()
          ->networkSource(m_networkSourceName)
          ->assetGroup(m_assetGroupName)
          ->assetType(m_assetTypeName);

      m_utilityTier = m_utilityNetwork
          ->definition()
          ->domainNetwork(m_domainNetworkName)
          ->tier(m_tierName);

      // Create a UtilityElement from the UtilityAssetType to use as the starting location
      m_startingLocation = createStartingLocation();

      // Get a default trace configuration from a tier in the network
      m_traceConfiguration = createDefaultTraceConfiguration();

      // Create a base condition to compare against
      m_baseCondition = dynamic_cast<UtilityTraceConditionalExpression*>(m_utilityTier->traceConfiguration()->traversability()->barriers());

      // Create downstream trace parameters with function outputs
      m_traceParameters = new UtilityTraceParameters(UtilityTraceType::Downstream, {m_startingLocation}, this);
      m_traceParameters->setResultTypes({UtilityTraceResultType::Elements, UtilityTraceResultType::FunctionOutputs});
      // Assign the trace configuration to trace parameters.
      m_traceParameters->setTraceConfiguration(m_traceConfiguration);

      // Create a list of possible phases from a given network attribute
      m_phaseList = createPhaseList();

      // Create a connection that is triggered when the utility network trace completes
      createTraceCompletedConnection();

      m_sampleStatus = CreateLoadReport::SampleReady;
      emit sampleStatusChanged();
    }
    else if (m_utilityNetwork->loadStatus() == LoadStatus::FailedToLoad)
    {
      m_sampleStatus = CreateLoadReport::SampleError;
      sampleStatusChanged();
    }
  });

  m_utilityNetwork->load();
}

UtilityElement* CreateLoadReport::createStartingLocation()
{
  if (!m_utilityAssetType)
    return nullptr;

  QList<UtilityTerminal*> utilityTerminals = m_utilityAssetType->terminalConfiguration()->terminals();
  if (!utilityTerminals.first())
    return nullptr;

  UtilityTerminal* loadTerminal = nullptr;

  for (UtilityTerminal* utilityTerminal : utilityTerminals)
  {
    // Set the terminal for the location. (For our case, use the "Load" terminal.)
    if (utilityTerminal->name() == m_terminalName)
    {
      loadTerminal = utilityTerminal;
      break;
    }
  }

  if (!loadTerminal)
    return nullptr;

  return m_utilityNetwork->createElementWithAssetType(m_utilityAssetType, QUuid(m_globalId), loadTerminal, this);
}

UtilityTraceConfiguration* CreateLoadReport::createDefaultTraceConfiguration()
{
  UtilityTraceConfiguration* traceConfig = m_utilityTier->traceConfiguration();

  // Service Category for counting total customers
  UtilityCategory* servicePointCategory = getUtilityCategory(m_serviceCategoryName);

  // The load attribute for counting total load.
  UtilityNetworkAttribute* serviceLoadAttribute = m_utilityNetwork->definition()->networkAttribute(m_loadNetworkAttributeName);

  // Create a comparison to check the existence of service points.
  UtilityCategoryComparison* serviceCategoryComparison = new UtilityCategoryComparison(servicePointCategory, UtilityCategoryComparisonOperator::Exists, this);
  UtilityTraceFunction* addLoadAttributeFunction = new UtilityTraceFunction(UtilityTraceFunctionType::Add, serviceLoadAttribute, serviceCategoryComparison, this);

  traceConfig->functions()->clear();

  // Create function input and output condition.
  traceConfig->functions()->append(addLoadAttributeFunction);
  traceConfig->setOutputCondition(serviceCategoryComparison);

  // Set to false to ensure that service points with incorrect phasing
  // (which therefore act as barriers) are not counted with results.
  traceConfig->setIncludeBarriers(false);

  return traceConfig;
}

UtilityCategory* CreateLoadReport::getUtilityCategory(const QString& categoryName)
{
  QList<UtilityCategory*> utilityCategories = m_utilityNetwork->definition()->categories();

  for (UtilityCategory* utilityCategory : utilityCategories)
  {
    if (utilityCategory->name() == categoryName)
      return utilityCategory;
  }
  return nullptr;
}

QList<CodedValue> CreateLoadReport::createPhaseList()
{
  // The phase attribute for getting total phase current load.
  m_phasesCurrentAttribute = m_utilityNetwork->definition()->networkAttribute(m_phasesNetworkAttributeName);

  // Get possible coded phase values from the attributes.
  if (m_phasesCurrentAttribute->domain().domainType() == DomainType::CodedValueDomain)
  {
    const CodedValueDomain cvd = CodedValueDomain(m_phasesCurrentAttribute->domain());
    QList<CodedValue> codedValues = cvd.codedValues();

    return codedValues;
  }

  return {};
}

void CreateLoadReport::runReport(const QStringList& selectedPhaseNames)
{
  m_sampleStatus = CreateLoadReport::SampleBusy;
  emit sampleStatusChanged();

  QList<CodedValue> activeValues;
  for (CodedValue codedValue : m_phaseList)
  {
    if (selectedPhaseNames.contains(codedValue.name()))
      activeValues.append(codedValue);

    // Reset the report values
    m_phaseCust.remove(codedValue.name());
    m_phaseLoad.remove(codedValue.name());

    emit loadReportUpdated();
  }

  for (CodedValue codedValue : activeValues)
  {
    setUtilityTraceOrconditionWithCodedValue(codedValue);
    TaskWatcher task = m_utilityNetwork->trace(m_traceParameters);
    m_tasks[task.taskId()] = codedValue.name();
  }

  // If no phases were selected then the sample was reset and can be marked ready
  if (selectedPhaseNames.size() == 0) {
    m_sampleStatus = CreateLoadReport::SampleReady;
    emit sampleStatusChanged();
  }
}

void CreateLoadReport::setUtilityTraceOrconditionWithCodedValue(CodedValue codedValue)
{
  // Create a conditional expression with the CodedValue
  UtilityNetworkAttributeComparison* utilityNetworkAttributeComparison =
        new UtilityNetworkAttributeComparison(
          m_phasesCurrentAttribute,
          UtilityAttributeComparisonOperator::DoesNotIncludeAny,
          codedValue.code(), this);

  UtilityTraceOrCondition* utilityTraceOrCondition = nullptr;

  // Chain it with the base condition using an OR operator.
  if (utilityNetworkAttributeComparison && m_baseCondition)
    utilityTraceOrCondition = new UtilityTraceOrCondition(m_baseCondition, utilityNetworkAttributeComparison, this);

  if (utilityTraceOrCondition)
    m_traceParameters->traceConfiguration()->traversability()->setBarriers(utilityTraceOrCondition);
}

void CreateLoadReport::createTraceCompletedConnection()
{
  connect(m_utilityNetwork, &UtilityNetwork::traceCompleted, this, [this](QUuid taskId)
  {
    const QString codedValueName = m_tasks.take(taskId);

    UtilityTraceResultListModel* results = m_utilityNetwork->traceResult();

    for (UtilityTraceResult* result : *results) {
      // Get the total customers from the UtilityElementTraceResult
      if (UtilityElementTraceResult* elementResult = dynamic_cast<UtilityElementTraceResult*>(result))
        m_phaseCust[codedValueName] = elementResult->elements(this).size();

      // Get the total load from the UtilityFunctionTraceResult
      else if (UtilityFunctionTraceResult* functionResult = dynamic_cast<UtilityFunctionTraceResult*>(result))
        m_phaseLoad[codedValueName] = functionResult->functionOutputs().first()->result().toInt();
    }

    emit loadReportUpdated();

    // If the tasks queue is empty, all trace tasks have completed
    if (m_tasks.keys().size() == 0) {
      m_sampleStatus = CreateLoadReport::SampleReady;
      emit sampleStatusChanged();
    }
  });
}

CreateLoadReport::~CreateLoadReport() = default;

void CreateLoadReport::init()
{
  qmlRegisterType<CreateLoadReport>("Esri.Samples", 1, 0, "CreateLoadReportSample");
}

void CreateLoadReport::addPhase(const QString& phaseToAdd)
{
  m_activePhases.append(phaseToAdd);
}

QVariantMap CreateLoadReport::phaseCust()
{
  return m_phaseCust;
}

QVariantMap CreateLoadReport::phaseLoad()
{
  return m_phaseLoad;
}

int CreateLoadReport::sampleStatus()
{
  return m_sampleStatus;
}
