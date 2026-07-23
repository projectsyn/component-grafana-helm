local kap = import 'lib/kapitan.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local utils = import 'utils.libsonnet';

local prometheusRule = prom.generateRules(utils.metadata.name, params.rules);
local hasGroup = std.length(prometheusRule.spec.groups) > 0;

{
  [if hasGroup then '40_alerts/prometheusrule']: prometheusRule,
}
