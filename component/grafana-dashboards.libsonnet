local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.spks_monitoring;
local instance = inv.parameters._instance;


{
  ['grafana-resources/dashboards/' + dashboard]: kube.ConfigMap('dashboard-' + dashboard) {
    metadata+: {
      namespace: params.namespace,
      labels+: {
        grafana_dashboard: '1',
      },
    },
    data+: {
      [dashboard + '.json']: params.dashboards[dashboard],
    },
  }
  for dashboard in std.objectFields(params.dashboards)
}
