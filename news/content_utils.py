"""
HaberNexus - İçerik Üretim Utility Fonksiyonları (v2.0)
Sınıflandırma, yazı stili seçimi, prompt üretimi, kalite kontrol
"""

import logging
from datetime import timedelta
from difflib import SequenceMatcher

from django.utils import timezone

import feedparser
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)


# ============================================================================
# DUPLICATE DETECTION
# ============================================================================


class DuplicateDetector:
    """
    Benzer başlıkları ve içerikleri tespit et
    """

    def __init__(self, similarity_threshold: float = 0.85):
        self.similarity_threshold = similarity_threshold

    @staticmethod
    def is_duplicate_headline(title1: str, title2: str, threshold: float = 0.85) -> bool:
        """
        İki başlığın benzer olup olmadığını kontrol et
        """
        t1 = title1.lower().strip()
        t2 = title2.lower().strip()

        ratio = SequenceMatcher(None, t1, t2).ratio()
        return ratio > threshold

    @classmethod
    def find_similar_articles(cls, title: str, category: str, days: int = 7, threshold: float = 0.85) -> list:
        """
        Benzer makaleleri bul
        """
        from news.models import Article

        similar_articles = []
        recent_articles = Article.objects.filter(
            category=category, created_at__gte=timezone.now() - timedelta(days=days), status__in=["published", "draft"]
        )

        for article in recent_articles:
            if cls.is_duplicate_headline(title, article.title, threshold):
                similar_articles.append(article)

        return similar_articles


# ============================================================================
# KALITE PUANLAMA
# ============================================================================


class ContentQualityScorer:
    """
    Başlık ve içerik kalitesini puan ver
    """

    QUALITY_WEIGHTS = {"length": 0.15, "sentiment": 0.20, "keywords": 0.25, "clickability": 0.20, "uniqueness": 0.20}

    @staticmethod
    def score_headline(headline: str, category: str = None) -> float:
        """
        Başlığı 0-100 arasında puan ver
        """
        scores = {
            "length": ContentQualityScorer._score_length(headline),
            "sentiment": ContentQualityScorer._score_sentiment(headline),
            "keywords": ContentQualityScorer._score_keywords(headline),
            "clickability": ContentQualityScorer._score_clickability(headline),
            "uniqueness": ContentQualityScorer._score_uniqueness(headline, category),
        }

        # Ağırlıklı ortalama
        total_score = sum(scores[key] * ContentQualityScorer.QUALITY_WEIGHTS[key] for key in scores)

        return min(100, max(0, total_score))

    @staticmethod
    def _score_length(headline: str) -> float:
        """Başlık uzunluğu puanı (optimal: 60-80 karakter)"""
        length = len(headline)
        if 60 <= length <= 80:
            return 100
        elif 50 <= length <= 90:
            return 80
        elif 40 <= length <= 100:
            return 60
        else:
            return 30

    @staticmethod
    def _score_sentiment(headline: str) -> float:
        """Duygu analizi puanı"""
        positive_words = ["başarı", "iyi", "harika", "yeni", "gelişme", "rekor"]
        negative_words = ["kriz", "hata", "sorun", "kayıp", "tehdit", "ölüm"]

        headline_lower = headline.lower()

        positive_count = sum(1 for word in positive_words if word in headline_lower)
        negative_count = sum(1 for word in negative_words if word in headline_lower)

        if positive_count > negative_count:
            return 75
        elif negative_count > positive_count:
            return 70  # Negatif haberler de ilgi çekici
        else:
            return 50

    @staticmethod
    def _score_keywords(headline: str) -> float:
        """Anahtar kelime yoğunluğu puanı"""
        words = headline.split()
        if len(words) < 3:
            return 20
        elif len(words) < 6:
            return 50
        elif len(words) <= 12:
            return 100
        else:
            return 70

    @staticmethod
    def _score_clickability(headline: str) -> float:
        """Tıklanabilirlik puanı"""
        score = 50

        if "?" in headline:
            score += 15
        if any(char.isdigit() for char in headline):
            score += 15
        if any(word in headline.lower() for word in ["nasıl", "neden", "ne zaman"]):
            score += 10

        return min(100, score)

    @staticmethod
    def _score_uniqueness(headline: str, category: str = None) -> float:
        """Benzersizlik puanı"""
        similar = DuplicateDetector.find_similar_articles(headline, category, threshold=0.80)

        if not similar:
            return 100
        elif len(similar) == 1:
            return 70
        else:
            return 40


# ============================================================================
# SINIFLAMA VE KATEGORİZASYON
# ============================================================================


