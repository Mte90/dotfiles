Loaded on demand from ../SKILL.md — Periodic Tasks, Worker Deployment, and Scheduler comparison.

## Periodic Tasks with django-celery-beat

### Django Admin Configuration

`django-celery-beat` stores schedules in the database. Configure via Django admin or programmatically.

### Programmatic Schedules

In `myapp/schedule.py` or a data migration:

```python
from django_celery_beat.models import PeriodicTask, CrontabSchedule, IntervalSchedule

# Every 5 minutes
interval = IntervalSchedule.objects.create(every=5, period=IntervalSchedule.MINUTES)
PeriodicTask.objects.create(
    interval=interval,
    name='cleanup-sessions',
    task='myapp.tasks.cleanup_expired_sessions',
)

# Crontab: every day at 2:00 AM
crontab = CrontabSchedule.objects.create(
    hour=2,
    minute=0,
    timezone='Europe/Rome',
)
PeriodicTask.objects.create(
    crontab=crontab,
    name='daily-report',
    task='myapp.tasks.generate_daily_report',
    args=json.dumps(['daily']),
)

# Crontab: every Monday at 9:00 AM
weekly = CrontabSchedule.objects.create(
    hour=9,
    minute=0,
    day_of_week=1,
)
PeriodicTask.objects.create(
    crontab=weekly,
    name='weekly-summary',
    task='myapp.tasks.generate_weekly_summary',
)

# Crontab: every 15 minutes during business hours
business = CrontabSchedule.objects.create(
    minute='*/15',
    hour='9-17',
    day_of_week='1-5',
)
PeriodicTask.objects.create(
    crontab=business,
    name='sync-inventory',
    task='myapp.tasks.sync_inventory',
)
```

### Dynamic Schedules from Models

```python
from django.db import models
from django_celery_beat.models import PeriodicTask, CrontabSchedule
import json

class ScheduledReport(models.Model):
    name = models.CharField(max_length=200)
    hour = models.IntegerField(default=8)
    minute = models.IntegerField(default=0)
    day_of_week = models.CharField(max_length=20, default='*')
    is_active = models.BooleanField(default=True)
    periodic_task = models.ForeignKey(
        PeriodicTask, null=True, blank=True, on_delete=models.SET_NULL
    )

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self._update_schedule()

    def _update_schedule(self):
        if self.is_active:
            crontab, _ = CrontabSchedule.objects.get_or_create(
                hour=self.hour,
                minute=self.minute,
                day_of_week=self.day_of_week,
            )
            if self.periodic_task:
                self.periodic_task.crontab = crontab
                self.periodic_task.save()
            else:
                self.periodic_task = PeriodicTask.objects.create(
                    crontab=crontab,
                    name=f'report-{self.pk}',
                    task='myapp.tasks.generate_report',
                    args=json.dumps([self.pk]),
                )
                super().save(update_fields=['periodic_task'])
        elif self.periodic_task:
            self.periodic_task.delete()
            self.periodic_task = None
            super().save(update_fields=['periodic_task'])
```

---

## Running Workers

### Development

```bash
# Start worker
celery -A proj worker --loglevel=info

# Start beat scheduler (django-celery-beat)
celery -A proj beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler

# Or run both together (development only)
celery -A proj worker -B -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler
```

### Production (systemd)

`/etc/systemd/system/celery-worker.service`:

```ini
[Unit]
Description=Celery Worker
After=network.target redis.service

[Service]
Type=forking
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/venv/bin/celery -A proj multi start worker \
    --pidfile=/var/run/celery/%n.pid \
    --logfile=/var/log/celery/%n%I.log \
    --loglevel=INFO \
    --concurrency=4 \
    --max-tasks-per-child=1000
ExecStop=/opt/myapp/venv/bin/celery multi stopwait worker \
    --pidfile=/var/run/celery/%n.pid
ExecReload=/opt/myapp/venv/bin/celery -A proj multi restart worker \
    --pidfile=/var/run/celery/%n.pid \
    --logfile=/var/log/celery/%n%I.log \
    --loglevel=INFO
Restart=always

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/celery-beat.service`:

```ini
[Unit]
Description=Celery Beat Scheduler
After=network.target redis.service

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/opt/myapp
ExecStart=/opt/myapp/venv/bin/celery -A proj beat \
    --scheduler django_celery_beat.schedulers:DatabaseScheduler \
    --pidfile=/var/run/celery/beat.pid \
    --logfile=/var/log/celery/beat.log \
    --loglevel=INFO
Restart=always

[Install]
WantedBy=multi-user.target
```

---

## System Cron vs Celery-Beat: Choosing a Scheduler

For a single-server Django deployment, system cron + a management command is often simpler and more reliable than Celery + Redis + `django-celery-beat`. Use Celery only when the project already needs a task queue for async work, fan-out, or retries.

| Factor | System cron + `manage.py` command | Celery + `django-celery-beat` |
|--------|-----------------------------------|-------------------------------|
| Infrastructure | None (cron daemon) | Redis/RabbitMQ broker, worker process, beat process |
| Scheduling | OS crontab, one line per job | Database-backed `PeriodicTask`, admin-editable |
| Retries | Manual in the command | Native Celery retries with backoff |
| Observability | `JobLog` table + log files | Flower, Sentry, task state in DB |
| Concurrency | Sequential (or `&` between jobs) | Worker pool, task-level concurrency |
| Deployment | Add crontab entry per server | Deploy worker + beat as systemd services |
| Failure mode | One job failing doesn't block others | Broker outage stops all tasks |
| Best for | Nightly billing, daily sweep, imports | Real-time processing, fan-out, long-running jobs |

**Decision rule:** if the only async work is "run X daily/hourly," use system cron. If the project needs retries, fan-out, or sub-minute scheduling, introduce Celery.

### System cron pattern

```bash
# /etc/cron.d/regolo-billing
0 2 * * * regolo /app/.venv/bin/python /app/manage.py daily_processing >> /var/log/regolo/daily.log 2>&1
```

The management command wraps each item in a savepoint (see Batch Processing below) so one failure doesn't abort the run.

### Celery-Beat pattern

```python
# settings.py
CELERY_BEAT_SCHEDULE = {
    "daily-processing": {
        "task": "billing.tasks.daily_processing",
        "schedule": crontab(hour=2, minute=0),
    },
}
```