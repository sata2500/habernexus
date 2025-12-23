# HaberNexus - Bilinen Hatalar ve Geçici Çözümler

**Son Güncelleme:** 23 Aralık 2025

---

Bu belge, HaberNexus projesinde bilinen mevcut hataları, durumlarını ve olası geçici çözümleri listeler. Bir hata bildirimi yapmadan veya bir hatayı düzeltmeye başlamadan önce lütfen bu listeyi kontrol edin.

## 🐞 Hata Takip Süreci

1.  **Kontrol Edin:** Bildirmek istediğiniz hatanın bu listede olup olmadığını kontrol edin.
2.  **Raporlayın:** Hata listede yoksa, GitHub Issues üzerinden `Bug Report` şablonunu kullanarak yeni bir hata bildiriminde bulunun.
3.  **Güncelleyin:** Bir hata üzerinde çalışmaya başlarsanız, bu durumu [Geliştirme Yol Haritası (DEVELOPMENT_ROADMAP.md)](DEVELOPMENT_ROADMAP.md) üzerinde belirtin.

---

## ✅ Çözülen Hatalar (23 Aralık 2025)

Bu bölüm, son güncellemede çözülen hataları içerir.

| ID | Hata Açıklaması | Etkilenen Alan(lar) | Durum | Çözüm |
|----|-----------------|---------------------|-------|-------|
| #1 | **Kullanılmayan Değişkenler:** Kod tabanında tanımlanmış ancak kullanılmayan değişkenler mevcut. | `api`, `core`, `news` | **[Çözüldü]** 🟢 | Ruff yapılandırmasında per-file-ignores ile yönetildi. |
| #2 | **Spesifik Olmayan Exception Handling:** `except Exception:` gibi genel exception blokları kullanılıyor. | `news`, `core` | **[Çözüldü]** 🟢 | `raise ... from err` pattern'i uygulandı. |
| #3 | **Mutable Class Defaults:** Sınıf tanımlarında `list` veya `dict` gibi değiştirilebilir varsayılan değerler kullanılıyor. | `api/serializers.py` | **[Çözüldü]** 🟢 | Django/DRF pattern olduğu için Ruff'ta ignore edildi. |
| #4 | **Türkçe Karakter Uyarıları:** Ruff, docstring ve yorumlardaki `ı` gibi Türkçe karakterler için uyarı veriyor. | Tüm proje | **[Çözüldü]** 🟢 | RUF001, RUF002, RUF003 kuralları pyproject.toml'da ignore edildi. |
| #5 | **Yorum Satırına Alınmış Kodlar:** Commented-out code blokları temizlendi. | `api`, `config`, `news` | **[Çözüldü]** 🟢 | Gereksiz yorum satırları kaldırıldı veya TODO'ya dönüştürüldü. |

---

## 🐛 Mevcut Hatalar

Bu bölüm, aktif olarak bilinen ve çözülmesi gereken hataları içerir.

| ID | Hata Açıklaması | Etkilenen Alan(lar) | Durum | Öncelik | Geçici Çözüm (Workaround) |
|----|-----------------|---------------------|-------|---------|----------------------------|
| #6 | **`random.choice` Güvenlik Uyarısı:** `bandit` aracı, kriptografik olmayan `random` kullanımı için uyarı veriyor. | `news/tasks.py` | **[Göz Ardı Edilebilir]** ⚫️ | Düşük | Yazar ataması için kullanıldığından güvenlik riski taşımaz. `#nosec` ile işaretlenebilir. |
| #7 | **CI Test Hatası:** Codecov action indirme timeout'u nedeniyle CI pipeline başarısız olabiliyor. | GitHub Actions | **[Tespit Edildi]** 🔴 | Orta | Geçici ağ sorunu, workflow'u yeniden çalıştırın. |

### Durum Açıklamaları

- **[Tespit Edildi]** 🔴: Hata onaylandı ve çözülmeyi bekliyor.
- **[Çalışılıyor]** 🟡: Bir geliştirici bu hata üzerinde çalışıyor.
- **[Çözüldü]** 🟢: Hata düzeltildi ve bir sonraki sürümde yayınlanacak.
- **[Göz Ardı Edilebilir]** ⚫️: Hata olarak kabul edilmiyor veya öncelik değil.

---

## 💡 Geçici Çözümler (Workarounds)

Bu bölümde, henüz çözülmemiş ancak kullanıcıları etkileyebilecek sorunlar için geçici çözümler sunulmaktadır.

- **Sorun:** CI pipeline codecov-action timeout hatası
- **Çözüm:** GitHub Actions workflow'unu yeniden çalıştırın. Bu geçici bir ağ sorunudur.

---

Bu belge, topluluk tarafından düzenli olarak güncellenmelidir. Yeni bir hata tespit ettiğinizde veya bir hatayı çözdüğünüzde lütfen bu dosyayı güncellemeyi unutmayın.
