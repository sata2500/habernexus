# Security Policy

## Supported Versions

Aşağıdaki tabloda, güvenlik güncellemeleri ile desteklenen HaberNexus sürümleri listelenmiştir:

| Version | Supported          |
| ------- | ------------------ |
| 10.x    | :white_check_mark: |
| 9.x     | :white_check_mark: |
| 8.x     | :x:                |
| < 8.0   | :x:                |

## Reporting a Vulnerability

HaberNexus projesinde bir güvenlik açığı keşfettiyseniz, lütfen aşağıdaki adımları izleyin:

### İletişim

Güvenlik açıklarını bildirmek için lütfen **salihtanriseven25@gmail.com** adresine e-posta gönderin.

### Beklentiler

- **İlk Yanıt:** 48 saat içinde
- **Durum Güncellemesi:** 7 gün içinde
- **Çözüm Süresi:** Kritik açıklar için 30 gün, diğerleri için 90 gün

### Bildirim İçeriği

Lütfen raporunuzda aşağıdaki bilgileri ekleyin:

1. Açığın detaylı açıklaması
2. Etkilenen sürümler
3. Yeniden üretme adımları
4. Potansiyel etki değerlendirmesi
5. Varsa önerilen çözüm

### Sorumlu Açıklama

- Güvenlik açıklarını kamuya açıklamadan önce bizimle iletişime geçin
- Açığı gidermemiz için makul bir süre tanıyın
- Kullanıcı verilerine veya sistemlere zarar vermeyin

## Security Best Practices

### Kurulum Güvenliği

```bash
# Güçlü secret key oluşturun
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# .env dosyasını güvenli tutun
chmod 600 .env
```

### Önerilen Yapılandırma

1. **DEBUG Mode:** Production ortamında `DEBUG=False` olmalı
2. **ALLOWED_HOSTS:** Sadece gerekli domainleri ekleyin
3. **HTTPS:** Cloudflare Tunnel veya SSL sertifikası kullanın
4. **Database:** Güçlü şifreler kullanın
5. **API Keys:** Çevre değişkenlerinde saklayın

### Güvenlik Özellikleri

HaberNexus aşağıdaki güvenlik özelliklerini içerir:

- **Cloudflare Tunnel:** Port açmadan güvenli erişim
- **SSL/TLS:** Otomatik sertifika yönetimi
- **Rate Limiting:** API isteklerini sınırlama
- **CORS:** Cross-origin güvenliği
- **CSRF Protection:** Django CSRF koruması
- **XSS Protection:** Template auto-escaping
- **SQL Injection Protection:** Django ORM

## Güvenlik Taramaları

Projede aşağıdaki güvenlik araçları kullanılmaktadır:

- **Bandit:** Python güvenlik taraması
- **Trivy:** Container güvenlik taraması
- **Dependabot:** Bağımlılık güvenlik güncellemeleri

## Changelog

Güvenlik güncellemeleri için [CHANGELOG.md](CHANGELOG.md) dosyasını inceleyin.

---

**Son Güncelleme:** Aralık 2025
