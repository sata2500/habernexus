from .settings import *

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}

# Disable Elasticsearch for tests if not available
ELASTICSEARCH_DSL_AUTOSYNC = False
ELASTICSEARCH_DSL_AUTO_REFRESH = False

# Use local memory cache for tests
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}

# Disable Celery for tests
CELERY_TASK_ALWAYS_EAGER = True
