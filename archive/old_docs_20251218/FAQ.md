# Haber Nexus - Sıkça Sorulan Sorular (SSS)

**Sürüm:** 1.0  
**Son Güncelleme:** 11 Aralık 2025

---

## İçindekiler

1. [Genel Sorular](#genel-sorular)
2. [Kurulum Soruları](#kurulum-soruları)
3. [Yapılandırma Soruları](#yapılandırma-soruları)
4. [İçerik Üretimi Soruları](#içerik-üretimi-soruları)
5. [Teknik Sorular](#teknik-sorular)
6. [Sorun Giderme](#sorun-giderme)

---

## Genel Sorular

### S: Haber Nexus nedir?

**C:** Haber Nexus, Google Gemini AI kullanarak RSS kaynaklarından tam otomatik, profesyonel ve SEO uyumlu haber içeriği üreten, 7/24 kesintisiz çalışan yeni nesil bir haber ajansı platformudur.

### S: Projenin temel amacı nedir?

**C:** Projenin temel amacı, manuel müdahale olmadan, RSS beslemelerinden yüksek kaliteli ve özgün haber içeriği oluşturarak bir haber sitesini sürekli güncel tutmaktır.

### S: Proje hangi teknolojileri kullanıyor?

**C:** Proje; Django, Python, PostgreSQL, Redis, Celery, Docker, Nginx ve Google Gemini AI gibi modern teknolojileri kullanmaktadır. Detaylı liste için **[README](../README.md)** dosyasına bakabilirsiniz.

### S: Proje açık kaynaklı mı?

**C:** Hayır, proje tescilli (proprietary) bir lisansa sahiptir. Detaylar için **[LICENSE](../LICENSE)** dosyasına bakınız.

---

## Kurulum Soruları

### S: En kolay kurulum yöntemi hangisidir?

**C:** En kolay ve önerilen kurulum yöntemi **Docker**'dır. Tek bir komutla tüm servisleri ayağa kaldırabilirsiniz. Detaylar için **[Kurulum Rehberi](INSTALLATION.md)**'ne bakınız.

### S: Manuel kurulum yapabilir miyim?

**C:** Evet, manuel kurulum da mümkündür. Ancak, tüm bağımlılıkları (Python, PostgreSQL, Redis) kendiniz kurmanız ve yapılandırmanız gerekir. Detaylı adımlar için **[Kurulum Rehberi](INSTALLATION.md)**'nin "Local Development Setup" bölümünü inceleyebilirsiniz.

### S: Kurulum ne kadar sürer?

**C:** Docker ile kurulum yaklaşık 5-10 dakika sürer. Manuel kurulum ise sisteminize ve tecrübenize bağlı olarak 30-60 dakika sürebilir.

### S: Hangi işletim sistemlerini destekliyor?

**C:** Proje, Linux (Ubuntu önerilir), macOS ve Windows (WSL2 ile) üzerinde çalışabilir. Production ortamı için Ubuntu 22.04 LTS veya üstü önerilir.

---

## Yapılandırma Soruları

### S: `.env` dosyası nedir ve neden gerekli?

**C:** `.env` dosyası, projenin hassas yapılandırma bilgilerini (API anahtarları, veritabanı şifreleri vb.) saklamak için kullanılır. Bu dosya, güvenlik nedeniyle versiyon kontrol sistemine (Git) dahil edilmez. `.env.example` dosyasını kopyalayarak kendi `.env` dosyanızı oluşturmanız gerekir.

### S: Google Gemini API anahtarını nereden alabilirim?

**C:** Google Gemini API anahtarını Google Cloud Console üzerinden alabilirsiniz. Detaylı bilgi için Google'ın resmi dokümantasyonunu inceleyebilirsiniz.

### S: Veritabanı ayarlarını nasıl değiştiririm?

**C:** Veritabanı ayarlarını `.env` dosyasındaki `DB_` ile başlayan değişkenleri düzenleyerek yapabilirsiniz. Desteklenen veritabanları PostgreSQL ve SQLite'dır.

### S: Celery görevlerinin çalışma sıklığını nasıl ayarlarım?

**C:** Celery görevlerinin zamanlaması `habernexus_config/celery.py` dosyasındaki `beat_schedule` sözlüğü üzerinden yapılır. Buradaki `crontab` ifadelerini düzenleyerek görevlerin ne sıklıkla çalışacağını belirleyebilirsiniz.

---

## İçerik Üretimi Soruları

### S: Haberler hangi kaynaklardan alınıyor?

**C:** Haberler, Django admin panelinden eklediğiniz RSS kaynaklarından (RSS feeds) alınır. İstediğiniz kadar RSS kaynağı ekleyebilirsiniz.

### S: İçerik üretim süreci nasıl işliyor?

**C:** Süreç, RSS kaynaklarından başlıkların çekilmesi, kalite puanlaması, AI ile sınıflandırma, dinamik prompt'lar ile içerik üretimi, kalite kontrolü ve son olarak yayınlama adımlarından oluşur. Detaylı bilgi için **[İçerik Sistemi Rehberi](CONTENT_SYSTEM.md)**'ni inceleyebilirsiniz.

### S: Üretilen içeriğin kalitesini nasıl kontrol edebilirim?

**C:** Üretilen her içerik için okunabilirlik, SEO ve yapısal metrikler hesaplanır. Bu metrikleri Django admin panelindeki "Content Quality Metrics" bölümünden inceleyebilirsiniz.

### S: AI modelini değiştirebilir miyim?

**C:** Evet, `.env` dosyasındaki `GEMINI_MODEL` değişkenini düzenleyerek farklı bir Gemini modelini (örneğin `gemini-2.5-pro`) kullanabilirsiniz. Ancak, prompt'ların yeni modele uygunluğunu test etmeniz gerekebilir.

---

## Teknik Sorular

### S: Proje neden Celery kullanıyor?

**C:** Celery, RSS beslemelerini tarama, AI ile içerik üretme gibi uzun süren işlemleri arka planda asenkron olarak çalıştırmak için kullanılır. Bu sayede web uygulaması bloke olmaz ve kullanıcı deneyimi olumsuz etkilenmez.

### S: Neden PostgreSQL yerine MySQL kullanamıyorum?

**C:** Proje, Django'nun PostgreSQL'e özel bazı özelliklerini (JSONField vb.) kullanabilir. MySQL ile uyumluluk sorunları yaşanabilir. Bu nedenle PostgreSQL kullanılması şiddetle tavsiye edilir.

### S: Projeyi nasıl ölçeklendirebilirim?

**C:** Projeyi yatay olarak (daha fazla sunucu ekleyerek) veya dikey olarak (sunucu kaynaklarını artırarak) ölçeklendirebilirsiniz. Docker Swarm veya Kubernetes gibi orkestrasyon araçları ile Django ve Celery worker'larının sayısını artırabilirsiniz.

### S: Testleri nasıl çalıştırabilirim?

**C:** Proje ana dizinindeyken `python manage.py test` komutunu çalıştırarak tüm testleri çalıştırabilirsiniz. Belirli bir uygulamanın testlerini çalıştırmak için `python manage.py test news` gibi bir komut kullanabilirsiniz.

---

## Sorun Giderme

### S: "502 Bad Gateway" hatası alıyorum, ne yapmalıyım?

**C:** Bu hata genellikle Gunicorn (Django uygulama sunucusu) servisinin çalışmadığı anlamına gelir. `docker-compose logs app` komutu ile logları kontrol ederek sorunun kaynağını bulabilirsiniz. Genellikle bir yapılandırma hatası veya kod hatası nedeniyle servis başlamamıştır.

### S: Statik dosyalar (CSS, JS) yüklenmiyor, sayfa bozuk görünüyor.

**C:** Bu sorun genellikle statik dosyaların toplanmamasından kaynaklanır. `docker-compose exec app python manage.py collectstatic --noinput` komutunu çalıştırarak statik dosyaları toplayın ve ardından `docker-compose restart nginx` komutu ile Nginx'i yeniden başlatın.

### S: Celery görevleri çalışmıyor, yeni haberler üretilmiyor.

**C:** `docker-compose logs celery` ve `docker-compose logs celery_beat` komutları ile Celery loglarını kontrol edin. Redis bağlantısında bir sorun olabilir veya görevlerde bir hata meydana gelmiş olabilir. Servisleri `docker-compose restart celery celery_beat` komutu ile yeniden başlatmayı deneyin.

### S: Daha fazla sorun giderme bilgisine nereden ulaşabilirim?

**C:** Detaylı sorun giderme adımları için **[Sorun Giderme Rehberi](TROUBLESHOOTING.md)**'ni inceleyebilirsiniz.
