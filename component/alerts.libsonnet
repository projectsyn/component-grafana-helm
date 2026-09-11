local alertpatching = import 'lib/alert-patching.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local prom = import 'lib/prom.libsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local utils = import 'utils.libsonnet';

local prometheusRule = prom.generateRules(utils.metadata.name, params.rules);

local has_monitoring = std.member(inv.applications, 'prometheus') || std.member(inv.applications, 'openshift4-monitoring');
local has_alerts = std.length(prometheusRule.spec.groups) > 0;

{
  [if has_alerts && has_monitoring then '40_alerts/prometheusrule']: prometheusRule,
}
