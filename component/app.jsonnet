local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.grafana_helm;
local argocd = import 'lib/argocd.libjsonnet';

local instance = inv.parameters._instance;

{
  [instance]: argocd.App(instance, params.namespace),
}
