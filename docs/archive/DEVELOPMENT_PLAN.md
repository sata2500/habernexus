# Haber Nexus - Geliştirme Planı ve Yol Haritası

**Tarih:** 30 Kasım 2025  
**Hazırlayan:** Manus AI

## 1. Giriş

Bu belge, "Haber Nexus" projesinin mevcut durumunu analiz ederek, modern web teknolojileri ve en iyi geliştirme pratikleri (best practices) doğrultusunda projeyi daha ileriye taşımak için hazırlanmış kapsamlı bir geliştirme planı sunmaktadır. Amacımız, uygulamanın **güvenilirliğini, performansını, güvenliğini ve sürdürülebilirliğini** en üst düzeye çıkarmaktır.

Proje, sağlam bir temel üzerine kurulmuş olup, Docker, Django ve Celery gibi güçlü teknolojileri etkin bir şekilde kullanmaktadır. Yapılan detaylı inceleme ve teknoloji araştırmaları sonucunda, projeyi daha da güçlendirecek ve gelecekteki geliştirmeler için sağlam bir zemin oluşturacak bir dizi iyileştirme alanı tespit edilmiştir.

Bu plan, talimatlarınız doğrultusunda **adım adım ilerleyecek, her bir özelliğin ayrıntılı olarak test edileceği ve profesyonel bir çalışma disipliniyle** yürütülecektir.

## 2. Mevcut Durum Analizi

### Güçlü Yönler

- **Modern Teknoloji Yığını:** Django 5, PostgreSQL, Redis ve Celery gibi güncel ve güçlü teknolojilerin kullanımı.
- **Kapsamlı Dokümantasyon:** `ARCHITECTURE.md`, `DEVELOPMENT.md` ve `DEPLOYMENT.md` dosyaları projenin anlaşılabilirliğini ve yönetilebilirliğini artırmaktadır.
- **Otomasyon Odaklı Mimari:** Celery ve Celery Beat ile RSS beslemelerinin otomatik taranması ve yapay zeka ile içerik üretimi, projenin temel vizyonunu başarıyla yansıtmaktadır.
- **Containerization:** Docker ve Docker Compose kullanımı, geliştirme ve dağıtım süreçlerini standartlaştırarak kolaylaştırmaktadır.
- **Temiz Kod Yapısı:** Proje, Django uygulama mantığına uygun olarak `core`, `news`, `authors` gibi modüllere ayrılarak iyi bir şekilde organize edilmiştir.

### Geliştirilecek Alanlar ve Potansiyel Riskler

- **Görev Kuyruğu Güvenilirliği:** Dağıtık sistemlerde (Celery), veritabanı işlemleri ve görev kuyruğuna ekleme arasında yaşanabilecek senkronizasyon sorunları, görevlerin kaybolmasına veya hatalı işlenmesine neden olabilir (`transaction.on_commit` eksikliği).
- **Performans Optimizasyonu:** Veritabanı bağlantılarının her istekte yeniden kurulması (connection pooling eksikliği) ve bazı veritabanı sorgularının optimize edilmemiş olması, yüksek trafik altında performans sorunlarına yol açabilir.
- **Frontend Yapılandırması:** Tailwind CSS'in CDN üzerinden kullanılması, üretim ortamı için performans ve özelleştirme açısından ideal değildir. Bir build sürecinin entegre edilmesi gerekmektedir.
- **İzleme (Monitoring) ve Hata Takibi:** Celery görevlerinin ve genel sistem sağlığının anlık olarak izlenmesi için `Flower` gibi araçların entegre edilmemiş olması, olası sorunların tespitini ve çözümünü zorlaştırabilir.
- **Test Kapsamı:** Otomatik testlerin (unit, integration) bulunmaması, yeni geliştirmeler sırasında mevcut fonksiyonların bozulma riskini artırmaktadır.

## 3. Önerilen Geliştirme Yol Haritası

Aşağıdaki yol haritası, projeyi daha sağlam, performanslı ve yönetilebilir hale getirmek için tasarlanmıştır. Her faz, bir öncekinin üzerine inşa edilecek ve tamamlanmadan diğerine geçilmeyecektir.

### **Faz 1: Temel Güvenilirlik ve Optimizasyon**

Bu fazın amacı, sistemin bel kemiğini oluşturan arka plan görevlerini ve veritabanı operasyonlarını **%100 güvenilir** hale getirmek ve olası veri kayıplarını önlemektir.

| Öncelik | Görev                                                              | Açıklama                                                                                                                                                                                            | Beklenen Sonuç                                                                |
|:--------:|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| **1**  | **Celery Görevlerini `transaction.on_commit` ile Güvence Altına Alma** | Veritabanı işlemi başarıyla tamamlanmadan Celery görevinin kuyruğa eklenmesini önlemek. Bu, özellikle `generate_ai_content` gibi kritik görevler için hayati önem taşır.                               | Veritabanı ve görev kuyruğu arasında tam senkronizasyon, görev kaybı riskinin ortadan kaldırılması. |
| **2**  | **PostgreSQL Connection Pooling Entegrasyonu**                       | Django 5.1+ ile gelen bağlantı havuzu özelliğini `settings.py` dosyasında aktive ederek, her istekte yeni veritabanı bağlantısı kurma maliyetini ortadan kaldırmak.                                      | Yüksek trafik altında daha düşük gecikme (latency) ve artan veritabanı performansı. |
| **3**  | **Redis `maxmemory-policy` Yapılandırması**                        | Redis'in bellek dolduğunda eski görevleri silmesini önlemek için `maxmemory-policy` ayarını `noeviction` olarak değiştirmek. Bu, görevlerin rastgele kaybolmasını engeller.                               | Broker kaynaklı görev kaybı riskinin sıfırlanması.                             |
| **4**  | **Celery Görevleri için `Idempotency` Sağlama**                      | Network sorunları veya yeniden denemeler nedeniyle bir görevin birden fazla kez çalıştırılması durumunda bile sistemin tutarlı kalmasını sağlamak (örn: bir haberin iki kez üretilmesini önlemek). | Sistemin daha dayanıklı ve öngörülebilir çalışması.                            |
| **5**  | **Gelişmiş Celery Retry Stratejileri**                              | API hataları veya geçici ağ sorunları gibi durumlarda görevlerin otomatik olarak yeniden denenmesi için `autoretry_for`, `retry_backoff` gibi parametreleri yapılandırmak.                          | Geçici hatalara karşı sistemin kendi kendini iyileştirme yeteneği kazanması.     |

