# HaberNexus Geliştirme Yol Haritası

**Son Güncelleme:** 18 Aralık 2025

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

##  приоритет Anlık Öncelikler (Aralık 2025)

Bu bölüm, projenin sağlığı ve kalitesini artırmak için acil olarak ele alınması gereken görevleri içerir.

| ID | Görev | Durum | Atanan | Öncelik |
|----|-------|-------|--------|---------|
| #1 | **Kod Temizliği:** Kullanılmayan değişkenleri ve argümanları temizle | **[PLANNED]** 🔵 | - | Yüksek |
| #2 | **Exception Handling:** `except Exception` yerine daha spesifik exception'lar kullan | **[PLANNED]** 🔵 | - | Yüksek |
| #3 | **Mutable Class Defaults:** `ClassVar` kullanarak düzelt | **[PLANNED]** 🔵 | - | Orta |
| #4 | **Yorum Satırları:** Yorum satırına alınmış kodları kaldır | **[PLANNED]** 🔵 | - | Düşük |
| #5 | **Import Düzeni:** `ruff` ile import sıralamasını düzelt | **[PLANNED]** 🔵 | - | Düşük |

---

## 🚀 Gelecek Hedefler (1. Çeyrek 2026)

Bu bölüm, projeye eklenecek yeni özellikleri ve yapılacak büyük iyileştirmeleri içerir.

| ID | Görev | Açıklama | Durum | Öncelik |
|----|-------|-----------|-------|---------|
| #6 | **Gelişmiş İçerik Analizi:** Gemini 3 Pro ile daha derin metin analizi ve özetleme | **[PLANNED]** 🔵 | Yüksek |
| #7 | **Multimodal İçerik:** Haberlere AI tarafından üretilmiş görseller ekleme (Imagen 4) | **[PLANNED]** 🔵 | Yüksek |
| #8 | **Gelişmiş Arama:** Elasticsearch yeteneklerini genişlet (filtreleme, sıralama) | **[PLANNED]** 🔵 | Orta |
| #9 | **Kullanıcı Profilleri:** Kullanıcıların ilgi alanlarına göre haber akışı | **[PLANNED]** 🔵 | Orta |
| #10 | **Test Kapsamını Artırma:** Test coverage'ı %80'in üzerine çıkarma | **[PLANNED]** 🔵 | Düşük |
| #11 | **pathlib Geçişi:** `os.path` yerine `pathlib` kütüphanesini kullanma | **[PLANNED]** 🔵 | Düşük |

---

## 💡 Fikirler ve Bekleyenler (Backlog)

Bu bölümde, henüz önceliklendirilmemiş ancak gelecekte değerlendirilebilecek fikirler yer almaktadır.

| ID | Fikir | Açıklama | Durum |
|----|-------|-----------|-------|
| #12 | **Video Haber Desteği:** YouTube gibi platformlardan video haberleri çekme | **[NEEDS DISCUSSION]** 🟣 |
| #13 | **Mobil Uygulama:** React Native ile mobil uygulama geliştirme | **[NEEDS DISCUSSION]** 🟣 |
| #14 | **Sosyal Medya Entegrasyonu:** Haberleri otomatik olarak sosyal medyada paylaşma | **[NEEDS DISCUSSION]** 🟣 |
| #15 | **Kişiselleştirilmiş Newsletter:** Kullanıcı ilgi alanlarına göre bülten gönderme | **[NEEDS DISCUSSION]** 🟣 |

---

## 🤝 Nasıl Katkıda Bulunulur?

1. **Bir Görev Seçin:** Yukarıdaki tablolardan `[PLANNED]` durumunda bir görev seçin.
2. **Kendinize Atayın:** Görevin `Atanan` sütununa GitHub kullanıcı adınızı ekleyerek bir Pull Request (PR) açın.
3. **Geliştirmeye Başlayın:** `CONTRIBUTING.md` dosyasındaki kurallara uyarak geliştirmeyi yapın.
4. **Durumu Güncelleyin:** PR açtığınızda görevin durumunu `[IN PROGRESS]` 🟡 olarak güncelleyin.
5. **Tamamlandığında:** PR'ınız merge edildiğinde görevin durumunu `[COMPLETED]` 🟢 olarak güncelleyin.

Herhangi bir konuda tartışma başlatmak için bir issue açabilir veya `[NEEDS DISCUSSION]` 🟣 olarak işaretlenmiş bir görevi tartışmaya başlayabilirsiniz.
