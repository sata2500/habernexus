"""
Gunicorn yapılandırması
Production ortamında Django uygulamasını çalıştırmak için kullanılır.
"""

import multiprocessing
import os

# Server socket
bind = os.getenv("GUNICORN_BIND", "127.0.0.1:8000")
backlog = 2048

# Worker processes
workers = int(os.getenv("GUNICORN_WORKERS", multiprocessing.cpu_count() * 2 + 1))
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "/var/log/habernexus/gunicorn_access.log"
errorlog = "/var/log/habernexus/gunicorn_error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "habernexus"

# Server mechanics
daemon = False
pidfile = "/var/run/habernexus/gunicorn.pid"
umask = 0o022
user = None
group = None
tmp_upload_dir = None

# SSL (Nginx tarafından handle edilir, burada gerekli değil)
# keyfile = None
# certfile = None

# Application
wsgi_app = "habernexus_config.wsgi:application"
raw_env = []


# Server hooks
def on_starting(server):
    print("Gunicorn server başlatılıyor...")


def when_ready(server):
    print("Gunicorn server hazır!")


def on_exit(server):
    print("Gunicorn server kapatılıyor...")