### **Faz 2: Frontend Modernizasyonu ve Performans**

Bu faz, kullanıcı deneyimini doğrudan etkileyen frontend performansını ve veritabanı sorgu verimliliğini artırmaya odaklanacaktır.

| Öncelik | Görev                                                              | Açıklama                                                                                                                                                                                          | Beklenen Sonuç                                                                |
|:--------:|--------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| **1**  | **Tailwind CSS Build Sürecinin Kurulumu**                          | `django-tailwind` paketini kullanarak, Tailwind CSS'in CDN yerine proje içinde derlenip (build) optimize edilmiş tek bir CSS dosyası olarak sunulmasını sağlamak.                                    | Daha hızlı sayfa yükleme süreleri ve üretim ortamı için optimize edilmiş stil dosyaları. |
| **2**  | **Veritabanı Sorgu Optimizasyonu (`select_related`, `prefetch_related`)** | `Article` listeleme ve detay sayfaları gibi yerlerde ilişkili `Author` ve `Category` verilerini tek bir sorguda çekmek için `select_related` ve `prefetch_related` kullanmak.                         | Sayfa başına düşen veritabanı sorgu sayısının azalması ve sayfa yanıt sürelerinin iyileşmesi. |
| **3**  | **Görsel Optimizasyonu ve Lazy Loading**                             | Sayfada ilk anda görünmeyen görsellerin, kullanıcı sayfayı aşağı kaydırdıkça yüklenmesini sağlamak için `loading="lazy"` attribute'ünü `<img>` etiketlerine eklemek.                               | İlk sayfa açılış hızında (Initial Page Load) belirgin artış.                  |

### **Faz 3: İzleme, Test ve DevOps Altyapısı**

Bu faz, projenin uzun vadeli sağlığını, yönetilebilirliğini ve kalitesini güvence altına alacak altyapıyı kurmayı hedefler.

| Öncelik | Görev                                                              | Açıklama                                                                                                                                                                                          | Beklenen Sonuç                                                                |
|:--------:|--------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| **1**  | **Celery için `Flower` Monitoring Aracının Entegrasyonu**            | Celery worker'larının durumunu, tamamlanan ve başarısız olan görevleri gerçek zamanlı olarak izlemek için `Flower` web arayüzünü kurmak ve `docker-compose.yml` dosyasına eklemek.                | Arka plan görevleri üzerinde tam görünürlük ve proaktif sorun tespiti.        |
| **2**  | **Birim ve Entegrasyon Testlerinin Yazılması**                     | Kritik işlevler (örn: `fetch_single_rss`, `generate_ai_content` görevleri, `Article` modeli) için `pytest` veya Django'nun dahili test framework'ü ile otomatik testler yazmak.                   | Kod kalitesinin artması ve yeni geliştirmelerin mevcut sistemi bozmamasının garantisi. |
| **3**  | **CI/CD Pipeline Kurulumu (GitHub Actions)**                       | Her `git push` işleminde otomatik olarak testlerin çalıştırılması, kodun linting (kod stili denetimi) yapılması ve başarılı olursa bir staging ortamına otomatik olarak dağıtılması için bir iş akışı oluşturmak. | Geliştirme süreçlerinin otomatize edilmesi ve insan hatasının minimize edilmesi. |

### **Faz 4: Yeni Özellik Geliştirme**

Yukarıdaki temel iyileştirmeler tamamlandıktan sonra, proje artık yeni özelliklerin güvenli ve verimli bir şekilde eklenebileceği çok daha sağlam bir yapıya kavuşmuş olacaktır. Bu aşamada, sizinle birlikte belirleyeceğimiz yeni özellikler üzerinde çalışmaya başlayabiliriz. Olası yeni özellikler şunlar olabilir:

- **Gelişmiş Arama:** Elasticsearch entegrasyonu ile daha hızlı ve akıllı arama yetenekleri.
- **Kullanıcı Etkileşimi:** Haberlere yorum yapma, favorilere ekleme gibi özellikler.
- **Yönetim Paneli İyileştirmeleri:** Daha detaylı raporlama ve analiz ekranları.

## 4. Sonraki Adımlar

Yukarıda sunulan yol haritasını onaylamanız durumunda, **Faz 1, Öncelik 1** olan **"Celery Görevlerini `transaction.on_commit` ile Güvence Altına Alma"** adımı ile geliştirmeye başlamayı öneriyorum. Bu, sistemin en kritik zafiyetlerinden birini gidererek en yüksek faydayı sağlayacak ilk adımdır.

Lütfen planı inceleyip geri bildirimlerinizi paylaşın. Onayınızla birlikte ilk adımı atmak için hazırım.
