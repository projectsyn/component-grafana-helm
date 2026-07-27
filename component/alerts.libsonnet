local kap = import 'lib/kapitan.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local utils = import 'utils.libsonnet';

local rules = params.rules;
local defaultLabels = prometheusRule.labels;

local buildRule(alertName, rule) = rule {
  alert: alertName,
  labels+: defaultLabels,
};

local renderGroup(groupName) =
  local group = prometheusRule.groups[groupName];
  local rules = if group != null then [
    buildRule(alertName, group[alertName])
    for alertName in std.objectFields(group)
    if group[alertName] != null
  ] else [];
  if group != null && std.length(rules) > 0 then {
    name: groupName,
    rules: rules,
  } else null;

local groups = [
  renderGroup(groupName)
  for groupName in std.objectFields(prometheusRule.groups)
  if renderGroup(groupName) != null
];

local additionalRules = prom.generateRules(utils.metadata.name, params.rules) {
  metadata: {
    name: utils.metadata.name,
    namespace: params.namespace
  },
};

if std.length(groups) > 0 then {
  '40_alerts/prometheusrule': {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: utils.metadata,
    spec: { groups: groups },
  },
  'other': additionalRules
} else {}
