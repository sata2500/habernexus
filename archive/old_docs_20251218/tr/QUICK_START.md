# Haber Nexus - Hızlı Başlangıç

Bu rehber, Haber Nexus projesini 5 dakika içinde Docker kullanarak nasıl kuracağınızı ve çalıştıracağınızı gösterir.

---

## Gereksinimler

- **Docker:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) veya Docker Engine
- **Git:** [Git](https://git-scm.com/downloads)
- **Metin Düzenleyici:** VS Code, Sublime Text vb.

---

## Adım 1: Projeyi Klonlayın

Terminali açın ve aşağıdaki komutu çalıştırın:

```bash
git clone https://github.com/sata2500/habernexus.git
cd habernexus
```

---

## Adım 2: Ortam Değişkenlerini Ayarlayın

`.env.example` dosyasını kopyalayarak `.env` adında yeni bir dosya oluşturun:

```bash
cp .env.example .env
```

Şimdi `.env` dosyasını bir metin düzenleyici ile açın ve aşağıdaki değişkenleri doldurun:

```env
# Django için gizli anahtar (değiştirin)
SECRET_KEY=\'django-insecure-your-secret-key\'

# Google Gemini API anahtarı
GOOGLE_API_KEY=\'your-google-api-key\'

# Veritabanı ayarları (varsayılan olarak bırakılabilir)
DB_NAME=habernexus
DB_USER=habernexus
DB_PASSWORD=habernexus
DB_HOST=db
DB_PORT=5432
```

**Önemli:** `SECRET_KEY` ve `GOOGLE_API_KEY` alanlarını kendi değerlerinizle değiştirdiğinizden emin olun.

---

## Adım 3: Docker Konteynerlerini Başlatın

Proje ana dizinindeyken aşağıdaki komutu çalıştırın:

```bash
docker-compose up -d --build
```

Bu komut, gerekli imajları indirip derleyecek ve tüm servisleri (Nginx, Django, PostgreSQL, Redis, Celery) arka planda başlatacaktır.

---

## Adım 4: Veritabanını Hazırlayın ve Yönetici Oluşturun

Konteynerler başladıktan sonra, veritabanı tablolarını oluşturmak için aşağıdaki komutu çalıştırın:

```bash
docker-compose exec app python manage.py migrate
```

Ardından, Django admin paneline erişmek için bir yönetici (superuser) oluşturun:

```bash
docker-compose exec app python manage.py createsuperuser
```

Komut sizden bir kullanıcı adı, e-posta ve şifre isteyecektir.

---

## Adım 5: Projeyi Ziyaret Edin

Artık her şey hazır! Web tarayıcınızı açın ve aşağıdaki adresleri ziyaret edin:

- **Ana Sayfa:** `http://localhost`
- **Admin Paneli:** `http://localhost/admin/`

Admin paneline, az önce oluşturduğunuz yönetici bilgileriyle giriş yapabilirsiniz.

---

## Sonraki Adımlar

- **RSS Kaynakları Ekleyin:** Admin panelinden `Haberler > RSS Kaynakları` bölümüne giderek haber çekmek istediğiniz RSS beslemelerini ekleyin.
- **Ayarları Yapılandırın:** `Çekirdek > Sistem Ayarları` bölümünden AI modeli gibi ayarları yapılandırın.
- **Celery Görevlerini İzleyin:** `docker-compose logs -f celery` komutu ile arka planda çalışan görevleri izleyebilirsiniz.

Detaylı kurulum ve diğer seçenekler için **[Kurulum Rehberi](INSTALLATION.md)**'ni inceleyebilirsiniz.
