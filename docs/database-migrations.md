# Database migrations and deployment

The API applies pending Entity Framework Core migrations at startup, before it accepts requests. It uses `ConnectionStrings__DefaultConnection` from the current environment: the development database locally and the Azure PostgreSQL database in App Service.

The deployment flow is:

1. Push application changes and generated migration files to `main`.
2. GitHub Actions builds, tests, and deploys the application to Azure App Service.
3. On startup, the deployed API applies migrations absent from the target database's `__EFMigrationsHistory` table.
4. The API starts serving requests only after migration succeeds. Subsequent starts do not reapply completed migrations.

The database account must have permission to apply schema changes. If migration fails, startup fails and the exception appears in App Service logs; do not mark the deployment healthy until startup succeeds. Logs include `Database migrations completed.` on success.

`20261018174424_AddBodyWeightEntries` adds the body-weight table, its user foreign key, and an index. It does not modify existing measurements or workout data.

Review every migration before deployment. For future destructive or long-running migrations, take a database backup and use a controlled maintenance process instead of relying on automatic startup. Deployments do not automatically reverse database migrations when application code is rolled back.
