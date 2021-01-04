local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.grafana;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('grafana', params.namespace);

{
  grafana: app,
}
