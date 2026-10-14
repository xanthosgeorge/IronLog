# IronLog

IronLog is a web-based post-workout fitness tracker. It lets an athlete organize muscle groups and exercises, then record workout sessions with ordered exercises, sets, load, repetitions, RPE, warm-up status, and notes.

The application is a full-stack project with an Angular single-page application, an ASP.NET Core REST API, and PostgreSQL.

## Features

- Manage muscle groups and their descriptions.
- Create, update, deactivate, and delete exercises.
- Record workout sessions with multiple exercises and sets.
- Track set weight, repetitions, RPE, warm-up status, resistance notes, and exercise notes.
- Calculate and store the total training load for each workout session.
- View workout-session lists and details.
- Protect workout history by preventing deletion of exercises or muscle groups that are still in use.
- Create an athlete account, sign in, and maintain a JWT-backed browser session.

## Technology stack

| Area | Technology |
| --- | --- |
| Frontend | Angular 21, TypeScript 5.9, SCSS, RxJS |
| Backend | ASP.NET Core 10, C# |
| Data access | Entity Framework Core 10 with Npgsql |
| Database | PostgreSQL 17, Docker Compose |
| API documentation | OpenAPI and Swagger in Development |
| Tests | Angular Karma/Jasmine and .NET xUnit |

## Architecture

```text
Angular frontend (port 4200)
        |
        | HTTP / JSON
        v
ASP.NET Core API (port 5090)
        |
        | Entity Framework Core
        v
PostgreSQL (host port 5433)
```

The .NET solution is divided into the following projects:

```text
backend/
  IronLog.Api             API host, controllers, OpenAPI, CORS configuration
  IronLog.Application     API request and response DTOs
  IronLog.Domain          Core entities and relationships
  IronLog.Persistence     EF Core DbContext, migrations, PostgreSQL registration
  IronLog.Infrastructure  Reserved infrastructure extension layer
tests/
  IronLog.Tests           xUnit persistence tests
frontend/
  iron-log-web            Angular application
database/
  docker-compose.yml      Local PostgreSQL service
```

Controllers currently access `ApplicationDbContext` directly. The `Application` project provides DTO contracts, while a dedicated application-service/use-case layer has not yet been introduced.

### Data model

```text
User
  └─ WorkoutSession
       └─ WorkoutExercise
            └─ WorkoutSet

MuscleGroup
  └─ Exercise
       └─ WorkoutExercise
```

Important database rules include unique email, muscle-group name, and exercise-name constraints; unique exercise ordering and set numbering within a session; cascade deletion of a session's exercise/set records; and restricted deletion of exercises and muscle groups that are already referenced.

## Prerequisites

