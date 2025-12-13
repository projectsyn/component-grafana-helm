local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local utils = import 'utils.libsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.grafana_helm;

local serviceAccount = {
  apiVersion: 'v1',
  kind: 'ServiceAccount',
  metadata: utils.metadata {
    annotations+: {
      ['serviceaccounts.openshift.io/oauth-redirectreference.%(namespace)s' % utils.metadata]: '{"kind":"OAuthRedirectReference","apiVersion":"v1","reference":{"kind":"Route","name":"%(namespace)s"}}' % utils.metadata,
    },
  },
  automountServiceAccountToken: false,
};

local serviceAccountToken = {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: utils.metadata {
    annotations+: {
      'kubernetes.io/service-account.name': utils.metadata.name,
    },
    name: '%(name)s-token' % utils.metadata,
  },
  type: 'kubernetes.io/service-account-token',
};

local clusterRoleBindings = [
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      annotations: utils.metadata.annotations,
      labels: utils.metadata.labels,
      name: 'grafana-auth-delegator',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'system:auth-delegator',
    },
    subjects: [ {
      kind: 'ServiceAccount',
      name: utils.metadata.name,
      namespace: params.namespace,
    } ],
  },
  {
    apiVersion: 'rbac.authorization.k8s.io/v1',
    kind: 'ClusterRoleBinding',
    metadata: {
      annotations: utils.metadata.annotations,
      labels: utils.metadata.labels,
      name: 'grafana-monitoring-view',
    },
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'cluster-monitoring-view',
    },
    subjects: [ {
      kind: 'ServiceAccount',
      name: utils.metadata.name,
      namespace: params.namespace,
    } ],
  },
];

local service = {
  apiVersion: 'v1',
  kind: 'Service',
  metadata: utils.metadata {
    annotations+: {
      'service.beta.openshift.io/serving-cert-secret-name': 'grafana-tls',
    },
  },
  spec: {
    ports: [ {
      name: 'service',
      port: 3000,
      protocol: 'TCP',
      targetPort: 'grafana',
    } ],
    selector: {
      'app.kubernetes.io/instance': 'vshn-grafana',
      'app.kubernetes.io/name': 'grafana',
    },
    type: 'ClusterIP',
  },
};

local route = {
  apiVersion: 'route.openshift.io/v1',
  kind: 'Route',
  metadata: utils.metadata,
  spec: {
    host: 'grafana.%s' % inv.parameters.openshift.appsDomain,
    path: '/',
    port: {
      targetPort: 'service',
    },
    tls: {
      insecureEdgeTerminationPolicy: 'Redirect',
      termination: 'reencrypt',
    },
    to: {
      kind: 'Service',
      name: utils.metadata.name,
      weight: 100,
    },
    wildcardPolicy: 'None',
  },
};

local networkPolicy = {
  apiVersion: 'networking.k8s.io/v1',
  kind: 'NetworkPolicy',
  metadata: utils.metadata {
    name: 'allow-from-%(namespace)s' % utils.metadata,
    namespace: 'openshift-logging',
  },
  spec: {
    ingress: [ {
      from: [ {
        namespaceSelector: {
          matchLabels: {
            'kubernetes.io/metadata.name': utils.metadata.namespace,
          },
        },
      } ],
    } ],
    podSelector: {},
    policyTypes: [ 'Ingress' ],
  },
};

local secret = {
  apiVersion: 'v1',
  kind: 'Secret',
  metadata: utils.metadata {
    name: 'grafana-admin-password',
  },
  type: 'Opaque',
  stringData: {
    'admin-user': params.openshiftIntegration.auth.adminUser,
    'admin-password': params.openshiftIntegration.auth.adminPassword,
  },
};

if utils.isOpenshift && utils.openshiftIntegration then {
  '30_openshift_integration/clusterrolebinding': clusterRoleBindings,
  [if utils.hasOpenshiftLogging then '30_openshift_integration/networkpolicy']: networkPolicy,
  '30_openshift_integration/route': route,
  '30_openshift_integration/secret': secret,
  '30_openshift_integration/service': service,
  '30_openshift_integration/serviceaccount': [ serviceAccount, serviceAccountToken ],
} else {}
