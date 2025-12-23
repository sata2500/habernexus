"""
HaberNexus Newsletter Tasks
Newsletter gönderimi için Celery görevleri.
"""

import logging
from datetime import timedelta

from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils import timezone
from django.utils.html import strip_tags

from celery import shared_task

from core.tasks import log_error, log_info

from .models import Article
from .models_newsletter import NewsletterEmail, NewsletterSubscriber

logger = logging.getLogger(__name__)


@shared_task
def send_daily_newsletter():
    """
    Günlük haber bülteni gönder.
    Her gün sabah 08:00'de çalışır.
    """
    try:
        # Günlük aboneleri al
        subscribers = NewsletterSubscriber.objects.filter(is_active=True, is_verified=True, frequency="daily")

        if not subscribers.exists():
            log_info("send_daily_newsletter", "Günlük abone bulunamadı")
            return "Günlük abone yok"

        # Son 24 saatin haberlerini al
        yesterday = timezone.now() - timedelta(days=1)
        articles = Article.objects.filter(status="published", published_at__gte=yesterday).order_by("-published_at")[
            :10
        ]

        if not articles.exists():
            log_info("send_daily_newsletter", "Gönderilecek haber bulunamadı")
            return "Gönderilecek haber yok"

        # E-posta içeriğini oluştur
        subject = f"Haber Nexus - Günlük Bülten ({timezone.now().strftime('%d.%m.%Y')})"

        # Newsletter kaydı oluştur
        newsletter_email = NewsletterEmail.objects.create(
            subject=subject,
            content="",  # HTML içerik aşağıda oluşturulacak
            status="sending",
            recipients_count=subscribers.count(),
        )

        sent_count = 0
        for subscriber in subscribers:
            try:
                html_message = render_to_string(
                    "emails/daily_newsletter.html",
                    {
                        "subscriber": subscriber,
                        "articles": articles,
                        "date": timezone.now(),
                    },
                )
                plain_message = strip_tags(html_message)

                send_mail(
                    subject,
                    plain_message,
                    settings.DEFAULT_FROM_EMAIL,
                    [subscriber.email],
                    html_message=html_message,
                    fail_silently=False,
                )

                subscriber.last_email_sent = timezone.now()
                subscriber.save(update_fields=["last_email_sent"])
                sent_count += 1

            except Exception as e:
                logger.error(f"E-posta gönderim hatası ({subscriber.email}): {e!s}")

        # Newsletter kaydını güncelle
        newsletter_email.status = "sent"
        newsletter_email.sent_at = timezone.now()
        newsletter_email.save()

        log_info("send_daily_newsletter", f"Günlük bülten gönderildi: {sent_count}/{subscribers.count()} abone")
        return f"Başarılı: {sent_count} e-posta gönderildi"

    except Exception as e:
        log_error("send_daily_newsletter", f"Günlük bülten hatası: {e!s}", traceback=str(e))
        raise


@shared_task
def send_weekly_newsletter():
    """
    Haftalık haber bülteni gönder.
    Her Pazartesi sabah 09:00'da çalışır.
    """
    try:
        # Haftalık aboneleri al
        subscribers = NewsletterSubscriber.objects.filter(is_active=True, is_verified=True, frequency="weekly")

        if not subscribers.exists():
            log_info("send_weekly_newsletter", "Haftalık abone bulunamadı")
            return "Haftalık abone yok"

        # Son 7 günün en popüler haberlerini al
        last_week = timezone.now() - timedelta(days=7)
        articles = Article.objects.filter(status="published", published_at__gte=last_week).order_by("-views_count")[:15]

        if not articles.exists():
            log_info("send_weekly_newsletter", "Gönderilecek haber bulunamadı")
            return "Gönderilecek haber yok"

        # E-posta içeriğini oluştur
        subject = f"Haber Nexus - Haftalık Özet ({timezone.now().strftime('%d.%m.%Y')})"

        # Newsletter kaydı oluştur
        newsletter_email = NewsletterEmail.objects.create(
            subject=subject,
            content="",
            status="sending",
            recipients_count=subscribers.count(),
        )

        sent_count = 0
        for subscriber in subscribers:
            try:
                html_message = render_to_string(
                    "emails/weekly_newsletter.html",
                    {
                        "subscriber": subscriber,
                        "articles": articles,
                        "date": timezone.now(),
                    },
                )
                plain_message = strip_tags(html_message)

                send_mail(
                    subject,
                    plain_message,
                    settings.DEFAULT_FROM_EMAIL,
                    [subscriber.email],
                    html_message=html_message,
                    fail_silently=False,
                )

                subscriber.last_email_sent = timezone.now()
                subscriber.save(update_fields=["last_email_sent"])
                sent_count += 1

            except Exception as e:
                logger.error(f"E-posta gönderim hatası ({subscriber.email}): {e!s}")

        # Newsletter kaydını güncelle
        newsletter_email.status = "sent"
        newsletter_email.sent_at = timezone.now()
        newsletter_email.save()

        log_info("send_weekly_newsletter", f"Haftalık bülten gönderildi: {sent_count}/{subscribers.count()} abone")
        return f"Başarılı: {sent_count} e-posta gönderildi"

    except Exception as e:
        log_error("send_weekly_newsletter", f"Haftalık bülten hatası: {e!s}", traceback=str(e))
        raise


@shared_task
def cleanup_unverified_subscribers():
    """
    24 saatten eski doğrulanmamış aboneleri temizle.
    Her gün gece yarısı çalışır.
    """
    try:
        cutoff_date = timezone.now() - timedelta(hours=24)
        deleted_count, _ = NewsletterSubscriber.objects.filter(
            is_verified=False, subscribed_at__lt=cutoff_date
        ).delete()

        log_info("cleanup_unverified_subscribers", f"{deleted_count} doğrulanmamış abone silindi")
        return f"Başarılı: {deleted_count} abone silindi"

    except Exception as e:
        log_error("cleanup_unverified_subscribers", f"Temizleme hatası: {e!s}", traceback=str(e))
        raise
