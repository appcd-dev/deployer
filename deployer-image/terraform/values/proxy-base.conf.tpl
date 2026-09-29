server {
    listen 80;
    listen [::]:80;

    server_tokens off;

    server_name ${domain};

    add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload';
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' https: data:; base-uri 'self';";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy "strict-origin";
    add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()";
    client_max_body_size 10m;
    location = /healthz {
        default_type text/plain;
        return 200 'OK';
    }

    location = /favicon.ico {
        return 301 https://appcd.com/favicon.ico;
    }

    location = /mode.json {
        return 200 '{"mode":"ci", "main": "/"}';
    }

    location = /path.json {
        default_type application/json;
        return 200 '${jsonencode(merge({
          "auth" = {"path" = "/auth"},
          "appcd" = {"path" = "/appcd"},
          "iac-gen" = {"path" = "/iac-gen"},
          "exporter" = {"path" = "/exporter"}
        }, guild_enabled ? {
          "guild" = {"path" = "/guild"},
          "guild-ui" = {"path" = "/app/settings"}
        } : {}))}';
    }

    location = /features.json {
        default_type application/json;
        return 200 '${jsonencode({
          "notifications" = false,
          "editableIac" = true,
          "moduleEditor" = true,
          "exporter" = true,
          "vault" = true,
          "recentStarredModules" = true,
          "analytics" = true,
          "apm" = true,
          "driftDetection" = true,
          "agentSystem" = false,
          "aiden" = false,
          "communityEdition" = false,
          "advancedGuildFeatures" = guild_enabled,
          "commandCenter" = false,
          "guild" = guild_enabled,
          "emailOTPLogin" = false,
          "stackgenCore" = false
        })}';
    }

    location = /version.json {
        default_type application/json;
        return 200 '${jsonencode({
          "stackgen-distribution" = stackgen_version,
          "appcd" = component_versions.appcd,
          "iac-gen" = component_versions.iacgen,
          "ui" = component_versions.ui,
          "exporter" = component_versions.exporter,
          "llm-gateway" = component_versions.llm_gateway,
          "vault" = component_versions.vault,
          "guild" = guild_enabled ? component_versions.guild : "disabled",
          "guild-gateway" = guild_enabled ? component_versions.gateway : "disabled",
          "guild-ui" = guild_enabled ? component_versions.guild_ui : "disabled"
        })}';
    }

    location = /auth {
        internal;
        proxy_pass http://appcd.${namespace}.svc.cluster.local:8080/api/v1/auth/me;
        proxy_method HEAD;
        proxy_pass_request_body off;
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Original-Method $request_method;
    }

    location = /amplitude {
        proxy_pass https://api2.amplitude.com/2/httpapi;
        proxy_pass_request_body on;
    }

    location /appcd {
        proxy_http_version 1.1;

        auth_request /auth;
        auth_request_set $login $upstream_http_x_appcd_login;
        proxy_set_header X-Appcd-Login $login;

        auth_request_set $appcd_session $upstream_http_x_appcd_session;
        proxy_set_header X-Appcd-Session $appcd_session;

        auth_request_set $principal_name $upstream_http_x_stackgen_principal;
        proxy_set_header X-Stackgen-Principal $principal_name;

        auth_request_set $session_type $upstream_http_x_appcd_session_type;
        proxy_set_header X-Appcd-Session-Type $session_type;

        auth_request_set $appcd_org $upstream_http_x_appcd_org;
        proxy_set_header X-Appcd-Org $appcd_org;

        auth_request_set $appcd_scopes $upstream_http_x_appcd_scopes;
        proxy_set_header X-Appcd-Scopes $appcd_scopes;

        auth_request_set $stackgen_tenant $upstream_http_x_stackgen_tenant;
        proxy_set_header X-Stackgen-Tenant $stackgen_tenant;

        rewrite /appcd/(.*) /$1 break;

        proxy_pass http://appcd.${namespace}.svc.cluster.local:8080;
    }

    # Guild API, authenticated like AWS ingress minions, with the prefix removed.
