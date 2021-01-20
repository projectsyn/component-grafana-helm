local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.spks_monitoring;
local instance = inv.parameters._instance;


{
  'grafana-resources/01_datasources': kube.ConfigMap(instance + '-datasources') {
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
