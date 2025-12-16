"""
HaberNexus Newsletter Views
Newsletter abonelik işlemleri için view'lar.
"""

import logging

from django.conf import settings
from django.core.mail import send_mail
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods

from .models_newsletter import NewsletterSubscriber

logger = logging.getLogger(__name__)


def get_client_ip(request):
    """İstemci IP adresini al."""
    x_forwarded_for = request.META.get("HTTP_X_FORWARDED_FOR")
    if x_forwarded_for:
        ip = x_forwarded_for.split(",")[0]
    else:
        ip = request.META.get("REMOTE_ADDR")
    return ip


class NewsletterSubscribeView(View):
    """
    Newsletter abonelik view'ı.
    POST: Yeni abone ekle
    """

    def post(self, request):
        email = request.POST.get("email", "").strip().lower()
        name = request.POST.get("name", "").strip()
        frequency = request.POST.get("frequency", "daily")

        # Validasyon
        if not email:
            return JsonResponse({"success": False, "message": "E-posta adresi gerekli."}, status=400)

        if "@" not in email or "." not in email:
            return JsonResponse({"success": False, "message": "Geçerli bir e-posta adresi girin."}, status=400)

        try:
            # Mevcut abone kontrolü
            subscriber, created = NewsletterSubscriber.objects.get_or_create(
                email=email, defaults={"name": name, "frequency": frequency, "ip_address": get_client_ip(request)}
            )

            if not created:
                if subscriber.is_active:
                    return JsonResponse(
                        {"success": False, "message": "Bu e-posta adresi zaten abone."}, status=400
                    )
                else:
                    # Tekrar abone ol
                    subscriber.resubscribe()
                    subscriber.name = name
                    subscriber.frequency = frequency
                    subscriber.save()

            # Doğrulama e-postası gönder
            self.send_verification_email(subscriber)

            return JsonResponse(
                {
                    "success": True,
                    "message": "Aboneliğinizi doğrulamak için e-postanızı kontrol edin.",
                }
            )

        except Exception as e:
            logger.error(f"Newsletter abonelik hatası: {str(e)}")
            return JsonResponse({"success": False, "message": "Bir hata oluştu. Lütfen tekrar deneyin."}, status=500)

    def send_verification_email(self, subscriber):
        """Doğrulama e-postası gönder."""
        try:
            verification_url = f"https://habernexus.com/newsletter/verify/{subscriber.verification_token}/"

            subject = "Haber Nexus - E-posta Doğrulama"
            html_message = render_to_string(
                "emails/newsletter_verification.html",
                {"subscriber": subscriber, "verification_url": verification_url},
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
        except Exception as e:
            logger.error(f"Doğrulama e-postası gönderim hatası: {str(e)}")


class NewsletterVerifyView(View):
    """
    E-posta doğrulama view'ı.
    """

    def get(self, request, token):
        try:
            subscriber = get_object_or_404(NewsletterSubscriber, verification_token=token)

            if subscriber.is_verified:
                return render(
                    request,
                    "newsletter/already_verified.html",
                    {"subscriber": subscriber},
                )

            subscriber.verify()

            return render(
                request,
                "newsletter/verified.html",
                {"subscriber": subscriber},
            )

        except Exception as e:
            logger.error(f"E-posta doğrulama hatası: {str(e)}")
            return render(request, "newsletter/error.html", {"message": "Doğrulama başarısız."})


class NewsletterUnsubscribeView(View):
    """
    Abonelik iptal view'ı.
    """

    def get(self, request, token):
        try:
            subscriber = get_object_or_404(NewsletterSubscriber, token=token)

            return render(
                request,
                "newsletter/unsubscribe_confirm.html",
                {"subscriber": subscriber},
            )

        except Exception as e:
            logger.error(f"Abonelik iptal hatası: {str(e)}")
            return render(request, "newsletter/error.html", {"message": "Abonelik bulunamadı."})

    def post(self, request, token):
        try:
            subscriber = get_object_or_404(NewsletterSubscriber, token=token)
            subscriber.unsubscribe()

            return render(
                request,
                "newsletter/unsubscribed.html",
                {"subscriber": subscriber},
            )

        except Exception as e:
            logger.error(f"Abonelik iptal hatası: {str(e)}")
            return render(request, "newsletter/error.html", {"message": "Abonelik iptal edilemedi."})


class NewsletterPreferencesView(View):
    """
    Abonelik tercihlerini yönetme view'ı.
    """

    def get(self, request, token):
        try:
            subscriber = get_object_or_404(NewsletterSubscriber, token=token)

            return render(
                request,
                "newsletter/preferences.html",
                {"subscriber": subscriber, "frequency_choices": NewsletterSubscriber.FREQUENCY_CHOICES},
            )

        except Exception as e:
            logger.error(f"Tercih görüntüleme hatası: {str(e)}")
            return render(request, "newsletter/error.html", {"message": "Abonelik bulunamadı."})

    def post(self, request, token):
        try:
            subscriber = get_object_or_404(NewsletterSubscriber, token=token)

            frequency = request.POST.get("frequency", subscriber.frequency)
            name = request.POST.get("name", subscriber.name)

            subscriber.frequency = frequency
            subscriber.name = name
            subscriber.save(update_fields=["frequency", "name"])

            return render(
                request,
                "newsletter/preferences_updated.html",
                {"subscriber": subscriber},
            )

        except Exception as e:
            logger.error(f"Tercih güncelleme hatası: {str(e)}")
            return render(request, "newsletter/error.html", {"message": "Tercihler güncellenemedi."})
