# HaberNexus: Akıllı Haber Agregasyon Platformu

<div align="center">

[![Versiyon](https://img.shields.io/badge/versiyon-11.0.0-blue.svg?style=for-the-badge)](https://github.com/sata2500/habernexus)
[![Lisans](https://img.shields.io/badge/lisans-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Geliştirici](https://img.shields.io/badge/geliştirici-Salih%20TANRISEVEN-orange.svg?style=for-the-badge)](https://github.com/sata2500)
[![Python](https://img.shields.io/badge/Python-3.11%2B-green?style=for-the-badge&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-5.1-green?style=for-the-badge&logo=django)](https://djangoproject.com)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?style=for-the-badge&logo=docker)](https://docker.com)

**Modern, AI-Destekli, Tam Otomatik Haber Agregasyon Platformu**

[Hızlı Kurulum](#-hızlı-başlangıç-tek-komutla-kurulum) • [Özellikler](#-temel-özellikler) • [Yönetim](#️-gelişmiş-kurulum-ve-yönetim) • [Dökümanlar](https://github.com/sata2500/habernexus/wiki)

</div>

---

**HaberNexus**, modern teknolojilerle geliştirilmiş, Django tabanlı, Docker ile güçlendirilmiş ve yapay zeka entegrasyonuna sahip bir haber agregasyon platformudur. Bu proje, haberleri otomatik olarak toplayan, kategorize eden ve kullanıcılara sunan akıllı bir sistemdir.

## ✨ Temel Özellikler

- **Otomatik Kurulum**: Tek bir komutla tüm sistemi dakikalar içinde kurun.
- **Docker Entegrasyonu**: Tüm servisler (web, veritabanı, cache) Docker container'ları olarak çalışır.
- **Profesyonel Yedekleme**: Veritabanı, medya dosyaları ve yapılandırmalar için gelişmiş yedekleme ve geri yükleme sistemi.
- **Caddy Web Sunucusu**: Otomatik HTTPS, HTTP/2, ve reverse proxy desteği.
- **Cloudflare Tunnel**: Sunucunuzu güvenli bir şekilde internete açmak için opsiyonel Cloudflare Tunnel entegrasyonu.
- **Yapay Zeka**: Google Gemini AI ile haber özetleme ve analiz yetenekleri.
- **Celery & Redis**: Asenkron görevler ve periyodik işlemler için güçlü altyapı.

## 🚀 Hızlı Başlangıç: Tek Komutla Kurulum

HaberNexus'u kurmanın en hızlı yolu aşağıdaki komutu çalıştırmaktır. Bu komut, `setup.sh` script'ini indirir ve otomatik kurulumu başlatır.

```bash
curl -fsSL https://raw.githubusercontent.com/sata2500/habernexus/main/setup.sh | sudo bash
```

Kurulum sırasında sizden domain adı, admin bilgileri gibi temel bilgiler istenecektir. Dilerseniz varsayılan değerlerle hızlıca devam edebilirsiniz.

## 🛠️ Gelişmiş Kurulum ve Yönetim

Projenin ana kurulum ve yönetim aracı `setup.sh` script'idir. Bu script, kurulumdan yedeklemeye, temizlikten geri yüklemeye kadar tüm işlemleri yönetmenizi sağlar.

### Kurulum Seçenekleri

- **Otomatik Kurulum (Etkileşimli)**:
  ```bash
  sudo bash setup.sh
  ```

- **Hızlı Kurulum (Varsayılan Değerlerle)**:
  ```bash
  sudo bash setup.sh --quick
  ```

- **Geliştirici Kurulumu**:
  ```bash
  sudo bash setup.sh --dev
  ```

- **Manuel Kurulum (Adım Adım)**:
  ```bash
  sudo bash setup.sh --manual
  ```

### Yedekleme ve Geri Yükleme

Detaylı yedekleme ve geri yükleme işlemleri için `scripts/backup.sh` script'i kullanılır. `setup.sh` üzerinden de temel komutlara erişebilirsiniz.

- **Tam Yedek Al**:
  ```bash
  sudo bash setup.sh --backup
  ```

- **Yedekleri Listele**:
  ```bash
  sudo bash setup.sh --list-backups
  ```

- **Yedekten Geri Yükle**:
  ```bash
  sudo bash setup.sh --restore <yedek_ismi>
  ```

### Temizlik ve Kaldırma

- **Kurulumu Sıfırla (Yeniden Kurulum İçin)**:
  ```bash
  sudo bash setup.sh --reset
  ```

- **HaberNexus'u Tamamen Kaldır**:
  ```bash
  sudo bash setup.sh --uninstall
  ```

### Tüm Komutlar

Tüm komutları ve seçenekleri görmek için `--help` parametresini kullanın:

```bash
bash setup.sh --help
```

## 📂 Proje Yapısı

```
.
├── caddy/                # Caddy web sunucusu yapılandırması
├── habernexus/           # Django proje dosyaları
├── scripts/              # Yönetim script'leri (yedekleme, temizlik vb.)
├── staticfiles/          # Toplanan statik dosyalar
├── mediafiles/           # Yüklenen medya dosyaları
├── .env.example          # Örnek ortam değişkenleri dosyası
├── docker-compose.prod.yml # Üretim ortamı için Docker Compose dosyası
├── Dockerfile            # Django uygulaması için Dockerfile
├── setup.sh              # Ana kurulum ve yönetim script'i
└── README.md             # Bu dosya
```

## 🔧 Manuel Kurulum Rehberi

Eğer sistemi adım adım kendiniz kurmak isterseniz, `scripts/manual-setup.sh` script'ini kullanabilirsiniz. Bu script, her adımda ne yapıldığını açıklar ve sizden onay alarak ilerler.

```bash
sudo bash scripts/manual-setup.sh
```

## 📚 Dokümantasyon

Proje hakkında daha detaylı bilgi, mimari ve geliştirici rehberleri için **[📖 GitHub Wiki](https://github.com/sata2500/habernexus/wiki)** sayfamızı ziyaret edin.

## 🤝 Katkıda Bulunma

Katkılarınız için teşekkürler! Lütfen pull request açmadan önce projenin kodlama standartlarına ve yapısına uygun hareket ettiğinizden emin olun.

## 📜 Lisans

Bu proje MIT Lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakınız.

## 👨‍💻 Geliştirici

**Salih TANRISEVEN**
- Email: salihtanriseven25@gmail.com
- GitHub: [@sata2500](https://github.com/sata2500)

---

<div align="center">

**⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!**

</div>
