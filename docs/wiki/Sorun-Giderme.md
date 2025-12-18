## HaberNexus Sorun Giderme Rehberi

Bu rehber, HaberNexus kurulumu ve kullanımı sırasında karşılaşılabilecek yaygın sorunları ve bunların çözüm yollarını içerir.

---

### Kurulum Sorunları

#### Sorun: `get-habernexus.sh` betiği hata veriyor.

-   **Çözüm 1: Yetki Kontrolü**
    Betiğin `sudo` yetkileriyle çalıştırıldığından emin olun:
    ```bash
    curl ... | sudo bash
    ```

-   **Çözüm 2: Bağımlılıklar**
    Sisteminizde `curl`, `git` gibi temel paketlerin kurulu olduğundan emin olun. Betik bunların çoğunu kurmaya çalışır, ancak eksiklikler sorun yaratabilir.

-   **Çözüm 3: Logları İnceleme**
    Kurulum sırasında oluşan loglar genellikle `/tmp/habernexus_install.log` dosyasına kaydedilir. Bu dosyayı inceleyerek hatanın kaynağını tespit edebilirsiniz.

#### Sorun: Docker Compose başlatılırken "port is already allocated" hatası.

-   **Açıklama:** Bu hata, `80` veya `443` gibi portların başka bir servis (örneğin Apache, Nginx) tarafından kullanıldığı anlamına gelir.
-   **Çözüm:** Portu kullanan servisi durdurun veya kaldırın.
    ```bash
    # Portu hangi servisin kullandığını bulma
    sudo lsof -i :80
    sudo lsof -i :443

    # Örnek: Apache'yi durdurma
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    ```

### Uygulama Çalışma Sorunları

#### Sorun: Site açılmıyor, "502 Bad Gateway" hatası alıyorum.

-   **Açıklama:** Bu genellikle Caddy reverse proxy'nin arkadaki Django uygulamasına (app servisi) ulaşamadığı anlamına gelir.

-   **Çözüm 1: Servislerin Durumunu Kontrol Edin**
    Tüm Docker konteynerlerinin çalışır durumda olduğundan emin olun.
    ```bash
    docker compose ps
    ```
    Eğer `app`, `postgres` veya `redis` servislerinden biri `running` durumunda değilse, loglarını inceleyin:
    ```bash
    docker compose logs app
    ```

-   **Çözüm 2: Veritabanı Bağlantısı**
    `app` servisinin loglarında veritabanı bağlantı hatası olup olmadığını kontrol edin. `.env` dosyasındaki `DB_` ile başlayan değişkenlerin doğru yapılandırıldığından emin olun.

-   **Çözüm 3: Migration'ları Çalıştırın**
    Veritabanı şeması güncel olmayabilir. Migration'ları manuel olarak çalıştırın:
    ```bash
    docker compose exec app python manage.py migrate
    ```

#### Sorun: Haberler güncellenmiyor, yeni içerik gelmiyor.

-   **Açıklama:** Bu sorun genellikle Celery servislerinin (worker veya beat) düzgün çalışmamasından kaynaklanır.

-   **Çözüm 1: Celery Servislerini Kontrol Edin**
    `celery` ve `celery-beat` konteynerlerinin çalışıp çalışmadığını kontrol edin.
    ```bash
    docker compose ps
    ```

-   **Çözüm 2: Celery Loglarını İnceleyin**
    Servislerin loglarında hata olup olmadığını kontrol edin. Özellikle Redis bağlantı hataları yaygındır.
    ```bash
    docker compose logs celery
    docker compose logs celery-beat
    ```

-   **Çözüm 3: RSS Kaynaklarını Kontrol Edin**
    Django admin panelinden **Haberler > RSS Kaynakları** bölümüne gidin. Kaynakların `aktif` olduğundan ve URL'lerinin doğru olduğundan emin olun.

### Geliştirme Sorunları

#### Sorun: `pytest` çalıştırıldığında veritabanı hataları alıyorum.

-   **Açıklama:** Testler için ayrı bir test veritabanı oluşturulur. Bazen yetki sorunları veya yapılandırma eksiklikleri bu hataya neden olabilir.
-   **Çözüm:** `.env` dosyanızda test veritabanı için özel bir yapılandırma olup olmadığını kontrol edin. Genellikle, ana veritabanı kullanıcısının yeni veritabanları oluşturma yetkisine sahip olması gerekir.

#### Sorun: Statik dosyalar (CSS, JS) yüklenmiyor veya güncellenmiyor.

-   **Çözüm 1: `collectstatic` Komutunu Çalıştırın**
    Django'nun statik dosyaları tek bir dizinde toplaması gerekir.
    ```bash
    docker compose exec app python manage.py collectstatic --noinput
    ```

-   **Çözüm 2: Tarayıcı Önbelleğini Temizleyin**
    Tarayıcınız eski dosyaları önbellekten yüklüyor olabilir. Sayfayı `Ctrl + Shift + R` (veya `Cmd + Shift + R`) ile yenileyerek önbelleği atlayın.

-   **Çözüm 3: Tailwind CSS Derlemesi**
    Eğer `tailwind.config.js` dosyasında veya `css` dosyalarında değişiklik yaptıysanız, Tailwind'in CSS'i yeniden derlemesi gerekir. Geliştirme ortamında bu genellikle otomatiktir, ancak sorun yaşarsanız aşağıdaki komutu çalıştırabilirsiniz:
    ```bash
    docker compose exec app python manage.py tailwind build
    ```
