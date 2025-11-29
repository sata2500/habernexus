from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import SystemLog


@shared_task
def cleanup_old_logs():
    """
    Eski sistem loglarını temizle (30 günden eski olanları sil).
    Haftalık olarak çalışacak.
    """
    try:
        cutoff_date = timezone.now() - timedelta(days=30)
        deleted_count, _ = SystemLog.objects.filter(created_at__lt=cutoff_date).delete()
        
        SystemLog.objects.create(
            level='INFO',
            task_name='cleanup_old_logs',
            message=f'{deleted_count} eski log silindi.'
        )
        
        return f'Başarılı: {deleted_count} log silindi'
    except Exception as e:
        SystemLog.objects.create(
            level='ERROR',
            task_name='cleanup_old_logs',
            message=f'Hata: {str(e)}',
            traceback=str(e)
        )
        raise


def log_error(task_name, message, traceback=None, related_id=None):
    """
    Hata kaydı tutmak için yardımcı fonksiyon.
    Celery görevlerinden çağrılır.
    """
    SystemLog.objects.create(
        level='ERROR',
        task_name=task_name,
        message=message,
        traceback=traceback or '',
        related_id=related_id
    )


def log_info(task_name, message, related_id=None):
    """
    Bilgi kaydı tutmak için yardımcı fonksiyon.
    """
    SystemLog.objects.create(
        level='INFO',
        task_name=task_name,
        message=message,
        related_id=related_id
    )
