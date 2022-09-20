local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local com = import 'lib/commodore.libjsonnet';

local params = inv.parameters.grafana_helm;

local secrets = com.generateResources(
  params.secrets,
  function(name) kube.Secret(name) {
    metadata+: {
      namespace: params.namespace,
    },
  }
);

{
  [if params.createNamespace then '00_namespace']: kube.Namespace(params.namespace) {
    metadata+: {
      labels+: params.namespaceLabels,
      annotations+: params.namespaceAnnotations,
    },
  },
  '10_secrets': secrets,
} + (import 'grafana-dashboards.libsonnet')
+ (import 'grafana-datasources.libsonnet')
+ (import 'grafana-extraConfigMap.libsonnet')