class ArticleClassifier:
    """
    Makaleleri kategori ve alt kategoriye göre sınıflandır
    """

    CATEGORIES = {
        "Teknoloji": ["Yapay Zeka", "Mobil", "İnternet", "Güvenlik", "Yazılım"],
        "Sağlık": ["Tıp", "Beslenme", "Spor", "Ruh Sağlığı", "Koşullar"],
        "Ekonomi": ["Finans", "Borsa", "İş Dünyası", "Kripto", "Emtia"],
        "Politika": ["Hükümet", "Seçimler", "Diplomasi", "Yasalar", "Uluslararası"],
        "Spor": ["Futbol", "Basketbol", "Tenis", "Olimpiyatlar", "Diğer Sporlar"],
        "Eğlence": ["Sinema", "Müzik", "Dizi", "Oyuncu", "Ödüller"],
        "Bilim": ["Uzay", "Fizik", "Biyoloji", "Kimya", "Keşifler"],
    }

    @classmethod
    def classify_article(cls, title: str, summary: str) -> dict:
        """
        Makaleyi kategori ve alt kategoriye sınıflandır
        """
        text = f"{title}. {summary}"

        # Kategori belirleme (basit keyword matching)
        category, confidence = cls._determine_category(text)

        # Alt kategori belirleme
        subcategory = cls._determine_subcategory(text, category)

        # Önem seviyesi
        importance = cls._calculate_importance(title, summary)

        # Trending score
        trending_score = cls._calculate_trending_score(title)

        return {
            "category": category,
            "category_confidence": confidence,
            "subcategory": subcategory,
            "importance_level": importance,
            "trending_score": trending_score,
        }

    @classmethod
    def _determine_category(cls, text: str) -> tuple[str, float]:
        """
        Kategoriyi belirle
        """
        text_lower = text.lower()

        category_scores = {}
        for category, keywords in cls.CATEGORIES.items():
            score = sum(1 for keyword in keywords if keyword.lower() in text_lower)
            category_scores[category] = score

        if not category_scores or max(category_scores.values()) == 0:
            return "Diğer", 0.5

        best_category = max(category_scores, key=category_scores.get)
        confidence = min(1.0, category_scores[best_category] / 3)  # Normalize

        return best_category, confidence

    @classmethod
    def _determine_subcategory(cls, text: str, category: str) -> str:
        """
        Alt kategoriyi belirle
        """
        if category not in cls.CATEGORIES:
            return "Diğer"

        text_lower = text.lower()
        subcategories = cls.CATEGORIES[category]

        for subcategory in subcategories:
            if subcategory.lower() in text_lower:
                return subcategory

        return subcategories[0]  # İlk alt kategoriyi döndür

    @staticmethod
    def _calculate_importance(title: str, summary: str) -> int:
        """
        Haberin önem seviyesini hesapla (1-5)
        """
        score = 1

        # Anahtar kelimeler
        important_keywords = ["ölüm", "kriz", "başkan", "hükümet", "savaş", "felaket"]
        if any(kw in title.lower() for kw in important_keywords):
            score += 2

        # Uzunluk
        if len(summary.split()) > 200:
            score += 1

        return min(5, score)

    @staticmethod
    def _calculate_trending_score(title: str) -> float:
        """
        Trending score hesapla (0-100)
        """
        trending_words = ["yeni", "ilk", "açıklandı", "başladı", "sona erdi", "rekor"]
        score = 50

        if any(word in title.lower() for word in trending_words):
            score += 25

        return min(100, score)


# ============================================================================
# YAZAR VE STİL SEÇİMİ
# ============================================================================


class AuthorStyleSelector:
    """
    Kategori ve içeriğe göre en uygun yazarı ve stili seç
    """

    @staticmethod
    def select_author_and_style(category: str, importance_level: int) -> tuple:
        """
        Kategori ve önem seviyesine göre yazar seç
        """
        from authors.models import Author
        from news.models_advanced import AuthorCategoryMapping

        # Kategori-yazar mapping'i kontrol et
        mappings = AuthorCategoryMapping.objects.filter(category=category, author__is_active=True).order_by(
            "-expertise_level", "-is_primary"
        )

        if mappings.exists():
            author = mappings.first().author
            mapping = mappings.first()
        else:
            # Fallback: Aktif yazarlardan rastgele seç
            author = Author.objects.filter(is_active=True).first()
            mapping = None

        # Yazı stilini belirle
        style = AuthorStyleSelector._select_style(importance_level, mapping)

        return author, style

    @staticmethod
    def _select_style(importance_level: int, mapping=None) -> dict:
        """
        Yazı stilini seç
        """
        # Ton seçimi
        if importance_level >= 4:
            tone = "formal"
        elif importance_level >= 2:
            tone = "professional"
        else:
            tone = "casual"

        # Uzunluk seçimi
        if importance_level >= 4:
            word_count = (800, 1000)
        elif importance_level >= 2:
            word_count = (600, 800)
        else:
            word_count = (400, 600)

        # Karmaşıklık seçimi
        complexity = "high" if importance_level >= 3 else "medium"

        # Ses seçimi
        voice = mapping.preferred_tone if mapping else "professional"

        return {"tone": tone, "word_count": word_count, "complexity": complexity, "voice": voice}


