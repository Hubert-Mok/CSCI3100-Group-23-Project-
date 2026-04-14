# Azure production deployment (Container Apps + PostgreSQL)

This folder defines infrastructure with [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) for the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/) (`azd`). The app runs from the root [Dockerfile](../Dockerfile) on **Azure Container Apps** with **Azure Database for PostgreSQL – Flexible Server**.

## Prerequisites

- [Azure subscription](https://azure.microsoft.com/free/)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) (`azd`)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`) for optional commands
- Docker (local builds) unless you enable remote ACR builds later

## One-time setup

1. **Pick a region** (e.g. `swedencentral` if quotas elsewhere are tight).

2. **Create an azd environment** and set secrets before the first provision (values are substituted into [main.parameters.json](./main.parameters.json)):

   ```bash
   azd init
   azd env set AZURE_LOCATION swedencentral
   azd env set POSTGRES_ADMIN_PASSWORD '<alphanumeric-only-strong-password>'
   azd env set RAILS_MASTER_KEY "$(cat config/master.key)"
   azd env set SMTP_USERNAME '<your-smtp-username>'
   azd env set SMTP_PASSWORD '<your-smtp-password>'
   azd env set MAILER_FROM 'DoNotReply@<your-verified-domain>'
   ```

   `MAILER_FROM` is optional on first provision if you add it later in the portal; see [Email (Azure Communication Services)](#email-azure-communication-services).

   Optional (payments):

   ```bash
   azd env set STRIPE_SECRET_PUBLIC_KEY 'pk_live_...'
   azd env set STRIPE_SECRET_PRIVATE_KEY 'sk_live_...'
   azd env set STRIPE_WEBHOOK_SECRET 'whsec_...'
   ```

   Use an alphanumeric PostgreSQL password so `DATABASE_URL` in the template stays valid (no `@`, `#`, or spaces in the password).

3. **Deploy**:

   ```bash
   azd up
   ```

   First run: Bicep restores public modules from `br/public` (network required). `azd up` provisions infrastructure, builds the Docker image, pushes to ACR, and deploys the Container App.

4. **Open the site**: after `azd up`, use `SERVICE_WEB_URI` from `azd env get-values` or the Azure portal. `APP_HOST` is set automatically to the default Container Apps hostname for mailer URLs.

## Email (Azure Communication Services)

Production uses **SMTP** against **`smtp.azurecomm.net`** (port **587**, STARTTLS) with credentials from [Azure Communication Services Email](https://learn.microsoft.com/en-us/azure/communication-services/concepts/email/email-overview). This avoids consumer Gmail daily limits and matches the defaults in [`config/environments/production.rb`](../config/environments/production.rb).

### One-time Azure setup

1. Create an [Email Communication resource](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/create-email-communication-resource) and **provision a domain** (Azure-managed `*.azurecomm.net` or a [custom verified domain](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/add-azure-managed-domains)).
2. [Connect](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/connect-email-communication-resource) that Email resource to an **Azure Communication Services** resource.
3. [SMTP authentication](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/smtp-authentication): register a **Microsoft Entra application**, create a **client secret**, assign **Communication and Email Service Owner** on the Communication resource (IAM), then in the Communication resource create an **SMTP Username** linked to that app. The **SMTP Username** string is `SMTP_USERNAME`; the Entra **client secret** is `SMTP_PASSWORD`.
4. Set **`MAILER_FROM`** to a **sender address from your verified domain** (exact address shown in the portal). The app’s [`ApplicationMailer`](../app/mailers/application_mailer.rb) uses this for the `From:` header; it must match ACS, not an arbitrary domain.

Optional reading: [Send email with SMTP](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/send-email-smtp/send-email-smtp).

### azd / Container App environment

After the steps above:

```bash
azd env set SMTP_USERNAME '<smtp-username-from-azure-portal>'
azd env set SMTP_PASSWORD '<entra-application-client-secret>'
azd env set MAILER_FROM 'DoNotReply@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net'
```

Redeploy (`azd deploy` or `azd up`) so secrets and `MAILER_FROM` flow from [main.parameters.json](./main.parameters.json) into the template.

Optional overrides (rare): `SMTP_ADDRESS`, `SMTP_PORT`. For **implicit TLS on port 465** (e.g. legacy Gmail SMTP), set `SMTP_TLS_IMPLICIT=true` and `SMTP_ADDRESS=smtp.gmail.com` in the Container App environment variables.

## Migrations and releases

The production image runs [bin/docker-entrypoint](../bin/docker-entrypoint), which executes `rails db:prepare` before `rails server` when the command ends with `./bin/rails server`. New revisions therefore apply migrations on startup.

For a manual one-off migration (optional):

```bash
# From the repo root after azd up; use resource group and app name from `azd env get-values`.
az containerapp exec \
  --resource-group "<AZURE_RESOURCE_GROUP>" \
  --name "<SERVICE_WEB_NAME>" \
  --command "bundle exec rails db:migrate"
```

## Custom domain and HTTPS

In the Azure portal: Container App → **Custom domains** → add your domain and enable the managed certificate. Then update `APP_HOST` in the Container App environment variables to match the public hostname (or adjust Bicep and reprovision).

## Stripe webhooks

In the [Stripe Dashboard](https://dashboard.stripe.com/webhooks), add an endpoint:

`https://<your-public-host>/webhooks/stripe`

Use the signing secret as `STRIPE_WEBHOOK_SECRET` in azd / GitHub secrets and redeploy or update the Container App configuration.

## GitHub Actions

The workflow [.github/workflows/azure-dev.yml](../.github/workflows/azure-dev.yml) runs on **workflow_dispatch**. Configure variables, secrets, and federated credentials with:

```bash
azd pipeline config
```

Repository **Variables** (typical): `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AZURE_ENV_NAME`, `AZURE_LOCATION`.

Repository **Secrets** (typical): `POSTGRES_ADMIN_PASSWORD`, `RAILS_MASTER_KEY`, `SMTP_USERNAME`, `SMTP_PASSWORD`, and optional Stripe secrets. Set **`MAILER_FROM`** as a repository **Variable** (or secret) if you track the verified sender in `azd` / parameters.

## Solid Queue and background jobs

`SOLID_QUEUE_IN_PUMA` is **not** set on the Container App. Running the Solid Queue supervisor inside Puma can cause **`Detected Solid Queue has gone away, stopping Puma...`** and take down the web process on small instances.

Jobs still **enqueue** to PostgreSQL (`config.active_job.queue_adapter = :solid_queue` in production). To **process** jobs, run a separate worker (e.g. another Container App or Job running `bin/jobs` / `rails solid_queue:start`)—not covered by this template.

## Active Storage (product images)

The template provisions a **Storage Account**, a private blob container (`activestorage` by default), and injects **`AZURE_STORAGE_ACCOUNT_NAME`**, **`AZURE_STORAGE_ACCESS_KEY`** (Container App secret), and **`AZURE_STORAGE_CONTAINER`** into the web app. Production selects the **`azure`** service in `config/storage.yml` when those variables are present (see `config/environments/production.rb`).

Rails 8 no longer ships a first-party Azure adapter; the app uses the community gem **[azure-blob](https://github.com/testdouble/azure-blob)** (`AzureBlob` service), loaded from `config/application.rb`.

After the first deploy with Blob, **existing rows** in `active_storage_blobs` that pointed at local disk in an older revision will not magically exist in Blob; re-upload affected images or run a dedicated migration. New uploads use Azure Blob.

To repair **sample seed thumbnails** in-place (re-upload from `db/seeds/images` when download fails), run once after deploy:

```bash
az containerapp exec --resource-group "<AZURE_RESOURCE_GROUP>" --name "<SERVICE_WEB_NAME>" \
  --command "bundle exec rails marketplace:repair_seed_thumbnails"
```

Optional: switch to **managed identity** and omit the account key (grant the web app identity **Storage Blob Data Contributor** on the storage account, then configure `azure-blob` per its README). The current template uses a **shared key** for simplicity.

## Troubleshooting: Thruster / `listen tcp :80: permission denied`

The production image runs as **non-root** (`USER 1000` in the [Dockerfile](../Dockerfile)). Thruster’s default **`HTTP_PORT` is 80**, which non-root cannot bind. The template sets **`HTTP_PORT=8080`**, **`TARGET_PORT=3000`** (see [Thruster env](https://github.com/basecamp/thruster/blob/main/README.md)), and Container App **ingress target port 8080**. Run `azd provision` after changing these.

## Troubleshooting: PostgreSQL `plpgsql` not allow-listed

If logs show `extension "plpgsql" is not allow-listed`, open your **Flexible server** → **Server parameters** → **`azure.extensions`** and allow **`PLPGSQL`** (comma-separated with other extensions). Save, then restart the Container App.

## Troubleshooting: `RoleAssignmentExists` (AcrPull)

AcrPull for the web app’s managed identity is created **only** inside the `container-app-upsert` module (not duplicated in `core.bicep`). If you still see `RoleAssignmentExists`, you may have **leftover** role assignments from an older template that also defined AcrPull manually. Remove **duplicate** AcrPull rows on the Container Registry (IAM → same managed identity + AcrPull) until only one remains—or delete all direct AcrPull for that identity on the ACR and run `azd provision` again so a single assignment is recreated.

## Cost notes

Resources include a Burstable PostgreSQL flexible server, Basic ACR, Log Analytics, and Container Apps consumption. Delete the environment when finished:

```bash
azd down
```