%{ if guild_enabled ~}
    location /api/v1/guild {
        auth_request /auth;
        auth_request_set $login $upstream_http_x_appcd_login;
        proxy_set_header X-Appcd-Login $login;
        auth_request_set $principal_name $upstream_http_x_stackgen_principal;
        proxy_set_header X-Stackgen-Principal $principal_name;
        auth_request_set $appcd_org $upstream_http_x_appcd_org;
        proxy_set_header X-Appcd-Org $appcd_org;
        auth_request_set $appcd_scopes $upstream_http_x_appcd_scopes;
        proxy_set_header X-Appcd-Scopes $appcd_scopes;
        auth_request_set $stackgen_tenant_identifier $upstream_http_x_stackgen_tenant_identifier;
        proxy_set_header X-Stackgen-Tenant-Identifier $stackgen_tenant_identifier;
        auth_request_set $stackgen_tenant $upstream_http_x_stackgen_tenant;
        proxy_set_header X-Stackgen-Tenant $stackgen_tenant;
        auth_request_set $appcd_session $upstream_http_x_appcd_session;
        proxy_set_header X-Appcd-Session $appcd_session;
        auth_request_set $session_type $upstream_http_x_appcd_session_type;
        proxy_set_header X-Appcd-Session-Type $session_type;
        rewrite ^/api/v1/guild/(.*)$ /$1 break;
        proxy_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_pass http://appcd-stackgen-guild-guild.${namespace}.svc.cluster.local:8081;
    }

    # Global shares and signed callbacks bypass auth, matching AWS routes.
    location = /guild/api/v1/shared-sessions/global {
        rewrite ^/guild/(.*)$ /$1 break;
        proxy_pass http://appcd-stackgen-guild-guild.${namespace}.svc.cluster.local:8081;
    }
    location = /guild/api/v1/webhooks/trigger {
        rewrite ^/guild/(.*)$ /$1 break;
        proxy_pass http://appcd-stackgen-guild-guild.${namespace}.svc.cluster.local:8081;
    }
    location = /guild/api/v1/remote-runners/public {
        rewrite ^/guild/(.*)$ /$1 break;
        proxy_pass http://appcd-stackgen-guild-guild.${namespace}.svc.cluster.local:8081;
    }

    # Tenant Guild routes use the same auth headers and rewrite as AWS.
    location /guild {
        auth_request /auth;
        auth_request_set $login $upstream_http_x_appcd_login;
        proxy_set_header X-Appcd-Login $login;
        auth_request_set $principal_name $upstream_http_x_stackgen_principal;
        proxy_set_header X-Stackgen-Principal $principal_name;
        auth_request_set $appcd_org $upstream_http_x_appcd_org;
        proxy_set_header X-Appcd-Org $appcd_org;
        auth_request_set $appcd_scopes $upstream_http_x_appcd_scopes;
        proxy_set_header X-Appcd-Scopes $appcd_scopes;
        auth_request_set $stackgen_tenant_identifier $upstream_http_x_stackgen_tenant_identifier;
        proxy_set_header X-Stackgen-Tenant-Identifier $stackgen_tenant_identifier;
        auth_request_set $stackgen_tenant $upstream_http_x_stackgen_tenant;
        proxy_set_header X-Stackgen-Tenant $stackgen_tenant;
        auth_request_set $appcd_session $upstream_http_x_appcd_session;
        proxy_set_header X-Appcd-Session $appcd_session;
        auth_request_set $session_type $upstream_http_x_appcd_session_type;
        proxy_set_header X-Appcd-Session-Type $session_type;
        rewrite ^/guild/(.*)$ /$1 break;
        proxy_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_pass http://appcd-stackgen-guild-guild.${namespace}.svc.cluster.local:8081;
    }

    location /app/settings {
        # Guild's SPA bundle uses Function() for its code-split/runtime loader.
        # Scope unsafe-eval to Guild UI; keep the default CSP stricter elsewhere.
        add_header Strict-Transport-Security 'max-age=31536000; includeSubDomains; preload' always;
        add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' https: data:; base-uri 'self'; worker-src 'self' blob:;" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options nosniff always;
        add_header Referrer-Policy "strict-origin" always;
        add_header Permissions-Policy "geolocation=(),midi=(),sync-xhr=(),microphone=(),camera=(),magnetometer=(),gyroscope=(),fullscreen=(self),payment=()" always;
        proxy_set_header Host $host;
        # The Guild UI's nginx may redirect the slash-less path using either
        # its service DNS name or the forwarded public host plus :8080.
        proxy_redirect http://appcd-stackgen-guild-ui.${namespace}.svc.cluster.local:8080/ https://$host/;
        proxy_redirect http://appcd-stackgen-guild-ui:8080/ https://$host/;
        proxy_redirect http://$host:8080/ https://$host/;
        proxy_pass http://appcd-stackgen-guild-ui.${namespace}.svc.cluster.local:8080;
    }
    location /stream {
        proxy_buffering off;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /slack/events {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /callbacks/approvals {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /teams/events {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /googlechat/events {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /telegram/events {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
    location /whatsapp/events {
        proxy_pass http://appcd-stackgen-guild-gateway.${namespace}.svc.cluster.local:8080;
    }
%{ endif ~}

    location / {
        proxy_pass http://appcd-appcd-ui.${namespace}.svc.cluster.local:8000;
    }

    location /iac-gen {
        auth_request /auth;

        auth_request_set $login $upstream_http_x_appcd_login;
        proxy_set_header X-Appcd-Login $login;

        auth_request_set $principal_name $upstream_http_x_stackgen_principal;
        proxy_set_header X-Stackgen-Principal $principal_name;

        auth_request_set $appcd_org $upstream_http_x_appcd_org;
        proxy_set_header X-Appcd-Org $appcd_org;

        auth_request_set $appcd_scopes $upstream_http_x_appcd_scopes;
        proxy_set_header X-Appcd-Scopes $appcd_scopes;

        auth_request_set $stackgen_tenant $upstream_http_x_stackgen_tenant;
        proxy_set_header X-Stackgen-Tenant $stackgen_tenant;

        rewrite /iac-gen/(.*) /$1 break;

        proxy_pass http://appcd-iac-gen.${namespace}.svc.cluster.local:9000;
    }

    location /exporter {
        auth_request /auth;

        auth_request_set $login $upstream_http_x_appcd_login;
        proxy_set_header X-Appcd-Login $login;

        auth_request_set $principal_name $upstream_http_x_stackgen_principal;
        proxy_set_header X-Stackgen-Principal $principal_name;

        auth_request_set $appcd_session $upstream_http_x_appcd_session;
        proxy_set_header X-Appcd-Session $appcd_session;

        auth_request_set $appcd_org $upstream_http_x_appcd_org;
        proxy_set_header X-Appcd-Org $appcd_org;

        proxy_set_header NS_Connection true;

        auth_request_set $appcd_scopes $upstream_http_x_appcd_scopes;
        proxy_set_header X-Appcd-Scopes $appcd_scopes;

        auth_request_set $stackgen_tenant $upstream_http_x_stackgen_tenant;
        proxy_set_header X-Stackgen-Tenant $stackgen_tenant;

        rewrite /exporter/(.*) /$1 break;

        proxy_pass http://appcd-exporter.${namespace}.svc.cluster.local:8080;
    }
}
