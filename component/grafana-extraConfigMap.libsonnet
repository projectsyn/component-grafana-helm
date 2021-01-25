local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local instance = inv.parameters._instance;


{
  'grafana-extraConfigMap': kube.ConfigMap('grafana-extraConfigMap') {
    metadata+: {
      namespace: params.namespace,
    },
    data+: params.extraConfigMap,
  },
}
