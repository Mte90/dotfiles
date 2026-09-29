---
name: django
description: Use when building Django applications - security hardening, authentication and permissions, ORM optimization, PostgreSQL features, Django 6.0, migrations, testing, and ecosystem libraries
metadata:
  author: mte90
  version: 3.0.0
  tags:
    - python
    - django
    - security
    - orm
    - postgresql
    - admin
    - authentication
    - sessions
---

# Django

Comprehensive guide to Django covering security, ORM, PostgreSQL, GeoDjango, Django 6.0 essentials, admin extensions, and ecosystem tools.

## Overview

Django provides a batteries-included web framework with robust features out of the box:
- **Security** - CSRF protection, authentication, sessions, password hashing, security middleware
- **ORM** - Powerful database abstraction with query optimization
- **PostgreSQL** - Full-text search, array fields, JSONB, range fields
- **GeoDjango** - Geographic database operations with GPS extraction
- **Django 6.0** - Middleware changes, built-in tasks framework, CSP, GeneratedField
- **Admin Extensions** - Operational dashboards and monitoring tools
Django provides robust security features out of the box:
- **CSRF Protection** - Prevents cross-site request forgery
- **Authentication** - User login/logout, password management
- **Sessions** - Secure session management
- **Security Middleware** - Various security headers
- **Password Hashing** - Secure password storage

## Specialized Skills

For deeper coverage of specific domains, see these dedicated skills:

- ↳ **[django-admin](frameworks/django-admin/SKILL.md)** — Admin save_formset/get_search_results/db_index patterns
- ↳ **[django-transaction](frameworks/django-transaction/SKILL.md)** — atomic/select_for_update/on_commit/upserts

---

## Deep Dives

Load these reference files on demand for detailed coverage:

- ↳ **[security.md](references/security.md)** — CSRF protection, sessions, security middleware, field-level encryption
- ↳ **[authentication-permissions.md](references/authentication-permissions.md)** — Authentication views, custom backends, password management, login templates, Django permissions
- ↳ **[orm-performance.md](references/orm-performance.md)** — ORM optimization, caching, response time, materialized views
- ↳ **[postgresql.md](references/postgresql.md)** — pgvector, GeneratedField, GeoDjango, PostgreSQL features
- ↳ **[django6-modern.md](references/django6-modern.md)** — Django Tasks framework, 6.0 essentials, multi-DB routing, model fields, app naming
- ↳ **[testing-migrations.md](references/testing-migrations.md)** — Testing optimization, migrations, signals, StreamingHttpResponse
- ↳ **[external-api.md](references/external-api.md)** — Operational dashboards, external API integration
- ↳ **[ecosystem.md](references/ecosystem.md)** — Django ecosystem libraries

---

## Best Practices

1. **Always use {% csrf_token %}** in POST forms
2. **Use HTTPS** in production (SECURE_SSL_REDIRECT = True)
3. **Enable HSTS** for secure connections
4. **Set secure cookies** (SESSION_COOKIE_SECURE = True)
5. **Use strong password validation**
6. **Use @login_required** for protected views
7. **Never expose sensitive data** in URLs or logs
8. **Validate file uploads** carefully
9. **Use prepared statements** (Django ORM does this automatically)

---

## References

