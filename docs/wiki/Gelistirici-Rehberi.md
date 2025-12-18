## HaberNexus Geliştirici Rehberi

Bu rehber, HaberNexus projesine katkıda bulunmak isteyen geliştiriciler için hazırlanmıştır. Kodlama standartları, test süreçleri, commit mesaj formatları ve Pull Request (PR) süreci hakkında bilmeniz gereken her şeyi içerir.

Projeye yapacağınız her katkı değerlidir. Başlamadan önce bu rehberi ve projenin ana dizinindeki `CONTRIBUTING.md` dosyasını dikkatlice okumanızı rica ederiz.

---

### 🚀 Başlarken

1.  **Projeyi Fork'layın:** Kendi GitHub hesabınıza projenin bir kopyasını oluşturun.
2.  **Klonlayın:** Fork'ladığınız repoyu yerel makinenize klonlayın.
    ```bash
    git clone https://github.com/KULLANICI_ADINIZ/habernexus.git
    ```
3.  **Geliştirme Ortamını Kurun:** **[Kurulum Rehberi](Kurulum-Rehberi)**'ndeki adımları izleyerek yerel geliştirme ortamınızı hazırlayın.

### 🌿 Dal (Branch) Yönetimi

Tüm geliştirmeler `main` dalından oluşturulan yeni dallar üzerinde yapılmalıdır. Doğrudan `main` dalına commit atılmasına izin verilmemektedir.

-   **Yeni Özellikler İçin:**
    ```bash
    git checkout -b feature/yeni-ozellik-adi
    ```
-   **Hata Düzeltmeleri İçin:**
    ```bash
    git checkout -b fix/giderilen-hata-adi
    ```
-   **Dokümantasyon Değişiklikleri İçin:**
    ```bash
    git checkout -b docs/guncellenen-belge-adi
    ```

### ✍️ Kodlama Standartları

Projede tutarlı ve okunabilir bir kod tabanı sağlamak için aşağıdaki standartlara uyulması zorunludur.

-   **Kod Formatlama:** Tüm Python kodları `black` ile formatlanmalıdır.
-   **Import Sıralaması:** Import'lar `isort` ile otomatik olarak sıralanmalıdır.
-   **Kod Kalitesi:** `ruff` aracı, kod kalitesini ve stilini denetlemek için kullanılır. Commit atmadan önce `ruff .` komutunu çalıştırarak herhangi bir hata veya uyarı olup olmadığını kontrol edin.
-   **Type Hinting:** Mümkün olan her yerde (fonksiyon parametreleri, dönüş değerleri) Python'un type hint'leri kullanılmalıdır. Bu, kodun daha anlaşılır ve sürdürülebilir olmasını sağlar.
-   **Docstrings:** Tüm modüller, sınıflar ve fonksiyonlar için açıklayıcı docstring'ler yazılmalıdır. Google stilinde docstring formatı tercih edilmektedir.

### ✅ Test Süreçleri

Eklenen her yeni özelliğin veya yapılan her hata düzeltmesinin testlerle doğrulanması gerekmektedir.

-   **Testleri Çalıştırma:**
    ```bash
    pytest
    ```
-   **Test Kapsamını (Coverage) Kontrol Etme:**
    ```bash
    pytest --cov=.
    ```
    Yapılan değişikliklerin test kapsamını düşürmediğinden emin olun. Yeni kodlar için mutlaka birim (unit) veya entegrasyon (integration) testleri yazılmalıdır.

### 💬 Commit Mesaj Formatı

Projede **Conventional Commits** standardı kullanılmaktadır. Bu, `CHANGELOG.md` dosyasının otomatik olarak oluşturulmasını ve değişikliklerin daha kolay takip edilmesini sağlar.

**Format:** `<tür>(<kapsam>): <açıklama>`

-   **Türler:**
    -   `feat`: Yeni bir özellik eklendiğinde.
    -   `fix`: Bir hata düzeltildiğinde.
    -   `docs`: Sadece dokümantasyonda değişiklik yapıldığında.
    -   `style`: Kodun anlamını etkilemeyen formatlama değişiklikleri (boşluk, noktalama vb.).
    -   `refactor`: Kodun işlevselliğini değiştirmeyen, yeniden yapılandırma çalışmaları.
    -   `test`: Eksik testlerin eklenmesi veya mevcut testlerin düzeltilmesi.
    -   `chore`: Bağımlılıkların güncellenmesi, CI/CD yapılandırması gibi geliştirme sürecini etkileyen değişiklikler.

-   **Örnek Commit Mesajları:**
    ```
    feat(api): Add search functionality to articles endpoint
    fix(news): Correctly handle timezone conversion for published_at field
    docs(readme): Update installation instructions
    ```

### 🔄 Pull Request (PR) Süreci

1.  Değişikliklerinizi tamamladıktan ve commit'ledikten sonra, dalınızı kendi forkladığınız repoya push'layın:
    ```bash
    git push origin feature/yeni-ozellik-adi
    ```
2.  GitHub üzerinden `sata2500/habernexus` reposunun `main` dalına bir Pull Request açın.
3.  PR açıklamasında yaptığınız değişiklikleri detaylı bir şekilde açıklayın. İlgili issue numarası varsa (`Closes #123` gibi) belirtin.
4.  PR'ınız otomatik olarak CI/CD pipeline'ını tetikleyecektir. Testlerin ve kod kalitesi kontrollerinin başarıyla geçtiğinden emin olun.
5.  Proje yöneticileri tarafından yapılacak incelemeyi bekleyin. Geri bildirim olursa gerekli düzeltmeleri yapın.
6.  PR'ınız onaylandıktan sonra `main` dalı ile birleştirilecektir.