# ============================================================================
# PROMPT ÜRETİMİ
# ============================================================================


class PromptGenerator:
    """
    Dinamik ve kategori-aware prompt'lar oluştur
    """

    @staticmethod
    def generate_content_prompt(article_data: dict, author, style: dict) -> str:
        """
        İçerik üretimi için dinamik prompt oluştur
        """
        from news.models_advanced import PromptTemplate

        try:
            template = PromptTemplate.objects.get(
                category=article_data["category"], template_type="article", is_active=True
            )

            prompt = template.template_content.format(
                title=article_data["title"],
                summary=article_data["summary"],
                author_name=author.name,
                author_expertise=author.expertise,
                category=article_data["category"],
                tone=style["tone"],
                word_count=style["word_count"][0],
                importance_level=article_data["importance_level"],
            )

        except PromptTemplate.DoesNotExist:
            # Varsayılan template kullan
            prompt = PromptGenerator._get_default_prompt(article_data, author, style)

        return prompt

    @staticmethod
    def _get_default_prompt(article_data: dict, author, style: dict) -> str:
        """
        Varsayılan prompt template'i
        """
        min_words, max_words = style["word_count"]

        return f"""
Sen {author.name} isimli deneyimli bir {article_data["category"]} gazetecisisin.

HABER BİLGİLERİ:
Başlık: {article_data["title"]}
Kategori: {article_data["category"]}
Özet: {article_data["summary"]}
Kaynak: {article_data.get("link", "")}

YAZIM TALIMATLAR:
1. Ton: {style["tone"]}
2. Uzunluk: {min_words}-{max_words} kelime
3. Karmaşıklık: {style["complexity"]}
4. Ses: {style["voice"]}

YAPISI:
1. Giriş (100-150 kelime)
   - Haberin özeti
   - En önemli bilgiler
   - Neden önemli

2. Gelişme ({max_words - 250}-{max_words - 150} kelime)
   - Detaylı bilgiler
   - Bağlam ve arka plan
   - İlgili veriler

3. Sonuç (100-150 kelime)
   - Etki ve sonuçlar
   - Gelecek beklentileri

KURALLAR:
- HTML format: <h2>, <h3>, <p>, <strong>, <em>, <ul>, <li>
- Paragraflar: 3-4 cümle
- Cümleler: 15-20 kelime
- Teknik terimleri açıkla
- Kaynak metni doğrudan kopyalama
- SEO: Ana anahtar kelimeleri doğal kullan
- Tarafsız ve profesyonel ton

ÇIKTI:
Sadece HTML formatında haber yazısını yaz.
        """.strip()

    @staticmethod
    def generate_image_prompt(title: str, category: str) -> str:
        """
        Görsel üretimi için prompt oluştur
        """
        category_styles = {
            "Teknoloji": "modern, futuristic, tech-focused",
            "Sağlık": "clinical, professional, medical",
            "Ekonomi": "professional, business, financial",
            "Politika": "formal, governmental, serious",
            "Spor": "dynamic, energetic, action-packed",
            "Eğlence": "vibrant, colorful, entertaining",
            "Bilim": "scientific, educational, discovery",
        }

        style = category_styles.get(category, "professional news")

        return f"""
Professional news photography style for: {title}

Category: {category}
Style: {style}

Requirements:
- High quality, photorealistic, journalistic style
- 16:9 aspect ratio (1920x1080)
- Clean composition with professional lighting
- Editorial quality, suitable for news publication
- No text, no watermarks, no logos
- Visually engaging and relevant to the topic
- Color grading: Professional news standard
- Focus: Clear and sharp subject matter
        """.strip()

    @staticmethod
    def generate_video_prompt(title: str, category: str, duration: int = 8) -> str:
        """
        Video üretimi için prompt oluştur
        """
        return f"""
[Cinematography: Dynamic news footage style] +
[Subject: {title}] +
[Action: Engaging narrative movement] +
[Context: Professional news setting] +
[Style: Modern, clean, journalistic]

Requirements:
- Duration: {duration} seconds
- Resolution: 1080p
- Aspect Ratio: 16:9
- Frame Rate: 30fps
- Audio: Professional news background music
- Tone: Informative, engaging, professional
- Motion: Smooth, professional camera work
- Color: Vibrant, professional news standard

Category: {category}
        """.strip()


