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

    location = /favicon.ico {
        return 301 https://appcd.com/favicon.ico;
    }

    location = /mode.json {
        return 200 '{"mode":"ci", "main": "/"}';
    }

    location = /path.json {
        return 200 '{"auth":{"path":"/auth"},"appcd": {"path": "/appcd"}, "iac-gen": {"path": "/iac-gen"}, "exporter": {"path": "/exporter"}}';
    }

    location = /version.json {
        return 200 '{
            "appcd": "main",
            "iac-gen": "main",
            "ui": "main",
            "exporter": "main"
        }';
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
