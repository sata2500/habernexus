# HaberNexus Teknoloji Araştırma Notları
## Tarih: 18 Aralık 2025

## 1. Google Gen AI SDK Güncellemeleri

### En Son Değişiklikler (Aralık 2025)
- **Gemini 3 Flash Preview** (`gemini-3-flash-preview`) - 17 Aralık 2025'te yayınlandı
- **Gemini 3 Pro Preview** (`gemini-3-pro-preview`) - 18 Kasım 2025'te yayınlandı
- **ThinkingConfig Değişiklikleri:**
  - Gemini 2.5 serisi: `thinkingBudget` (integer) kullanır - 0: devre dışı, -1: dinamik, pozitif sayı: manuel bütçe
  - Gemini 3 serisi: `thinkingLevel` (string: "low" veya "high") kullanır
- **Yeni Özellikler:**
  - Multimodal function responses
  - Code execution with images
  - Deep Research Agent
  - Interactions API (Beta)
  - File Search API (public preview)

### Kullanımdan Kaldırılan Modeller
- `gemini-2.0-flash-thinking-exp` - 2 Aralık 2025'te kapatıldı
- `gemini-1.5-pro`, `gemini-1.5-flash`, `gemini-1.5-flash-8b` - 29 Eylül 2025'te kapatıldı

## 2. Django 5.1 Güncellemeleri

### Mevcut Sürüm: Django 5.1.15 (2 Aralık 2025)
- Python 3.10 - 3.13 desteği
- Django 6.0 yakında çıkacak (yeni özellikler: querystring template tag genişletmeleri)
- LTS sürümü: Django 4.2

### Best Practices
- Composite primary key desteği (yeni)
- Güvenlik güncellemeleri düzenli takip edilmeli

## 3. Celery 5.4+ Best Practices

### Önerilen Yapılandırma
1. **Ayrı Kuyruklar:** Kritik görevler için ayrı kuyruklar kullanın
2. **Idempotent Görevler:** Güvenli tekrar çalıştırma için
3. **Kısa Görevler:** Uzun görevleri parçalara bölün
4. **Task Routing:** Görevleri doğru kuyruklara yönlendirin
5. **Monitoring:** Flower ile izleme

### Celery 5.5.3 Mevcut (En güncel)
- Django out-of-the-box desteği
- Redis broker önerilen

## 4. GitHub Açık Kaynak Best Practices

### Dokümantasyon
- README.md - Proje vizyonu ve hızlı başlangıç
- CONTRIBUTING.md - Katkı kuralları
- CODE_OF_CONDUCT.md - Davranış kuralları
- CHANGELOG.md - Değişiklik günlüğü
- SECURITY.md - Güvenlik politikası

### Geliştirme Planı Sistemi
- GitHub Projects ile roadmap
- Issue templates ile standart raporlama
- Pull Request templates
- Milestone'lar ile sürüm planlaması
- Labels ile kategorizasyon

### İletişim
- Tüm iletişimi herkese açık tutun
- Beklentileri yazılı olarak belirtin
- Yanıt süreleri hakkında bilgi verin

## 5. Önerilen Sistem Yapısı

### Geliştirme Planı (DEVELOPMENT_ROADMAP.md)
- Dinamik güncellenen plan
- Öncelik sıralaması
- Durum takibi (Planlanan, Devam Eden, Tamamlanan)
- Katkıda bulunanlar için açık alanlar

### Katkı Kuralları (CONTRIBUTING.md)
- Kod standartları
- Commit mesaj formatı
- PR süreci
- Test gereksinimleri

### Hata Raporlama (KNOWN_ISSUES.md)
- Bilinen hatalar ve çözümleri
- Workaround'lar
- Dikkat edilmesi gerekenler

### Geliştirici Rehberi (DEVELOPER_GUIDE.md)
- Detaylı kurulum
- Mimari açıklaması
- API kullanımı
- Debug ipuçları
