local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local utils = import 'utils.libsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.grafana_helm;

local common = {
  extraLabels: utils.metadata.labels,
  annotations: utils.metadata.annotations,
  image: {
    registry: params.images.grafana.registry,
    repository: params.images.grafana.repository,
    tag: params.images.grafana.tag,
  },
  sidecar: {
    image: {
      registry: params.images.sidecar.registry,
      repository: params.images.sidecar.repository,
      tag: params.images.sidecar.tag,
    },
  },
};

local openshift = if utils.isOpenshift && utils.openshiftIntegration then {
  admin: {
    existingSecret: 'grafana-admin-user',
  },
  persistence: {
    enabled: true,
  },
  'grafana.ini': {
    log: {
      mode: 'console',
      level: 'warn',
    },
    auth: {
      disable_login_form: false,
      disable_signout_menu: true,
      // this is needed because the generic_oauth with openshift uses the
      // username as email address.
      oauth_allow_insecure_email_lookup: true,
      // Invalidate sessions after 24h or 6h idle time to ensure Grafana
      // periodically requests a new OIDC token from OpenShift, since
      // OpenShift oauth doesn't provide refresh tokens as far as I can
      // see.
      login_maximum_lifetime_duration: '24h',
      login_maximum_inactive_lifetime_duration: '6h',
    },
    'auth.basic': {
      enabled: false,
    },
    'auth.generic_oauth': {
      name: 'OpenShift',
      icon: 'signin',
      enabled: true,
      // The referenced service account is created in openshift_integration.libsonnet.
      client_id: 'system:serviceaccount:%(namespace)s:%(name)s' % utils.metadata,
      client_secret: '${OAUTH_CLIENT_SECRET}',
      scopes: params.openshiftIntegration.auth.scopes,
      empty_scopes: false,
      auth_url: 'https://oauth-openshift.%s/oauth/authorize' % inv.parameters.openshift.appsDomain,
      token_url: 'https://oauth-openshift.%s/oauth/token' % inv.parameters.openshift.appsDomain,
      api_url: 'https://kubernetes.default.svc/apis/user.openshift.io/v1/users/~',
      email_attribute_path: 'metadata.name',
      auto_login: true,
      allow_sign_up: true,
      allow_assign_grafana_admin: true,
      role_attribute_path: params.openshiftIntegration.auth.roleAttributePath,
      tls_client_cert: '/etc/tls/private/tls.crt',
      tls_client_key: '/etc/tls/private/tls.key',
      tls_client_ca: '/run/secrets/kubernetes.io/serviceaccount/ca.crt',
      use_pkce: true,
    },
    security: {
      admin_user: params.openshiftIntegration.auth.adminUser,
      cookie_secure: true,
    },
    server: {
      protocol: 'https',
      cert_file: '/etc/tls/private/tls.crt',
      cert_key: '/etc/tls/private/tls.key',
      root_url: 'https://grafana.%s' % inv.parameters.openshift.appsDomain,
    },
    users: {
      auto_assign_org: 1,
      auto_assign_org_role: 'Editor',
    },
    analytics: {
      check_for_updates: false,
      reporting_enabled: false,
    },
  },
  livenessProbe: {
    httpGet: {
      scheme: 'HTTPS',
    },
  },
  readinessProbe: {
    httpGet: {
      scheme: 'HTTPS',
    },
  },
  rbac: {
    create: false,
  },
  // The service account is created in grafana-openshift.libsonnet.
  serviceAccount: {
    create: false,
    name: utils.metadata.name,
  },
  service: {
    enabled: false,
  },
  envValueFrom: {
    // The referenced secret is from the long-lived service account token.
    // The service account token is created in grafana-openshift.libsonnet.
    OAUTH_CLIENT_SECRET: {
      secretKeyRef: {
        name: '%(name)s-token' % utils.metadata,
        key: 'token',
      },
    },
    SA_SERVICE_CERT: {
      secretKeyRef: {
        name: '%(name)s-token' % utils.metadata,
        key: 'service-ca.crt',
      },
    },
    SA_BEARER_TOKEN: {
      secretKeyRef: {
        name: '%(name)s-token' % utils.metadata,
        key: 'token',
      },
    },
  },
  // This secret is created by the OpenShift OAuth proxy and contains the TLS certificate and key for the Grafana service.
  // The service is created in grafana-openshift.libsonnet.
  extraSecretMounts: [ {
    name: 'secret-grafana-tls',
    secretName: 'grafana-tls',
    mountPath: '/etc/tls/private',
  } ],
  [if utils.hasOpenshiftDatasources then 'datasources']: {
    'datasources.yaml': {
      apiVersion: 1,
      datasources: [
        if params.openshiftIntegration.metrics.enabled then {
          name: params.openshiftIntegration.metrics.name,
          type: 'prometheus',
          url: 'https://thanos-querier.openshift-monitoring.svc.cluster.local:9091',
          access: 'proxy',
          isDefault: true,
          editable: false,
          jsonData: {
            httpHeaderName1: 'Authorization',
            tlsAuthWithCACert: true,
          },
          secureJsonData: {
            // kubectl --as cluster-admin -n {GRAFANA_NAMESPACE} get secret {GRAFANA_SA_NAME}-token -ojsonpath='{.data.token}' | base64 -d
            httpHeaderValue1: 'Bearer $SA_BEARER_TOKEN',
            tlsCACert: '$SA_SERVICE_CERT',
          },
        },
        if utils.hasOpenshiftLogging && params.openshiftIntegration.logsApps.enabled then {
          name: params.openshiftIntegration.logsApps.name,
          type: 'loki',
          url: 'https://loki-openshift-logging.%s/api/logs/v1/application/' % inv.parameters.openshift.appsDomain,
          access: 'proxy',
          editable: false,
          jsonData: {
            oauthPassThru: true,
            timeout: '600s',
          },
        },
        if utils.hasOpenshiftLogging && params.openshiftIntegration.logsInfra.enabled then {
          name: params.openshiftIntegration.logsInfra.name,
          type: 'loki',
          url: 'https://loki-openshift-logging.%s/api/logs/v1/infrastructure/' % inv.parameters.openshift.appsDomain,
          access: 'proxy',
          editable: false,
          jsonData: {
            oauthPassThru: true,
            timeout: '600s',
          },
        },
        if utils.hasOpenshiftLogging && params.openshiftIntegration.logsAudit.enabled then {
          name: params.openshiftIntegration.logsAudit.name,
          type: 'loki',
          url: 'https://loki-openshift-logging.%s/api/logs/v1/audit/' % inv.parameters.openshift.appsDomain,
          access: 'proxy',
          editable: false,
          jsonData: {
            oauthPassThru: true,
            timeout: '600s',
          },
        },
      ],
    },
  },
} else {};

{
  ['%s-common' % inv.parameters._instance]: common,
  ['%s-openshift' % inv.parameters._instance]: openshift,
  ['%s-overrides' % inv.parameters._instance]: params.helm_values,
}
