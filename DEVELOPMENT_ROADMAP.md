# HaberNexus Geliştirme Yol Haritası

**Son Güncelleme:** 23 Aralık 2025

---

## 🎯 Vizyon

HaberNexus, yapay zeka destekli, tam otomatik ve ölçeklenebilir bir haber agregasyon platformu olmayı hedeflemektedir. Geliştirici dostu, güvenli ve yüksek performanslı bir sistem kurarak, haberin anlık ve kaliteli bir şekilde son kullanıcıya ulaşmasını sağlamak en temel amacımızdır.

---

## 🗺️ Yol Haritası

Bu belge, projenin mevcut durumunu, gelecek hedeflerini ve katkıda bulunma süreçlerini tanımlar. Tüm geliştiricilerin bu plana uyması ve güncellemeleri buradan takip etmesi beklenmektedir.

### 🚦 Durumlar

- **[PLANNED]** 🔵 - Planlandı, henüz başlanmadı.
- **[IN PROGRESS]** 🟡 - Geliştirme devam ediyor.
- **[COMPLETED]** 🟢 - Tamamlandı ve test edildi.
- **[ON HOLD]** ⚪️ - Beklemede, geçici olarak durduruldu.
- **[NEEDS DISCUSSION]** 🟣 - Tartışılması gerekiyor.

---

## ✅ Tamamlanan Görevler (Aralık 2025)

Bu bölüm, tamamlanan kod kalitesi iyileştirmelerini içerir.

| ID | Görev | Durum | Atanan | Tamamlanma Tarihi |
|----|-------|-------|--------|-------------------|
| #1 | **Kod Temizliği:** Kullanılmayan değişkenleri ve argümanları temizle | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |
| #2 | **Exception Handling:** `raise ... from err` pattern'i uygula | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |
| #3 | **Mutable Class Defaults:** Ruff yapılandırmasında ignore edildi (Django pattern) | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |
| #4 | **Yorum Satırları:** Yorum satırına alınmış kodları kaldır | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |
| #5 | **Import Düzeni:** `ruff format` ile kod formatlandı | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |
| #6 | **Ruff Yapılandırması:** Türkçe karakter uyarıları ve Django pattern'leri için ignore kuralları eklendi | **[COMPLETED]** 🟢 | Manus AI | 23 Aralık 2025 |

---

## 🚀 Gelecek Hedefler (1. Çeyrek 2026)

Bu bölüm, projeye eklenecek yeni özellikleri ve yapılacak büyük iyileştirmeleri içerir.

| ID | Görev | Açıklama | Durum | Öncelik |
|----|-------|-----------|-------|---------|
| #7 | **Gelişmiş İçerik Analizi:** Gemini 3 Pro ile daha derin metin analizi ve özetleme | **[PLANNED]** 🔵 | Yüksek |
| #8 | **Multimodal İçerik:** Haberlere AI tarafından üretilmiş görseller ekleme (Imagen 4) | **[PLANNED]** 🔵 | Yüksek |
| #9 | **Gelişmiş Arama:** Elasticsearch yeteneklerini genişlet (filtreleme, sıralama) | **[PLANNED]** 🔵 | Orta |
| #10 | **Kullanıcı Profilleri:** Kullanıcıların ilgi alanlarına göre haber akışı | **[PLANNED]** 🔵 | Orta |
| #11 | **Test Kapsamını Artırma:** Test coverage'ı %80'in üzerine çıkarma | **[PLANNED]** 🔵 | Düşük |
| #12 | **pathlib Geçişi:** `os.path` yerine `pathlib` kütüphanesini kullanma | **[PLANNED]** 🔵 | Düşük |

---

## 💡 Fikirler ve Bekleyenler (Backlog)

Bu bölümde, henüz önceliklendirilmemiş ancak gelecekte değerlendirilebilecek fikirler yer almaktadır.

| ID | Fikir | Açıklama | Durum |
|----|-------|-----------|-------|
| #13 | **Video Haber Desteği:** YouTube gibi platformlardan video haberleri çekme | **[NEEDS DISCUSSION]** 🟣 |
| #14 | **Mobil Uygulama:** React Native ile mobil uygulama geliştirme | **[NEEDS DISCUSSION]** 🟣 |
| #15 | **Sosyal Medya Entegrasyonu:** Haberleri otomatik olarak sosyal medyada paylaşma | **[NEEDS DISCUSSION]** 🟣 |
| #16 | **Kişiselleştirilmiş Newsletter:** Kullanıcı ilgi alanlarına göre bülten gönderme | **[NEEDS DISCUSSION]** 🟣 |

---

## 🤝 Nasıl Katkıda Bulunulur?

1. **Bir Görev Seçin:** Yukarıdaki tablolardan `[PLANNED]` durumunda bir görev seçin.
2. **Kendinize Atayın:** Görevin `Atanan` sütununa GitHub kullanıcı adınızı ekleyerek bir Pull Request (PR) açın.
3. **Geliştirmeye Başlayın:** `CONTRIBUTING.md` dosyasındaki kurallara uyarak geliştirmeyi yapın.
4. **Durumu Güncelleyin:** PR açtığınızda görevin durumunu `[IN PROGRESS]` 🟡 olarak güncelleyin.
5. **Tamamlandığında:** PR'ınız merge edildiğinde görevin durumunu `[COMPLETED]** 🟢 olarak güncelleyin.

Herhangi bir konuda tartışma başlatmak için bir issue açabilir veya `[NEEDS DISCUSSION]` 🟣 olarak işaretlenmiş bir görevi tartışmaya başlayabilirsiniz.
