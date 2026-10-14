# Deploy IronLog to Azure App Service

The GitHub workflow builds Angular in production mode, publishes the .NET API,
and copies the Angular browser output into the published API's `wwwroot` folder.
The API serves the SPA and its routes; unknown `/api` routes return HTTP 404.
Development retains the separate Angular server and `http://localhost:5090` API.

## App configuration

Use the existing Linux .NET 10 Web App `ironlog-app-george` in `rg-ironlog`.
Configure these App Service environment variables (never commit their values):

- `ConnectionStrings__DefaultConnection`: Azure PostgreSQL connection string
  for `ironlog_db`, with `SSL Mode=Require`.
- `Jwt__Key`: a new random signing key of at least 32 bytes (64 random characters
  recommended). The checked-in signing key is for Development only.
- `ASPNETCORE_ENVIRONMENT`: `Production`.

Allow the Web App's outbound IPv4 addresses in the PostgreSQL firewall.
Restore the database before deployment; the workflow does not create or reset it.
The app uses its default HTTPS Azure hostname. Free F1 has shared compute,
daily CPU quotas and no Always On; it is intended for demos/development.

## Authorize GitHub Actions

Run `configure-azure-deployment.sh` in Azure Cloud Shell Bash. It creates a
user-assigned managed identity in Italy North, trusts only the repository's `main`
branch, and grants Website Contributor on this Web App. It also configures the
startup command, HTTPS-only access and deployment of prebuilt output.
Basic publishing authentication can remain disabled.

Copy the three printed IDs into GitHub **Settings > Secrets and variables >
Actions > Variables > New repository variable**:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These are identifiers, not credentials. OIDC issues short-lived tokens for each
deployment. Allow time for Azure role permissions to propagate before the first run.

Push to `main` or use **Actions > Build and deploy IronLog to Azure > Run workflow**.
Pull requests build and test without deploying. Verify the published `/login`
and `/dashboard` routes, authentication and workout details after deployment.

Reference: https://learn.microsoft.com/azure/app-service/deploy-github-actions
