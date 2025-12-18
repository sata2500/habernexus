# Haber Nexus - Sorun Giderme Rehberi

Bu rehber, Haber Nexus projesini kurarken veya çalıştırırken karşılaşabileceğiniz yaygın sorunları ve çözümlerini içerir.

---

## İçindekiler

1. [Docker Sorunları](#docker-sorunları)
2. [Uygulama Sorunları](#uygulama-sorunları)
3. [Celery Sorunları](#celery-sorunları)
4. [Veritabanı Sorunları](#veritabanı-sorunları)
5. [Performans Sorunları](#performans-sorunları)

---

## Docker Sorunları

### Sorun: `docker-compose up` komutu hata veriyor.

- **Çözüm 1: Port Çakışması:** Başka bir servis Docker\ın kullanmak istediği bir portu (örn: 80, 5432) kullanıyor olabilir. `sudo lsof -i :80` gibi bir komutla portu hangi servisin kullandığını bulun ve durdurun.
- **Çözüm 2: İmaj Derleme Hatası:** `docker-compose up --build` komutunu kullanarak imajları yeniden derlemeyi deneyin. `Dockerfile` veya `requirements.txt` dosyasında bir hata olabilir. Logları dikkatlice inceleyin.
- **Çözüm 3: Disk Alanı:** Sunucunuzda yeterli disk alanı olduğundan emin olun. `df -h` komutu ile kontrol edebilirsiniz.

### Sorun: Konteynerler sürekli yeniden başlıyor (Restarting).

- **Çözüm:** Bu genellikle konteynerin içindeki ana işlem başlar başlamaz çöktüğünde olur. `docker-compose logs <servis_adı>` (örn: `docker-compose logs app`) komutu ile ilgili servisin loglarını inceleyerek hatanın nedenini bulun. Genellikle bir yapılandırma hatası veya kod hatasıdır.

---

## Uygulama Sorunları

### Sorun: Site açıldığında "502 Bad Gateway" hatası alıyorum.

- **Açıklama:** Bu hata, Nginx\in Django uygulamasına (Gunicorn) ulaşamadığı anlamına gelir.
- **Çözüm:** `docker-compose logs app` komutu ile Django uygulamasının loglarını kontrol edin. Uygulama bir hata nedeniyle başlamamış olabilir. Yaygın nedenler:
  - `.env` dosyasındaki bir yapılandırma hatası.
  - `settings.py` dosyasındaki bir Python hatası.
  - Veritabanı bağlantı sorunu.

### Sorun: Statik dosyalar (CSS, JS) yüklenmiyor, sayfa bozuk görünüyor.

- **Açıklama:** Bu, Nginx\in statik dosyaları bulamadığı anlamına gelir.
- **Çözüm 1 (Production):** `docker-compose exec app python manage.py collectstatic --noinput` komutunu çalıştırdığınızdan emin olun. Bu komut, tüm statik dosyaları Nginx\in erişebileceği tek bir klasörde toplar.
- **Çözüm 2 (Geliştirme):** `settings.py` dosyasındaki `STATIC_URL` ve `STATICFILES_DIRS` ayarlarının doğru olduğundan emin olun.

### Sorun: "DisallowedHost" hatası alıyorum.

- **Açıklama:** Erişmeye çalıştığınız alan adı, `ALLOWED_HOSTS` ayarında listelenmemiş.
- **Çözüm:** `.env` dosyasındaki `ALLOWED_HOSTS` değişkenine alan adınızı veya IP adresinizi ekleyin. Örneğin: `ALLOWED_HOSTS=localhost,127.0.0.1,habernexus.com`

---

## Celery Sorunları

### Sorun: Celery görevleri çalışmıyor, yeni haberler üretilmiyor.

- **Çözüm 1: Logları Kontrol Edin:** `docker-compose logs celery` ve `docker-compose logs celery_beat` komutları ile logları inceleyin. Hatanın nedeni genellikle loglarda yazar.
- **Çözüm 2: Redis Bağlantısı:** Celery, görev kuyruğu için Redis\e bağlanamazsa çalışmaz. Redis konteynerinin çalışır durumda olduğundan emin olun (`docker-compose ps`). `.env` dosyasındaki `REDIS_HOST` ve `REDIS_PORT` ayarlarını kontrol edin.
- **Çözüm 3: Görevdeki Hata:** Görevin kendisinde bir Python hatası olabilir. Loglarda `Traceback` olup olmadığını kontrol edin ve hatayı düzeltin.
- **Çözüm 4: Servisleri Yeniden Başlatın:** `docker-compose restart celery celery_beat` komutu ile servisleri yeniden başlatmayı deneyin.

---

## Veritabanı Sorunları

### Sorun: `FATAL: password authentication failed for user "habernexus"`

- **Açıklama:** Veritabanı şifresi yanlış.
- **Çözüm:** `.env` dosyasındaki `DB_USER`, `DB_PASSWORD` ve `DB_NAME` değişkenlerinin, PostgreSQL\de oluşturduğunuz kullanıcı bilgileriyle eşleştiğinden emin olun.

### Sorun: `relation "table_name" does not exist`

- **Açıklama:** Veritabanı tabloları oluşturulmamış veya migrate edilmemiş.
- **Çözüm:** `docker-compose exec app python manage.py migrate` komutunu çalıştırarak veritabanı şemasını en son sürüme güncelleyin.

---

## Performans Sorunları

### Sorun: Sayfalar yavaş yükleniyor.

- **Çözüm 1: Veritabanı Sorguları:** Django Debug Toolbar gibi bir araç kullanarak sayfa başına yapılan veritabanı sorgularının sayısını kontrol edin. N+1 sorgu problemi olup olmadığını araştırın. `select_related` ve `prefetch_related` kullanarak sorgu sayısını azaltın.
- **Çözüm 2: Caching:** Sık erişilen ama nadiren değişen veriler için cache kullanın. Django\nun cache framework\ünü Redis ile entegre edebilirsiniz.
- **Çözüm 3: Görsel Boyutları:** Yüksek çözünürlüklü görseller sayfa yüklenme süresini artırır. Görselleri optimize edin ve WebP gibi modern formatlar kullanın.
- **Çözüm 4: Sunucu Kaynakları:** Sunucunuzun CPU ve RAM kullanımını kontrol edin. Kaynaklar yetersiz kalıyorsa sunucuyu yükseltin (dikey ölçeklendirme) veya yeni sunucular ekleyin (yatay ölçeklendirme).