Install the following before running the project:

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Node.js](https://nodejs.org/) 20.19 or later
- Docker Desktop with Docker Engine running
- Entity Framework Core CLI 10 (needed to apply migrations)

Install the EF CLI once if it is not already available:

```powershell
dotnet tool install --global dotnet-ef --version 10.*
```

## Run locally

Run each command from the repository root unless stated otherwise.

### 1. Start PostgreSQL

```powershell
docker compose -f database/docker-compose.yml up -d
```

This starts a local PostgreSQL 17 container with these development credentials:

| Setting | Value |
| --- | --- |
| Host | `localhost` |
| Host port | `5433` |
| Database | `ironlog_db` |
| Username | `ironlog` |
| Password | `ironlog` |

### 2. Restore packages and apply migrations

```powershell
dotnet restore IronLog.slnx
dotnet ef database update --project backend/IronLog.Persistence/IronLog.Persistence.csproj --startup-project backend/IronLog.Api/IronLog.Api.csproj
```

### 3. Start the API

```powershell
dotnet run --project backend/IronLog.Api/IronLog.Api.csproj --launch-profile http
```

The API runs at <http://localhost:5090>. In the Development environment, Swagger is available at <http://localhost:5090/swagger>.

### 4. Start the frontend

In a second terminal:

```powershell
Set-Location frontend/iron-log-web
npm ci
npm start
```

Open <http://localhost:4200>.

The frontend API URL is configured in [frontend/iron-log-web/src/environments/environment.ts](frontend/iron-log-web/src/environments/environment.ts).

## Mock workout data

After applying migrations and registering a user, run this from the repository root
with that user's email:

```powershell
Get-Content -Raw database/seed-mock-workouts.sql | docker exec -i ironlog-postgres psql -U ironlog -d ironlog_db -v user_email=your-email@example.com
```

This adds 16 Upper A/B and Lower A/B workouts from September 14 to October 10,
2026, with five exercises and three sets per workout, weights, reps, RPE, and
calculated total loads. Earlier weeks use progressively lighter weights and fewer
repetitions so the dashboard can show progressive overload across four weeks.
It reuses existing catalog entries and skips mock workouts already present for the
selected user. The entire seed runs in one transaction and requires an existing
account. Database schema migrations remain in `backend/IronLog.Persistence/Migrations`;
the seed contains no account credentials or password hashes.

## Available API endpoints

For deployment of the frontend and API together on Azure App Service, see
[deployment/README.md](deployment/README.md).


| Resource | Endpoint | Operations |
| --- | --- | --- |
| Authentication | `/api/Auth` | Register, login, view authenticated profile |
| Muscle groups | `/api/MuscleGroups` | List, get by ID, create, update, delete |
| Exercises | `/api/Exercises` | List, get by ID, create, update, delete |
| Workout sessions | `/api/WorkoutSessions` | List, get details, create, delete |

`GET /api/WorkoutSessions` returns a session summary. `GET /api/WorkoutSessions/{id}` returns the complete nested exercise and set structure.

All workout, exercise, and muscle-group endpoints require a bearer token. Register or sign in through the UI first; the Angular HTTP interceptor attaches the access token to API requests automatically. Workout sessions are scoped to the authenticated athlete, and their user ID is taken from the signed-in token rather than the request body.

## Authentication

The application provides these public endpoints:

| Endpoint | Description |
| --- | --- |
| `POST /api/Auth/register` | Creates an athlete account and returns an access token. |
| `POST /api/Auth/login` | Validates email/password credentials and returns an access token. |
| `GET /api/Auth/me` | Returns the signed-in athlete profile. |

Passwords are stored as ASP.NET Core Identity password hashes. Tokens expire after eight hours by default. The development JWT signing key in `appsettings.json` must be replaced with a secret supplied through secure production configuration before deployment.

## Development commands

### Frontend

Run from `frontend/iron-log-web`:

```powershell
npm start                         # Start the development server
npm run build                     # Create a production build
npm test -- --watch=false --browsers=ChromeHeadless
```

### Backend

Run from the repository root:

```powershell
dotnet build IronLog.slnx
dotnet test IronLog.slnx
```

To create an EF Core migration after a domain-model change:

```powershell
dotnet ef migrations add <MigrationName> --project backend/IronLog.Persistence/IronLog.Persistence.csproj --startup-project backend/IronLog.Api/IronLog.Api.csproj
```

## Stop local services

Stop the frontend and API with `Ctrl+C` in their terminal windows. Stop the database container while preserving its data volume with:

```powershell
docker compose -f database/docker-compose.yml down
```

To remove the database volume as well, use `docker compose -f database/docker-compose.yml down -v`. This permanently deletes local PostgreSQL data.

## Current limitations and next steps

- Progress, Analytics, and Settings are navigation placeholders that redirect to Dashboard.
- `IronLog.Infrastructure` is a placeholder project.
- API controllers currently contain persistence/query logic that could move into application services or commands/queries.
- Test coverage is currently focused on basic persistence and component checks; API integration coverage would be a valuable next addition.

## Repository notes

Generated directories such as `bin/`, `obj/`, `node_modules/`, and frontend `dist/` output should not be committed. The local PostgreSQL named Docker volume is managed outside the repository.
