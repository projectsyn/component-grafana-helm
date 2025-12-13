local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local instance = inv.parameters._instance;

{
  [if std.length(params.datasources) > 0 then '20_extra_datasources']: kube.ConfigMap(instance + '-datasources') {
    metadata+: {
      namespace: params.namespace,
      labels+: {
        grafana_datasource: '1',
      },
    },
    data+: {
      [datasource]: params.datasources[datasource]
      for datasource in std.objectFields(params.datasources)
    },
  },
}
