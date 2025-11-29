# Haber Nexus

**Haber Nexus**, yapay zekanın gücünü kullanarak tam otomatik, 7/24 kusursuz çalışan profesyonel bir haber ajansıdır.

## Özellikler

- **Tam Otomatik İçerik Üretimi:** Google Gemini-3 Pro kullanarak RSS kaynaklarından çekilen verileri özgün, profesyonel içeriğe dönüştürür.
- **Profesyonel Görsel Üretimi:** Imagen-4 ile kusursuz görseller oluşturur veya RSS kaynaklarından orijinal görselleri kullanır.
- **Optimize Edilmiş Medya:** Tüm görseller WebP formatına dönüştürülerek optimize edilir.
- **Yönetim Paneli:** Django Admin ile kolay yönetim.
- **Taşınabilir Sistem:** Docker ile herhangi bir Ubuntu sunucusuna kurulabilir.
- **Güvenli Mimari:** Nginx proxy, Gunicorn uygulama sunucusu, PostgreSQL veritabanı.

## Teknoloji Yığını

- **Backend:** Python / Django
- **Frontend:** Django Templates + Tailwind CSS
- **Veritabanı:** PostgreSQL
- **Asenkron Görevler:** Celery + Redis
- **Web Sunucusu:** Nginx + Gunicorn
- **Konteynerleştirme:** Docker + Docker Compose
- **AI:** Google AI Python SDK

## Kurulum

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
docker-compose up -d
```

Daha fazla bilgi için `docs/` klasörüne bakınız.

## Geliştirici

Salih TANRISEVEN (salihtanriseven25@gmail.com)

## Lisans

Tüm hakları saklıdır.
