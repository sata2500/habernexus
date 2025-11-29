import os
from celery import Celery
from celery.schedules import crontab

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'habernexus_config.settings')

app = Celery('habernexus_config')

# Django settings'den Celery yapılandırmasını yükle
app.config_from_object('django.conf:settings', namespace='CELERY')

# Django uygulamalarından task'ları otomatik olarak keşfet
app.autodiscover_tasks()

# Periyodik Görevler (Celery Beat)
app.conf.beat_schedule = {
    # RSS kaynaklarını her 15 dakikada bir tara
    'fetch-rss-feeds': {
        'task': 'news.tasks.fetch_rss_feeds',
        'schedule': crontab(minute='*/15'),  # Her 15 dakikada bir
    },
    # Sistem loglarını temizle (her hafta)
    'cleanup-old-logs': {
        'task': 'core.tasks.cleanup_old_logs',
        'schedule': crontab(hour=2, minute=0, day_of_week=0),  # Pazartesi saat 2:00
    },
}

@app.task(bind=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