# ============================================================================
# RSS MEDYA ÇIKARMA
# ============================================================================


class RSSMediaExtractor:
    """
    RSS feed'den medya (görsel, video) çıkar
    """

    @staticmethod
    def extract_media_from_rss(feed_url: str, article_url: str) -> dict:
        """
        RSS feed'den makaleye ait medya çıkar
        """
        media = {"images": [], "videos": [], "audio": []}

        try:
            feed = feedparser.parse(feed_url)

            for entry in feed.entries:
                if entry.get("link") == article_url:
                    # Media content
                    if hasattr(entry, "media_content"):
                        for item in entry.media_content:
                            media_type = item.get("type", "")
                            if "image" in media_type:
                                media["images"].append(
                                    {"url": item.get("url", ""), "type": media_type, "credit": item.get("credit", "")}
                                )
                            elif "video" in media_type:
                                media["videos"].append(
                                    {
                                        "url": item.get("url", ""),
                                        "type": media_type,
                                        "duration": item.get("duration", 0),
                                    }
                                )

                    # HTML'den görselleri çıkar
                    if hasattr(entry, "summary"):
                        images = RSSMediaExtractor._extract_images_from_html(entry.summary)
                        media["images"].extend(images)

                    break

        except Exception as e:
            logger.error(f"Error extracting media from RSS: {e!s}")

        return media

    @staticmethod
    def _extract_images_from_html(html_content: str) -> list[dict]:
        """
        HTML'den görsel URL'lerini çıkar
        """
        images = []

        try:
            soup = BeautifulSoup(html_content, "html.parser")

            for img in soup.find_all("img"):
                images.append({"url": img.get("src", ""), "alt": img.get("alt", ""), "title": img.get("title", "")})

        except Exception as e:
            logger.error(f"Error extracting images from HTML: {e!s}")

        return images


# ============================================================================
# OKUNABILIRLIK METRİKLERİ
# ============================================================================


class ReadabilityMetrics:
    """
    Türkçe metinler için okunabilirlik metrikleri
    """

    @staticmethod
    def count_syllables(word: str) -> int:
        """
        Türkçe kelimedeki hece sayısını say
        """
        word = word.lower()
        vowels = "aeıioöuü"
        syllable_count = 0
        previous_was_vowel = False

        for char in word:
            is_vowel = char in vowels
            if is_vowel and not previous_was_vowel:
                syllable_count += 1
            previous_was_vowel = is_vowel

        return max(1, syllable_count)

    @staticmethod
    def calculate_lix_index(text: str) -> float:
        """
        Lix İndeksi hesapla (Türkçe için uyarlanmış)
        """
        words = text.split()
        sentences = [s.strip() for s in text.split(".") if s.strip()]

        if not words or not sentences:
            return 0

        long_words = [w for w in words if len(w) > 6]

        lix = (len(words) / len(sentences)) + ((len(long_words) * 100) / len(words))

        return lix

    @staticmethod
    def get_readability_level(lix_score: float) -> str:
        """
        Lix skorundan okunabilirlik seviyesini belirle
        """
        if lix_score < 20:
            return "Çok Kolay"
        elif lix_score < 30:
            return "Kolay"
        elif lix_score < 40:
            return "Orta"
        elif lix_score < 50:
            return "Zor"
        else:
            return "Çok Zor"

    @staticmethod
    def calculate_content_metrics(content: str) -> dict:
        """
        İçerik metrikleri hesapla
        """
        words = content.split()
        sentences = [s.strip() for s in content.split(".") if s.strip()]
        paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]

        total_syllables = sum(ReadabilityMetrics.count_syllables(w) for w in words)

        return {
            "word_count": len(words),
            "sentence_count": len(sentences),
            "paragraph_count": len(paragraphs),
            "avg_word_length": sum(len(w) for w in words) / len(words) if words else 0,
            "avg_sentence_length": len(words) / len(sentences) if sentences else 0,
            "avg_syllables_per_word": total_syllables / len(words) if words else 0,
            "lix_index": ReadabilityMetrics.calculate_lix_index(content),
        }
