# HaberNexus - Bilinen Hatalar ve Geçici Çözümler

**Son Güncelleme:** 18 Aralık 2025

---

Bu belge, HaberNexus projesinde bilinen mevcut hataları, durumlarını ve olası geçici çözümleri listeler. Bir hata bildirimi yapmadan veya bir hatayı düzeltmeye başlamadan önce lütfen bu listeyi kontrol edin.

## 🐞 Hata Takip Süreci

1.  **Kontrol Edin:** Bildirmek istediğiniz hatanın bu listede olup olmadığını kontrol edin.
2.  **Raporlayın:** Hata listede yoksa, GitHub Issues üzerinden `Bug Report` şablonunu kullanarak yeni bir hata bildiriminde bulunun.
3.  **Güncelleyin:** Bir hata üzerinde çalışmaya başlarsanız, bu durumu [Geliştirme Yol Haritası (DEVELOPMENT_ROADMAP.md)](DEVELOPMENT_ROADMAP.md) üzerinde belirtin.

---

## 🐛 Mevcut Hatalar

Bu bölüm, aktif olarak bilinen ve çözülmesi gereken hataları içerir.

| ID | Hata Açıklaması | Etkilenen Alan(lar) | Durum | Öncelik | Geçici Çözüm (Workaround) |
|----|-----------------|---------------------|-------|---------|----------------------------|
| #1 | **Kullanılmayan Değişkenler:** Kod tabanında tanımlanmış ancak kullanılmayan değişkenler mevcut. | `api`, `core`, `news` | **[Tespit Edildi]** 🔴 | Orta | Yok, kod temizliği gerektirir. |
| #2 | **Spesifik Olmayan Exception Handling:** `except Exception:` gibi genel exception blokları kullanılıyor. | `news`, `core` | **[Tespit Edildi]** 🔴 | Yüksek | Hata ayıklamayı zorlaştırır. Spesifik exception'lar kullanılmalı. |
| #3 | **Mutable Class Defaults:** Sınıf tanımlarında `list` veya `dict` gibi değiştirilebilir varsayılan değerler kullanılıyor. | `api/serializers.py` | **[Tespit Edildi]** 🔴 | Orta | `default_factory` veya `ClassVar` kullanılmalı. |
| #4 | **Türkçe Karakter Uyarıları:** Ruff, docstring ve yorumlardaki `ı` gibi Türkçe karakterler için uyarı veriyor. | Tüm proje | **[Göz Ardı Edilebilir]** ⚫️ | Düşük | Proje dili Türkçe olduğu için bu bir hata değildir. Ruff yapılandırmasında bu uyarılar kapatılabilir. |
| #5 | **`random.choice` Güvenlik Uyarısı:** `bandit` aracı, kriptografik olmayan `random` kullanımı için uyarı veriyor. | `news/tasks.py` | **[Göz Ardı Edilebilir]** ⚫️ | Düşük | Yazar ataması için kullanıldığından güvenlik riski taşımaz. `#nosec` ile işaretlenebilir. |

### Durum Açıklamaları

- **[Tespit Edildi]** 🔴: Hata onaylandı ve çözülmeyi bekliyor.
- **[Çalışılıyor]** 🟡: Bir geliştirici bu hata üzerinde çalışıyor.
- **[Çözüldü]** 🟢: Hata düzeltildi ve bir sonraki sürümde yayınlanacak.
- **[Göz Ardı Edilebilir]** ⚫️: Hata olarak kabul edilmiyor veya öncelik değil.

---

## 💡 Geçici Çözümler (Workarounds)

Bu bölümde, henüz çözülmemiş ancak kullanıcıları etkileyebilecek sorunlar için geçici çözümler sunulmaktadır.

- **Sorun:** Henüz listelenmiş bir geçici çözüm bulunmamaktadır.
- **Çözüm:** -

---

Bu belge, topluluk tarafından düzenli olarak güncellenmelidir. Yeni bir hata tespit ettiğinizde veya bir hatayı çözdüğünüzde lütfen bu dosyayı güncellemeyi unutmayın.
