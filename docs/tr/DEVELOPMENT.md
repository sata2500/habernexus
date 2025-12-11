# Haber Nexus - Geliştirme Rehberi

Bu rehber, Haber Nexus projesine katkıda bulunmak isteyen geliştiriciler için kod standartlarını, iş akışlarını ve en iyi pratikleri açıklar.

---

## İçindekiler

1. [Geliştirme Ortamı](#geliştirme-ortamı)
2. [Kod Standartları ve Kalite](#kod-standartları-ve-kalite)
3. [Git İş Akışı (Git Flow)](#git-iş-akışı-git-flow)
4. [Test Yazma](#test-yazma)
5. [Commit Mesajları](#commit-mesajları)
6. [Pull Request Süreci](#pull-request-süreci)
7. [Yeni Bir Uygulama Ekleme](#yeni-bir-uygulama-ekleme)

---

## Geliştirme Ortamı

En kolay geliştirme ortamı kurulumu için **[Kurulum Rehberi](INSTALLATION.md)**\ndeki "Yerel Geliştirme Ortamı Kurulumu" bölümünü takip edin.

### Önerilen Araçlar

- **IDE:** VS Code veya PyCharm
- **VS Code Eklentileri:** Python, Django, Pylance, Black, Flake8

---

## Kod Standartları ve Kalite

Projede tutarlı ve yüksek kaliteli bir kod tabanı sağlamak için aşağıdaki araçlar ve standartlar kullanılır.

### Kod Formatlama

- **Black:** Kodun otomatik olarak formatlanması için kullanılır.
- **isort:** `import` ifadelerinin otomatik olarak sıralanması için kullanılır.

```bash
# Kodu formatla
black .
isort .
```

### Kod Analizi (Linting)

- **Flake8:** PEP 8 standartlarına uygunluğu ve potansiyel hataları denetler.

```bash
# Kodu denetle
flake8 .
```

### Type Hinting

Projede **type hinting** kullanımı teşvik edilir. Bu, kodun okunabilirliğini artırır ve `mypy` gibi araçlarla statik tip kontrolü yapılmasına olanak tanır.

```python
def get_article_by_slug(slug: str) -> Article | None:
    try:
        return Article.objects.get(slug=slug)
    except Article.DoesNotExist:
        return None
```

---

## Git İş Akışı (Git Flow)

Projede Git Flow\a benzer bir iş akışı kullanılır.

- **`main` branch:** Her zaman stabil ve production\a hazır kodu içerir.
- **`develop` branch (isteğe bağlı):** Geliştirme aşamasındaki kodu içerir. Küçük projelerde doğrudan `feature` branch\leri `main`\e birleştirilebilir.
- **`feature/` branch\leri:** Yeni özellikler bu branch\lerde geliştirilir. (Örn: `feature/add-user-comments`)
- **`bugfix/` branch\leri:** Hata düzeltmeleri bu branch\lerde yapılır. (Örn: `bugfix/fix-login-issue`)
- **`hotfix/` branch\leri:** Production\daki acil hatalar için kullanılır ve doğrudan `main`\den dallanır.

### Adımlar

1.  **Yeni bir özellik geliştirmeye başlarken:**
    ```bash
    git checkout main
    git pull origin main
    git checkout -b feature/your-feature-name
    ```

2.  **Değişiklikleri yapın ve commit edin.**

3.  **Pull request oluşturun:**
    `feature` branch\inizi `main` branch\ine birleştirmek için bir pull request açın.

---

## Test Yazma

Projede testler için Django\nun yerleşik test framework\ü ve `pytest` kullanılır. Her yeni özellik veya hata düzeltmesi için test yazılması zorunludur.

### Testleri Çalıştırma

```bash
# Tüm testleri çalıştır
python manage.py test

# Belirli bir uygulamanın testlerini çalıştır
python manage.py test news
```

### Test Kapsamı (Test Coverage)

Test kapsamını ölçmek için `coverage` paketi kullanılır.

```bash
coverage run --source=\".\" manage.py test
coverage report
```

**Hedef:** %80 ve üzeri test kapsamı.

---

## Commit Mesajları

Projede **Conventional Commits** standardı kullanılır. Bu, `CHANGELOG.md` dosyasının otomatik olarak oluşturulmasını kolaylaştırır.

**Format:** `<type>(<scope>): <subject>`

- **`feat`:** Yeni bir özellik (feature)
- **`fix`:** Bir hata düzeltmesi (bug fix)
- **`docs`:** Sadece dokümantasyon değişiklikleri
- **`style`:** Kodun anlamını etkilemeyen formatlama değişiklikleri
- **`refactor`:** Ne bir hata düzelten ne de bir özellik ekleyen kod değişikliği
- **`perf`:** Performansı artıran bir kod değişikliği
- **`test`:** Eksik testlerin eklenmesi veya mevcut testlerin düzeltilmesi

**Örnek:**

```
feat(news): Add comment functionality to articles
```

---

## Pull Request Süreci

1.  **PR Açma:** `feature` veya `bugfix` branch\inizi `main` branch\ine birleştirmek için bir PR açın.
2.  **Açıklama:** PR açıklamasında yaptığınız değişiklikleri ve nedenlerini net bir şekilde açıklayın.
3.  **Review:** En az bir başka geliştiricinin onayı gereklidir.
4.  **CI Kontrolleri:** GitHub Actions üzerindeki tüm testlerin ve kontrollerin başarıyla geçmesi gerekir.
5.  **Merge:** Onay alındıktan ve kontroller geçtikten sonra PR, `squash and merge` yöntemiyle birleştirilir.

---

## Yeni Bir Uygulama Ekleme

Projeye yeni bir Django uygulaması eklerken aşağıdaki adımları izleyin:

1.  **Uygulama oluşturun:**
    ```bash
    python manage.py startapp my_new_app
    ```

2.  **`settings.py`\e ekleyin:**
    `INSTALLED_APPS` listesine yeni uygulamanızı ekleyin.

3.  **URL\leri yapılandırın:**
    Ana `urls.py` dosyasına yeni uygulamanızın `urls.py` dosyasını `include` edin.

4.  **Modelleri, view\ları ve template\leri oluşturun.**

5.  **Testleri yazın.**
