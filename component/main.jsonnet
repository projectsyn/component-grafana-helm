local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;

{
  [if params.createNamespace then '00_namespace']: kube.Namespace(params.namespace) {
    metadata+: {
      labels+: params.namespaceLabels,
      annotations+: params.namespaceAnnotations,
    },
  },
} + (import 'grafana-dashboards.libsonnet')
+ (import 'grafana-datasources.libsonnet')
+ (import 'grafana-extraConfigMap.libsonnet')
