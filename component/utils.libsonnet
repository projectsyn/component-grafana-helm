local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.grafana_helm;

local isOpenshift = std.member([ 'openshift4', 'oke' ], inv.parameters.facts.distribution);
local openshiftIntegration = params.openshiftIntegration.enabled;
local hasOpenshiftLogging = std.member(inv.applications, 'openshift4-logging');
local hasOpenshiftDatasources = params.openshiftIntegration.metrics.enabled || params.openshiftIntegration.logsApps.enabled || params.openshiftIntegration.logsInfra.enabled || params.openshiftIntegration.logsAudit.enabled;

local metadata = {
  annotations: {
    'syn.tools/source': 'https://github.com/projectsyn/component-grafana-helm.git',
  },
  labels: {
    'app.kubernetes.io/managed-by': 'commodore',
    'app.kubernetes.io/part-of': 'syn',
    'app.kubernetes.io/component': 'grafana-helm',
    'app.kubernetes.io/name': 'grafana',
    'app.kubernetes.io/instance': inv.parameters._instance,
  },
  name: inv.parameters._instance,
  namespace: params.namespace,
};

{
  isOpenshift: isOpenshift,
  openshiftIntegration: openshiftIntegration,
  hasOpenshiftLogging: hasOpenshiftLogging,
  hasOpenshiftDatasources: hasOpenshiftDatasources,
  metadata: metadata,
}
