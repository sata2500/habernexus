_Bu dosya, Manus AI tarafından proje analizine dayalı olarak yeniden düzenlenmiştir._

# HaberNexus'a Katkıda Bulunma Rehberi

**Son Güncelleme:** 18 Aralık 2025

---

Öncelikle, HaberNexus projesine katkıda bulunmak için zaman ayırdığınız için teşekkür ederiz! Bu topluluk, sizin gibi geliştiricilerin desteğiyle büyüyor.

Bu belge, projeye sağlıklı ve verimli katkılar sağlamak için bir dizi kural ve yönerge içerir. Lütfen bu yönergeleri dikkatlice okuyun.

## 🤝 Davranış Kuralları (Code of Conduct)

Bu projeye katılan herkesin [Davranış Kuralları](CODE_OF_CONDUCT.md) belgesine uyması beklenir. Lütfen tüm katılımcılara karşı saygılı ve yapıcı bir dil kullanın.

---

## 🚀 Nasıl Katkıda Bulunabilirim?

Katkıda bulunmanın birçok yolu vardır:

- **Hata Bildirimi:** Karşılaştığınız hataları bildirmek.
- **Özellik Talebi:** Yeni özellikler önermek.
- **Kod Katkısı:** Hataları düzeltmek veya yeni özellikler geliştirmek.
- **Dokümantasyon:** Dokümanları iyileştirmek veya yeni rehberler yazmak.

### 🗺️ Geliştirme Süreci

Tüm geliştirme süreci, [Geliştirme Yol Haritası (DEVELOPMENT_ROADMAP.md)](DEVELOPMENT_ROADMAP.md) üzerinden yönetilmektedir. Katkıda bulunmak için lütfen aşağıdaki adımları izleyin:

1.  **Bir Görev Seçin:** Yol haritasındaki `[PLANNED]` 🔵 durumundaki görevlerden birini seçin.
2.  **Görevi Üstlenin:** Seçtiğiniz görevin `Atanan` bölümüne kendi GitHub kullanıcı adınızı eklemek için bir Pull Request (PR) açın. Bu PR sadece `DEVELOPMENT_ROADMAP.md` dosyasını değiştirmelidir.
3.  **Onay Bekleyin:** Proje yöneticisi, görevi size atadığında PR'ınızı onaylayacak ve birleştirecektir.
4.  **Geliştirmeye Başlayın:** Görev size atandıktan sonra, geliştirmeye başlayabilirsiniz.

---

## 💻 Geliştirme Akışı

### 1. Projeyi Fork'layın ve Klonlayın

```bash
# Projeyi kendi hesabınıza fork'layın
# Ardından fork'ladığınız repoyu klonlayın
git clone https://github.com/YOUR_USERNAME/habernexus.git
cd habernexus

# Ana repoyu "upstream" olarak ekleyin
git remote add upstream https://github.com/sata2500/habernexus.git
```

### 2. Geliştirme Dalı (Branch) Oluşturun

Her zaman `main` dalından yeni bir dal oluşturun.

```bash
# Ana dalı güncelleyin
git checkout main
git pull upstream main

# Yeni bir dal oluşturun (görev ID'si ile)
git checkout -b feat/6-advanced-content-analysis
# veya hata düzeltmesi için
git checkout -b fix/2-specific-exception-handling
```

**Dal İsimlendirme Kuralları:**

- **Özellik:** `feat/<görev-id>-<kısa-açıklama>`
- **Hata Düzeltme:** `fix/<görev-id>-<kısa-açıklama>`
- **Dokümantasyon:** `docs/<görev-id>-<kısa-açıklama>`
- **Refactor:** `refactor/<görev-id>-<kısa-açıklama>`

### 3. Değişiklikleri Yapın ve Test Edin

Kodunuzu yazarken [Kodlama Standartları](#-kodlama-standartları) bölümüne uyun.

```bash
# Kod kalitesini kontrol edin
ruff check .

# Kod formatını düzeltin
ruff format .

# Testleri çalıştırın
pytest
```

### 4. Commit ve Push

Commit mesajlarınızın [Commit Mesaj Formatı](#-commit-mesaj-formatı) bölümüne uygun olduğundan emin olun.

```bash
git add .
git commit -m "feat(#6): Add advanced content analysis with Gemini 3"
git push origin feat/6-advanced-content-analysis
```

### 5. Pull Request (PR) Oluşturun

GitHub üzerinden `main` dalına bir Pull Request açın. PR şablonunu eksiksiz doldurun. PR'ınız, en az bir proje yöneticisi tarafından incelenip onaylandıktan sonra birleştirilecektir.

---

## ✍️ Kodlama Standartları

- **Formatlama:** `ruff format` ile otomatik formatlama.
- **Linting:** `ruff check` ile kod kalitesi kontrolü.
- **Stil:** PEP 8 standartlarına uyun.
- **Type Hinting:** Tüm fonksiyon ve metodlar için type hint ekleyin.
- **Docstrings:** Tüm public modül, sınıf ve fonksiyonlar için açıklayıcı docstring yazın.

---

## 💬 Commit Mesaj Formatı

Proje, [Conventional Commits](https://www.conventionalcommits.org/) standardını kullanır.

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

- **Type:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Scope:** Değişikliğin etki ettiği alan (örn: `api`, `news`, `celery`)
- **Subject:** Değişikliği özetleyen kısa bir başlık.

**Örnek:**

```
git commit -m "feat(api): Add rate limiting to news endpoints"
```

---

## 🐞 Hata Bildirimi ve Bilinen Hatalar

- **Hata Bildirimi:** Yeni bir hata bildirmek için lütfen GitHub Issues'daki `Bug Report` şablonunu kullanın.
- **Bilinen Hatalar:** Geliştirmeye başlamadan önce [Bilinen Hatalar (KNOWN_ISSUES.md)](KNOWN_ISSUES.md) dosyasını kontrol ederek mevcut sorunlar hakkında bilgi edinin.

---

## 📚 Geliştirici Rehberi

Daha detaylı teknik bilgi, mimari ve kurulum adımları için [Geliştirici Rehberi (DEVELOPER_GUIDE.md)](DEVELOPER_GUIDE.md) belgesini inceleyin.
