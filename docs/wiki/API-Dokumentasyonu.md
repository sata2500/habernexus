## HaberNexus REST API Dokümantasyonu

HaberNexus, projenin tüm özelliklerine programatik olarak erişim sağlayan kapsamlı bir REST API sunar. Bu doküman, API'nin nasıl kullanılacağını, endpoint'leri ve veri modellerini açıklar.

---

### API Erişimi ve Dokümantasyon

API'nin interaktif dokümantasyonuna aşağıdaki adreslerden ulaşabilirsiniz:

-   **Swagger UI:** `/api/docs/`
-   **ReDoc:** `/api/redoc/`

Bu arayüzler üzerinden tüm endpoint'leri test edebilir ve şemaları inceleyebilirsiniz.

### Temel URL

Tüm API istekleri aşağıdaki temel URL üzerinden yapılır:

`https://habernexus.com/api/v1/`

### Kimlik Doğrulama (Authentication)

API, herkese açık (public) ve yönetici (admin) yetkisi gerektiren endpoint'ler içerir. Yönetici endpoint'leri için `IsAdminUser` yetkisi gereklidir ve bu, Django admin paneli üzerinden oluşturulan kullanıcılar ile sağlanır. Gelecekte JWT tabanlı bir kimlik doğrulama sistemi eklenmesi planlanmaktadır.

---

## Kullanım Örnekleri

Aşağıda, API'nin nasıl kullanılacağına dair `cURL` ve `Python` örnekleri bulunmaktadır.

### Örnek 1: Tüm Haberleri Listeleme

**cURL:**
```bash
curl -X GET https://habernexus.com/api/v1/articles/
```

**Python (`requests` kütüphanesi):**
```python
import requests

response = requests.get('https://habernexus.com/api/v1/articles/')

if response.status_code == 200:
    data = response.json()
    for article in data['results']:
        print(article['title'])
else:
    print(f"Hata: {response.status_code}")
```

### Örnek 2: Tek Bir Haberin Detayını Getirme

**cURL:**
```bash
curl -X GET https://habernexus.com/api/v1/articles/yapay-zeka-sanati-yeniden-sekillendiriyor/
```

**Python:**
```python
import requests

slug = 'yapay-zeka-sanati-yeniden-sekillendiriyor'
response = requests.get(f'https://habernexus.com/api/v1/articles/{slug}/')

if response.status_code == 200:
    article_details = response.json()
    print(article_details['content'])
```

### Örnek 3: Haberler İçinde Arama Yapma

**cURL:**
```bash
curl -X GET "https://habernexus.com/api/v1/articles/search/?q=teknoloji"
```

**Python:**
```python
import requests

params = {
    'q': 'teknoloji'
}

response = requests.get('https://habernexus.com/api/v1/articles/search/', params=params)

if response.status_code == 200:
    search_results = response.json()
    print(f"{len(search_results['results'])} sonuç bulundu.")
```

---

## Ana Endpoints

### Haberler (Articles)

-   **Endpoint:** `/articles/`
-   **Metotlar:** `GET`
-   **Açıklama:** Yayınlanmış tüm haberleri listeler. Sayfalama (pagination) destekler.

#### Haber Detayı

-   **Endpoint:** `/articles/{slug}/`
-   **Metot:** `GET`
-   **Açıklama:** Belirtilen `slug`'a sahip tek bir haberin detaylarını getirir.

#### Haber Arama

-   **Endpoint:** `/articles/search/`
-   **Metot:** `GET`
-   **Parametreler:**
    -   `q` (zorunlu): Aranacak metin (en az 2 karakter).
-   **Açıklama:** Haber başlığı, içeriği ve etiketleri içinde arama yapar.

### Yazarlar (Authors)

-   **Endpoint:** `/authors/`
-   **Metotlar:** `GET`
-   **Açıklama:** Tüm aktif yazarları listeler.

#### Yazar Detayı

-   **Endpoint:** `/authors/{slug}/`
-   **Metot:** `GET`
-   **Açıklama:** Belirtilen `slug`'a sahip yazarın bilgilerini getirir.

#### Yazarın Haberleri

-   **Endpoint:** `/authors/{slug}/articles/`
-   **Metot:** `GET`
-   **Açıklama:** Belirtilen yazara ait tüm haberleri listeler.

### Kategoriler (Categories)

-   **Endpoint:** `/categories/`
-   **Metot:** `GET`
-   **Açıklama:** Tüm kategorileri ve her kategorideki haber sayılarını listeler.

### İstatistikler (Stats)

-   **Endpoint:** `/stats/`
-   **Metot:** `GET`
-   **Açıklama:** Site ile ilgili genel istatistikleri (toplam haber, görüntülenme, yazar sayısı vb.) döndürür.

### RSS Kaynakları (RSS Sources) - *Admin Yetkisi Gerekir*

-   **Endpoint:** `/rss-sources/`
-   **Metotlar:** `GET`, `POST`, `PUT`, `PATCH`, `DELETE`
-   **Açıklama:** RSS kaynaklarını yönetmek için kullanılır. Sadece yöneticiler erişebilir.

### Sağlık Kontrolü (Health Check)

-   **Endpoint:** `/health/`
-   **Metot:** `GET`
-   **Açıklama:** API'nin ve sistemin sağlıklı çalışıp çalışmadığını kontrol etmek için kullanılır.

---

## Veri Modelleri (Serializers)

### ArticleListSerializer (Haber Listesi)

```json
{
  "url": "string",
  "title": "string",
  "slug": "string",
  "excerpt": "string",
  "featured_image": "string (URL)",
  "category": "string",
  "tags": "string",
  "author": {
    "name": "string",
    "slug": "string"
  },
  "published_at": "datetime"
}
```

### ArticleDetailSerializer (Haber Detayı)

`ArticleListSerializer` alanlarına ek olarak:

```json
{
  "content": "string (HTML)",
  "views_count": "integer",
  "is_ai_generated": "boolean"
}
```

### AuthorSerializer (Yazar)

```json
{
  "name": "string",
  "slug": "string",
  "bio": "string",
  "avatar": "string (URL)",
  "expertise": "string"
}
```
```
