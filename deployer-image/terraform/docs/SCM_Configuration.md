# StackGen SCM Configuration

StackGen best works with the SCM providers like Github, GitLab, and Bitbucket. The configurations for these SCM providers can vary based on your enterprise's requirements. We have tried our best to make this configuration as flexible as possible.

The SCM configuration can be overridden using the tf var entry `scm_configuration`

## GitLab

If you are trying to configure GitLab, Please do create a [GitLab application](https://docs.gitlab.com/ee/integration/oauth_provider.html) with the scopes as shown [in this image](../images/gitlab_app_configuration.png). Follow steps in [common steps](#common-steps) to set the `client_id` and `client_secret` in appcd pod.

## GitHub

Create a [GitHub oauth app](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app). We need to set the `client_id` and `client_secret` in appcd pod. Check [common step](#common-steps) on using the secrets to achieve this.

> Callback url should be of format: `https://your-domain/appcd/api/v1/auth/callback/sso`

## Bitbucket

Create a [Bitbucket OAuth consumer](https://support.atlassian.com/bitbucket-cloud/docs/use-oauth-on-bitbucket-cloud/). We need to set the `client_id` and `client_secret` in appcd pod. Check [common step](#common-steps) on using the secrets to achieve this.

### Enterprise GitHub setup

If using enterprise GitHub, You might want to override the default GitHub oauth url. You can do this by setting the `.appcd.scm.github.auth_url` helm value.

```yaml
# entry in values/appcd.yaml
appcd:
  scm:
    github:
      auth_url: "https://github.mycompany.com/login/oauth/authorize"
      token_url: "https://github.mycompany.com/login/oauth/access_token"
```

## Azure DevOps

Create a [Azure DevOps oauth app](https://docs.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/oauth?view=azure-devops). We need to set the `client_id` and `client_secret` in appcd pod. Check [common step](#common-steps) on using the secrets to achieve this.

## Common steps

Copy the application client and secret, Use the template [shown here](../env/sample.tfvars) to be added to the existing `tfvars` file. Remove values as you see it fit.

```hcl

scm_configuration = {
  scm_type = "gitlab"
  gitlab_config = {
    client_id     = "6aa18c2705005d1306db4f30a527079d58e773a6526742762b0678e7e567c1c7"
    client_secret = "gloas-583ad0312c39821d87b26e26412e007fa289bf79e533502ed0d90ff7bddaa0c3"
  }
}
```

## Apply the changes with a new variable supplied called additional_secrets

```sh
./install.sh
```
