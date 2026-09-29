<!-- This file is loaded on demand from frameworks/django/SKILL.md -->

## Ecosystem Libraries

### iommi
- **URL**: https://github.com/iommirocks/iommi (docs: https://docs.iommi.rocks/)
- **PyPI**: `iommi`
- **Version**: 7.31.0 (Python >=3.12; Django >=5.2, tested on Django 5.2 and 6.0)

A high-level framework built on Django for building web apps (CRUD apps) faster, without writing HTML or JavaScript. Composes forms, tables, menus, and fragments into full pages declaratively in Python.

**Key features**:
- Forms that feel like Django forms but scale to complex cases (auto-config from models)
- Powerful tables (list, filter, sort, paginate) plus edit tables for full CRUD
- Page composition system: combine forms, tables, menus, fragments into pages with access control
- Dev tools: live edit, jump-to-code, profiler, SQL trace, feedback for missing select/prefetch
- Actionable error messages when configuration is wrong

```bash
pip install iommi
```

### django-boilerplate (SaaS Pegasus)
- **URL**: https://github.com/saaspegasus/django-boilerplate
- **PyPI**: N/A (the `django-boilerplate` PyPI name belongs to an unrelated abandoned package — use by forking/cloning this repo)
- **Version**: No tagged releases (README targets Django 6 on Python 3.14)

The open-source edition of the SaaS Pegasus boilerplate: a free, production-grade starting point for a new Django app with a modern front-end stack and built-in essentials, optimized for the AI-agent era.

**Key features**:
- Django 6 on Python 3.14 with clean project structure
- Authentication via django-allauth (sign-up, login, password reset, email verification)
- HTMX + Alpine.js interactivity; Tailwind CSS v4 + DaisyUI wired through Vite and django-vite
- REST API on Django REST Framework with an auto-generated, OpenAPI-typed API client
- Celery + Redis background tasks, Postgres, Docker Compose, uv, Ruff, pre-commit, pytest, GitHub Actions CI, and agent-ready `CLAUDE.md`/`AGENTS.md` files

```bash
git clone https://github.com/saaspegasus/django-boilerplate.git
cd django-boilerplate
make init   # builds Postgres/Redis, runs migrations, installs frontend deps (Docker required)
make dev    # run app at localhost:8000
```

### double-turbo
- **URL**: https://github.com/Mte90/double-turbo
- **PyPI**: N/A (not on PyPI; repo-only boilerplate)
- **Version**: 0.1.0 (Python >=3.13, Django >=5.1)

A pure-API Django boilerplate aimed at SaaS development, built on Turbo (the Unfold admin boilerplate) plus TurboDRF, shipping a complete API project with admin panel and production deployment pieces.

**Key features**:
- Automatic REST API generation from models via TurboDRF, with an Unfold-admin-based admin panel and Swagger docs
- Stripe subscriptions via a fork of drf-stripe-subscription (multi-user membership)
- Auth stack: django-allauth + dj-rest-auth (JWT), dj-hijack (work on behalf of users), inactive users by default
- Ops tooling: django-prometheus metrics, drf-api-tracking, django-auditlog, Loguru logging (django-easy-logging), django-split-settings + python-dotenv
- Production deployment: Dockerfile, Nginx config, Celery/Celery Beat systemd services (RabbitMQ), GitLab CI example with `deploy-prod.sh`

```bash
git clone https://github.com/Mte90/double-turbo.git
cd double-turbo
uv sync
python setup.py   # initialize the database
uv run -- python manage.py runserver 0.0.0.0:8000
```

### nanodjango
- **URL**: https://github.com/radiac/nanodjango
- **PyPI**: `nanodjango`
- **Version**: 0.16.3 (Python >=3.8 declared; Django >=5.2 dependency, so effectively modern Python 3.10+)

Write a complete Django site — models, views, admin, and API — in a single `.py` file, run it locally or in production, and share it as a standalone script.

**Key features**:
- Single-file apps: `@app.route`, standard Django models auto-registered with the admin, class-based or function views
- Built-in Django Ninja API support (`@app.api.get`) and async view support
- CLI: `nanodjango run` (dev server + auto migrations), `nanodjango manage` (any manage.py command), `nanodjango serve` (gunicorn/uvicorn with production defaults)
- `nanodjango convert` upgrades the single file into a full Django project when it outgrows one file
- Shareable apps via PEP 723 inline script metadata: run with `uv run script.py` / `pipx run script.py`, no install needed; online playground at nanodjango.dev/play

```bash
pip install nanodjango
```

### neapolitan
- **URL**: https://github.com/carltongibson/neapolitan
- **PyPI**: `neapolitan`
- **Version**: 26.1 (CalVer: year.release; supports all current Django and Python versions, dropped at EOL)

Provides quick CRUD views for Django: one `CRUDView` subclass gives you the standard list, detail, create, edit, and delete views for a model, with hooks to customize any part.

**Key features**:
- `CRUDView.get_urls()` generates standard CRUD URLs for a model with minimal configuration
- Customization hooks on every part of the flow (fields, filters, actions, templates)
- Filtering via `filterset_fields` (uses django-filter)
- Base templates and reusable template tags for getting model data on the page
- Docs at https://noumenal.es/neapolitan/

