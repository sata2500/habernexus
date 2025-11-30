from django.contrib import messages
from django.contrib.admin.views.decorators import staff_member_required
from django.shortcuts import redirect, render

from .models import Setting


@staff_member_required
def api_settings_view(request):
    """
    Google AI API anahtarı ve diğer API ayarlarını yönetmek için view.
    Sadece staff üyeleri erişebilir.
    """
    if request.method == "POST":
        # Google Gemini API Anahtarı
        gemini_key = request.POST.get("gemini_api_key", "").strip()
        if gemini_key:
            Setting.objects.update_or_create(
                key="GOOGLE_GEMINI_API_KEY",
                defaults={
                    "value": gemini_key,
                    "description": "Google Gemini API Anahtarı (İçerik üretimi için)",
                    "is_secret": True,
                },
            )
            messages.success(request, "✓ Google Gemini API Anahtarı kaydedildi.")

        # Google Imagen API Anahtarı (Gemini ile aynı olabilir)
        imagen_key = request.POST.get("imagen_api_key", "").strip()
        if imagen_key:
            Setting.objects.update_or_create(
                key="GOOGLE_IMAGEN_API_KEY",
                defaults={
                    "value": imagen_key,
                    "description": "Google Imagen API Anahtarı (Görsel üretimi için)",
                    "is_secret": True,
                },
            )
            messages.success(request, "✓ Google Imagen API Anahtarı kaydedildi.")

        # RSS Tarama Sıklığı (dakika cinsinden)
        rss_frequency = request.POST.get("rss_frequency", "15").strip()
        if rss_frequency.isdigit():
            Setting.objects.update_or_create(
                key="RSS_FETCH_FREQUENCY_MINUTES",
                defaults={
                    "value": rss_frequency,
                    "description": "RSS kaynakları tarama sıklığı (dakika cinsinden)",
                    "is_secret": False,
                },
            )
            messages.success(request, f"✓ RSS tarama sıklığı {rss_frequency} dakika olarak ayarlandı.")

        # İçerik Üretim Sıklığı (dakika cinsinden)
        content_frequency = request.POST.get("content_frequency", "30").strip()
        if content_frequency.isdigit():
            Setting.objects.update_or_create(
                key="CONTENT_GENERATION_FREQUENCY_MINUTES",
                defaults={
                    "value": content_frequency,
                    "description": "AI ile içerik üretim sıklığı (dakika cinsinden)",
                    "is_secret": False,
                },
            )
            messages.success(request, f"✓ İçerik üretim sıklığı {content_frequency} dakika olarak ayarlandı.")

        return redirect("admin:core_settings")

    # Mevcut ayarları getir
    settings_dict = {}
    settings = Setting.objects.all()

    for setting in settings:
        if setting.is_secret:
            # Gizli ayarlar için maskelenmiş değer göster
            settings_dict[setting.key] = "***" if setting.value else ""
        else:
            settings_dict[setting.key] = setting.value

    context = {
        "settings": settings_dict,
        "gemini_key_set": bool(Setting.objects.filter(key="GOOGLE_GEMINI_API_KEY").first()),
        "imagen_key_set": bool(Setting.objects.filter(key="GOOGLE_IMAGEN_API_KEY").first()),
        "rss_frequency": settings_dict.get("RSS_FETCH_FREQUENCY_MINUTES", "15"),
        "content_frequency": settings_dict.get("CONTENT_GENERATION_FREQUENCY_MINUTES", "30"),
    }

    return render(request, "admin/api_settings.html", context)


def get_setting(key, default=None):
    """
    Ayarları almak için yardımcı fonksiyon.
    Örnek: get_setting('GOOGLE_GEMINI_API_KEY')
    """
    try:
        setting = Setting.objects.get(key=key)
        return setting.value
    except Setting.DoesNotExist:
        return default
