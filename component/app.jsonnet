local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.grafana_helm;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('grafana_helm', params.namespace);

{
  grafana_helm: app,
}