```bash
pip install neapolitan
# then add "neapolitan" to INSTALLED_APPS and create a base.html with a {% block content %}
```

### django-migration-zero
- **URL**: https://github.com/ambient-innovation/django-migration-zero
- **PyPI**: `django-migration-zero`
- **Version**: 2.4.1 (Python >=3.11; Django >=4.2)

A holistic implementation of the "migration zero" pattern for Django: cleans up local migrations and handles updating the migration history of already-deployed environments (test/production), as an alternative to Django's squashing.

**Key features**:
- Removes all existing local migration files and recreates them as a fresh initial migration set
- Configuration singleton in the Django admin to prepare the clean-up deployment
- Management command for CI/CD pipelines that rewrites Django's migration history table to match the recreated migrations
- Alternative to migration squashing that avoids circular-dependency problems (for apps where you control all environments)
- 100% test coverage; fully automated, Sigstore-signed releases via PyPI Trusted Publishing

```bash
pip install django-migration-zero
# then add 'django_migration_zero' to INSTALLED_APPS
```

### django-maintenance-mode
- **URL**: https://github.com/fabiocaccamo/django-maintenance-mode
- **PyPI**: `django-maintenance-mode`
- **Version**: 0.23.0 (Django >=4.2)

Middleware that shows a 503 error page while maintenance mode is on. Works at application level (the Django instance must be up) and does not use the database, so it's safe during deployments and DB migrations.

**Key features**:
- Multiple state backends: local file (default), Django default storage, static storage, and cache — no database required
- Fine-grained ignore rules: admin site, staff, superusers, authenticated/anonymous users, IP addresses, and URL patterns
- Scheduled maintenance windows with `start`/`end` datetimes — auto on/off without cron
- Toggle from anywhere: Python API (`set_maintenance_mode`), `manage.py maintenance_mode on|off`, superuser URLs, view decorators, and context managers
- Configurable 503 template, HTML or JSON response type, custom status code, and Retry-After header

```bash
pip install django-maintenance-mode
# add maintenance_mode to INSTALLED_APPS, MaintenanceModeMiddleware to MIDDLEWARE, and a templates/503.html
```

### django-recurrence
- **URL**: https://github.com/jazzband/django-recurrence
- **PyPI**: `django-recurrence`
- **Version**: 1.14 (Python >=3.9; Django >=4.0)

Django utility for working with recurring dates, wrapping `dateutil.rrule` in an RFC 2445-compatible subset so you can store and render recurrence rules in Django models and forms.

**Key features**:
- `Recurrence`/`Rule` objects for specifying recurring dates/times (wraps `dateutil.rrule`)
- `RecurrenceField` model field that serializes recurrence information for database storage
- JavaScript widget included for form rendering
- Template tags/filters for expanding recurrence rules in templates
- Jazzband-maintained with active CI across supported Python/Django versions; docs at django-recurrence.readthedocs.io

```bash
pip install django-recurrence
```

### dj-database-url
- **URL**: https://github.com/jazzband/dj-database-url
- **PyPI**: `dj-database-url`
- **Version**: 3.1.2 (Python >=3.10; Django >=4.2)

A simple utility that lets you configure your Django `DATABASES` setting from a 12-factor `DATABASE_URL` environment variable.

**Key features**:
- `dj_database_url.config()` reads the `DATABASE_URL` env var, with a `default=` fallback
- `dj_database_url.parse()` to configure Django from any arbitrary database URL string
- `conn_max_age` (CONN_MAX_AGE) and `conn_health_checks` (CONN_HEALTH_CHECKS) options for connection pooling
- Supports PostgreSQL/PostGIS, MySQL/MySQL GIS, Oracle/Oracle GIS, MSSQL, Redshift, CockroachDB, Timescale/Timescale GIS, SQLite/SpatiaLite
- `register()` to add custom backends, including post-processing hooks for backend-specific config; `test_options` for test DB settings

```bash
pip install dj-database-url
```
### django-extensions

- **URL**: https://github.com/django-extensions/django-extensions
- **PyPI**: `django-extensions`
- **Key features**: `shell_plus` (auto-import all models), `runserver_plus` (debug server with Werkzeug), plus 50+ management commands for debugging and development

### whitenoise
- **URL**: https://github.com/evansd/whitenoise
- **PyPI**: `whitenoise`
- **Key features**: Simplified static file serving for Django apps (no need for separate web server in development, works with Gunicorn/uWSGI)

### django-environ
- **URL**: https://github.com/joke2k/django-environ
- **PyPI**: `django-environ`
- **Key features**: 12-factor environment variables management, companion to dj-database-url for parsing DATABASE_URL and other settings from env vars

### Additional Ecosystem Libraries

- **django-crispy-forms** (https://github.com/django-crispy-forms/django-crispy-forms) - Elegant form rendering with template packs
- **django-widget-tweaks** (https://github.com/jazzband/django-widget-tweaks) - Render form widgets as template tags (modify attrs in templates)
- **django-taggit** (https://github.com/jazzband/django-taggit) - Simple tagging for Django models
- **django-model-utils** (https://github.com/jazzband/django-model-utils) - Django model mixins and utilities (TimeStampedModel, StatusField, etc.)
- **django-polymorphic** (https://github.com/django-commons/django-polymorphic) - Transparent polymorphic models (better than default Django admin)

### awesome-django


