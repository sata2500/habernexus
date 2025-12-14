"""
İçerik Kalitesi Metrikleri Hesaplama Araçları
Okunabilirlik, SEO ve yapı metriklerini hesaplar.
"""

import re
from html.parser import HTMLParser


class HTMLTextExtractor(HTMLParser):
    """
    HTML'den metin çıkarmak için yardımcı sınıf.
    """

    def __init__(self):
        super().__init__()
        self.text = []
        self.in_script = False
        self.in_style = False

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self.in_script = True if tag == "script" else False
            self.in_style = True if tag == "style" else False

    def handle_endtag(self, tag):
        if tag in ("script", "style"):
            self.in_script = False
            self.in_style = False

    def handle_data(self, data):
        if not self.in_script and not self.in_style:
            self.text.append(data)

    def get_text(self):
        return "".join(self.text)


def extract_text_from_html(html_content):
    """
    HTML içeriğinden metin çıkar.
    """
    parser = HTMLTextExtractor()
    try:
        parser.feed(html_content)
        return parser.get_text()
    except Exception:
        return html_content


def count_syllables(word):
    """
    Bir kelimedeki hece sayısını tahmin et.
    """
    word = word.lower()
    syllable_count = 0
    vowels = "aeıioöuü"
    previous_was_vowel = False

    for char in word:
        is_vowel = char in vowels
        if is_vowel and not previous_was_vowel:
            syllable_count += 1
        previous_was_vowel = is_vowel

    # Düzeltmeler
    if word.endswith("e"):
        syllable_count -= 1
    if word.endswith("le"):
        syllable_count += 1

    return max(1, syllable_count)


def calculate_readability(html_content):
    """
    Okunabilirlik metriklerini hesapla.
    Flesch-Kincaid, Gunning Fog, SMOG indeksleri.
    """
    # HTML'den metin çıkar
    text = extract_text_from_html(html_content)

    # Temizle
    text = re.sub(r"\s+", " ", text).strip()

    # Temel metrikler
    words = text.split()
    word_count = len(words)

    # Cümle sayısı
    sentences = re.split(r"[.!?]+", text)
    sentences = [s.strip() for s in sentences if s.strip()]
    sentence_count = len(sentences)

    # Paragraf sayısı
    paragraphs = re.split(r"\n\n+", text)
    paragraphs = [p.strip() for p in paragraphs if p.strip()]
    paragraph_count = len(paragraphs)

    # Hece sayısı
    syllable_count = sum(count_syllables(word) for word in words)

    # Ortalamalar
    avg_sentence_length = word_count / sentence_count if sentence_count > 0 else 0
    avg_word_length = sum(len(word) for word in words) / word_count if word_count > 0 else 0

    # Flesch-Kincaid Grade Level
    if sentence_count > 0 and word_count > 0:
        flesch_kincaid = 0.39 * (word_count / sentence_count) + 11.8 * (syllable_count / word_count) - 15.59
        flesch_kincaid = max(0, min(18, flesch_kincaid))  # 0-18 aralığında
    else:
        flesch_kincaid = 0

    # Gunning Fog Index
    complex_words = sum(1 for word in words if count_syllables(word) >= 3)
    if sentence_count > 0 and word_count > 0:
        gunning_fog = 0.4 * ((word_count / sentence_count) + 100 * (complex_words / word_count))
        gunning_fog = max(0, min(18, gunning_fog))
    else:
        gunning_fog = 0

    # SMOG Index
    if sentence_count > 0:
        smog = 1.0430 * (30 * (complex_words / sentence_count)) ** 0.5 + 3.1291
        smog = max(0, min(18, smog))
    else:
        smog = 0

    return {
        "word_count": word_count,
        "sentence_count": sentence_count,
        "paragraph_count": paragraph_count,
        "syllable_count": syllable_count,
        "avg_sentence_length": round(avg_sentence_length, 2),
        "avg_word_length": round(avg_word_length, 2),
        "flesch_kincaid_grade": round(flesch_kincaid, 2),
        "gunning_fog_index": round(gunning_fog, 2),
        "smog_index": round(smog, 2),
    }


def calculate_seo_metrics(title, html_content, category):
    """
    SEO metriklerini hesapla.
    Anahtar kelime yoğunluğu, meta açıklaması vb.
    """
    text = extract_text_from_html(html_content)
    text_lower = text.lower()

    # Birincil anahtar kelime (başlıktan çıkar)
    title_words = title.lower().split()
    primary_keyword = " ".join(title_words[:2])  # İlk 2 kelime

    # Anahtar kelime sayıları
    primary_keyword_count = len(re.findall(r"\b" + re.escape(primary_keyword) + r"\b", text_lower))

    # İkincil anahtar kelimeler (kategori bazlı)
    secondary_keywords = get_secondary_keywords(category)
    secondary_keyword_count = sum(
        len(re.findall(r"\b" + re.escape(kw) + r"\b", text_lower)) for kw in secondary_keywords
    )

    # Kelime sayısı
    words = text.split()
    word_count = len(words)

    # Anahtar kelime yoğunluğu
    keyword_density = (primary_keyword_count / word_count * 100) if word_count > 0 else 0

    return {
        "primary_keyword": primary_keyword,
        "primary_keyword_count": primary_keyword_count,
        "secondary_keyword_count": secondary_keyword_count,
        "keyword_density": round(keyword_density, 2),
    }


