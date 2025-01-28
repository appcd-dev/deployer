# Securing the StackGen Installation

This document provides information on securing the StackGen installation.

## Introduction

Once the installation is complete, you might want to secure the StackGen installation. This document provides information on how to secure the StackGen installation.

## Authentication options

1. StackGen installed on-premise.
2. Access to the StackGen server.
3. A valid domain name for the StackGen server.
4. Access to the StackGen installation script and [values/appcd.yaml](./values/appcd.yaml) file.
5. Familiarity with the [OAuth2](https://oauth.net/2/) protocol.

Below are the options available for `appcd_authentication`:

### Google

To use Google as an authentication provider, set the following configuration.

More configuration options can be found [here](https://dexidp.io/docs/connectors/google/).

```hcl
appcd_authentication = {
  type = "google"
  config = {
    clientID: $GOOGLE_CLIENT_ID
    clientSecret: $GOOGLE_CLIENT_SECRET
  }
}
```

### GitHub

To use GitHub as an authentication provider, set the following configuration.

More configuration options can be found [here](https://dexidp.io/docs/connectors/github/).

```hcl
appcd_authentication = {
  type = "github"
  config = {
    clientID: $GITHUB_CLIENT_ID
    clientSecret: $GITHUB_CLIENT_SECRET
  }
}
```

### Gitlab

To use Gitlab as an authentication provider, set the following configuration.

More configuration options can be found [here](https://dexidp.io/docs/connectors/gitlab/).

```hcl
appcd_authentication = {
  type = "gitlab"
  config = {
    clientID: $GITLAB_CLIENT_ID
    clientSecret: $GITLAB_CLIENT_SECRET
  }
}
```

### SAML

To use SAML as an authentication provider, set the following configuration.

Make the SAML Ca certificate available to the appCD installation through configmap.

```sh
kubectl create configmap dex-metadata --from-file=ca.pem=ca.pem
```

More configuration options can be found [here](https://dexidp.io/docs/connectors/saml/).

```hcl
appcd_authentication = {
  type = "saml"
  config = {
    "ssoURL": "https://saml.example.com/sso"
    "ca": "/data/config/ca.pem"
    "usernameAttr": "name"
    "emailAttr": "email"
    "entityIssuer": "appcd-authenticator"
    "redirectURI": "https://${host_domain}/callback/saml"
  }
}
```

#### Configuration on SAML Side

- Application start URL: `https://${host_domain}`
- Application ACS URL: `https://${host_domain}/auth/callback`
- Application SAML audience: `appcd-authenticator`

#### Attribute Mapping

| User Attribute | appCD Attribute | format       |
| -------------- | --------------- | ------------ |
| Subject        | `${user:email}` | `persistent` |
| name           | `${user:name}`  | `basic`      |
| email          | `${user:email}` | `basic`      |
