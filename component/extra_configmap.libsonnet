local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.grafana_helm;
local instance = inv.parameters._instance;

{
  [if std.length(params.extraConfigMap) > 0 then '20_extra_configmap']: kube.ConfigMap('grafana-extraconfigmap') {
    metadata+: {
      namespace: params.namespace,
    },
    data+: params.extraConfigMap,
  },
}