def get_secondary_keywords(category):
    """
    Kategori bazlı ikincil anahtar kelimeler.
    """
    keywords_by_category = {
        "Teknoloji": ["yazılım", "uygulama", "veri", "siber", "dijital", "web"],
        "Spor": ["oyuncu", "takım", "maç", "turnuva", "antrenör", "hakem"],
        "Siyaset": ["hükümet", "seçim", "kanun", "parlamento", "başkan", "vali"],
        "Ekonomi": ["pazar", "yatırım", "finans", "borsa", "şirket", "ticaret"],
        "Sağlık": ["doktor", "hastane", "tedavi", "hastalık", "ilaç", "sağlık"],
    }

    return keywords_by_category.get(category, [])


def calculate_structure_metrics(html_content):
    """
    İçerik yapısı metriklerini hesapla.
    Başlıklar, listeler, görseller vb.
    """
    # Başlıkları say
    h2_count = len(re.findall(r"<h2[^>]*>.*?</h2>", html_content, re.IGNORECASE))
    h3_count = len(re.findall(r"<h3[^>]*>.*?</h3>", html_content, re.IGNORECASE))
    heading_count = h2_count + h3_count

    # Listeleri kontrol et
    has_lists = bool(re.search(r"<[ou]l[^>]*>.*?</[ou]l>", html_content, re.IGNORECASE))
    list_count = len(re.findall(r"<li[^>]*>.*?</li>", html_content, re.IGNORECASE))

    # Görselleri kontrol et
    has_images = bool(re.search(r"<img[^>]*>", html_content, re.IGNORECASE))
    image_count = len(re.findall(r"<img[^>]*>", html_content, re.IGNORECASE))

    # Kalın metni kontrol et
    has_bold_text = bool(re.search(r"<strong[^>]*>.*?</strong>", html_content, re.IGNORECASE))
    bold_count = len(re.findall(r"<strong[^>]*>.*?</strong>", html_content, re.IGNORECASE))

    # İç bağlantıları kontrol et
    internal_links = len(re.findall(r'<a[^>]*href="[^"]*"[^>]*>.*?</a>', html_content, re.IGNORECASE))

    return {
        "heading_count": heading_count,
        "h2_count": h2_count,
        "h3_count": h3_count,
        "has_lists": has_lists,
        "list_count": list_count,
        "has_images": has_images,
        "image_count": image_count,
        "has_bold_text": has_bold_text,
        "bold_count": bold_count,
        "internal_link_count": internal_links,
    }


def validate_content_quality(metrics, thresholds=None):
    """
    İçerik kalitesini eşiklere göre doğrula.
    """
    if thresholds is None:
        thresholds = {
            "min_word_count": 400,
            "max_word_count": 1000,
            "target_readability": 8,
            "min_keyword_density": 1.5,
            "max_keyword_density": 3.0,
            "min_headings": 2,
        }

    issues = []

    # Kelime sayısı kontrolü
    if metrics["word_count"] < thresholds["min_word_count"]:
        issues.append(f"Çok kısa: {metrics['word_count']} kelime (minimum: {thresholds['min_word_count']})")
    elif metrics["word_count"] > thresholds["max_word_count"]:
        issues.append(f"Çok uzun: {metrics['word_count']} kelime (maksimum: {thresholds['max_word_count']})")

    # Okunabilirlik kontrolü
    readability = metrics.get("flesch_kincaid_grade", 0)
    if readability > thresholds["target_readability"] + 2:
        issues.append(f"Çok zor: Flesch-Kincaid {readability} (hedef: {thresholds['target_readability']})")

    # Anahtar kelime yoğunluğu kontrolü
    keyword_density = metrics.get("keyword_density", 0)
    if keyword_density < thresholds["min_keyword_density"]:
        issues.append(f"Az anahtar kelime: {keyword_density}% (minimum: {thresholds['min_keyword_density']}%)")
    elif keyword_density > thresholds["max_keyword_density"]:
        issues.append(f"Çok fazla anahtar kelime: {keyword_density}% (maksimum: {thresholds['max_keyword_density']}%)")

    # Yapı kontrolü
    heading_count = metrics.get("heading_count", 0)
    if heading_count < thresholds["min_headings"]:
        issues.append(f"Az başlık: {heading_count} (minimum: {thresholds['min_headings']})")

    return {
        "is_valid": len(issues) == 0,
        "issues": issues,
        "issue_count": len(issues),
    }
