"""
Geliştirilmiş İçerik Üretim Sistemi - Admin Konfigürasyonu
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse

from .models_extended import (
    ContentQualityMetrics,
    HeadlineScore,
    ArticleClassification,
    ResearchSource,
    ContentGenerationLog,
)


@admin.register(HeadlineScore)
class HeadlineScoreAdmin(admin.ModelAdmin):
    list_display = (
        'headline_preview',
        'overall_score_badge',
        'rss_source',
        'is_processed',
        'created_at'
    )
    list_filter = (
        'is_processed',
        'rss_source',
        'created_at',
    )
    search_fields = ('original_headline',)
    readonly_fields = (
        'created_at',
        'updated_at',
        'word_count',
        'character_count',
        'overall_score',
        'uniqueness_score',
        'engagement_score',
        'keyword_relevance',
    )

    fieldsets = (
        ('Başlık Bilgileri', {
            'fields': ('original_headline', 'rss_source', 'word_count', 'character_count')
        }),
        ('Puanlama Bileşenleri', {
            'fields': (
                'overall_score',
                'uniqueness_score',
                'engagement_score',
                'keyword_relevance',
            ),
            'classes': ('collapse',)
        }),
        ('Başlık Özellikleri', {
            'fields': (
                'has_numbers',
                'has_power_words',
                'power_words',
                'is_question',
                'is_listicle',
            ),
            'classes': ('collapse',)
        }),
        ('Durum', {
            'fields': ('is_processed', 'article')
        }),
        ('Tarihler', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    actions = ['mark_as_processed', 'mark_as_unprocessed']

    def headline_preview(self, obj):
        return obj.original_headline[:60]
    headline_preview.short_description = 'Başlık'

    def overall_score_badge(self, obj):
        color = self._get_score_color(obj.overall_score)
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 3px; font-weight: bold;">{:.1f}</span>',
            color,
            obj.overall_score
        )
    overall_score_badge.short_description = 'Puan'

    def _get_score_color(self, score):
        if score >= 80:
            return '#28a745'  # Yeşil
        elif score >= 60:
            return '#ffc107'  # Sarı
        else:
            return '#dc3545'  # Kırmızı

    def mark_as_processed(self, request, queryset):
        updated = queryset.update(is_processed=True)
        self.message_user(request, f"{updated} başlık işlendi olarak işaretlendi.")
    mark_as_processed.short_description = "Seçili başlıkları işlendi olarak işaretle"

    def mark_as_unprocessed(self, request, queryset):
        updated = queryset.update(is_processed=False)
        self.message_user(request, f"{updated} başlık işlenmedi olarak işaretlendi.")
    mark_as_unprocessed.short_description = "Seçili başlıkları işlenmedi olarak işaretle"


@admin.register(ArticleClassification)
class ArticleClassificationAdmin(admin.ModelAdmin):
    list_display = (
        'article_link',
        'article_type_badge',
        'primary_category',
        'research_depth_display',
        'type_confidence_badge',
    )
    list_filter = (
        'article_type',
        'primary_category',
        'research_depth',
        'is_time_sensitive',
        'is_controversial',
        'tone',
    )
    search_fields = ('article__title', 'primary_category')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Makale', {
            'fields': ('article',)
        }),
        ('Tür Sınıflandırması', {
            'fields': (
                'article_type',
                'type_confidence',
                'primary_category',
                'secondary_categories',
            )
        }),
        ('İçerik Özellikleri', {
            'fields': (
                'research_depth',
                'is_time_sensitive',
                'is_controversial',
                'tone',
                'target_audience',
            )
        }),
        ('AI Ayarları', {
            'fields': (
                'recommended_ai_model',
                'requires_fact_checking',
            ),
            'classes': ('collapse',)
        }),
        ('Tarihler', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def article_link(self, obj):
        url = reverse('admin:news_article_change', args=[obj.article.id])
        return format_html('<a href="{}">{}</a>', url, obj.article.title[:50])
    article_link.short_description = 'Makale'

    def article_type_badge(self, obj):
        colors = {
            'news': '#0066cc',
            'analysis': '#ff6600',
            'feature': '#009900',
            'opinion': '#cc0000',
            'tutorial': '#9900cc',
            'interview': '#00cccc',
            'breaking': '#ff0000',
        }
        color = colors.get(obj.article_type, '#666666')
        label = obj.get_article_type_display()
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            label
        )
    article_type_badge.short_description = 'Tür'

    def research_depth_display(self, obj):
        return obj.get_research_depth_display()
    research_depth_display.short_description = 'Araştırma Derinliği'

    def type_confidence_badge(self, obj):
        confidence = obj.type_confidence * 100
        color = '#28a745' if confidence >= 80 else '#ffc107' if confidence >= 60 else '#dc3545'
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{:.0f}%</span>',
            color,
            confidence
        )
    type_confidence_badge.short_description = 'Güven'


@admin.register(ContentQualityMetrics)
class ContentQualityMetricsAdmin(admin.ModelAdmin):
    list_display = (
        'article_link',
        'overall_score_badge',
        'readability_badge',
        'keyword_density_badge',
        'word_count',
    )
    list_filter = (
        'created_at',
    )
    search_fields = ('article__title',)
    readonly_fields = (
        'created_at',
        'updated_at',
        'flesch_kincaid_grade',
        'gunning_fog_index',
        'smog_index',
        'overall_quality_score',
    )

    fieldsets = (
        ('Makale', {
            'fields': ('article',)
        }),
        ('Okunabilirlik Metrikleri', {
            'fields': (
                'flesch_kincaid_grade',
                'gunning_fog_index',
                'smog_index',
            )
        }),
        ('İçerik Metrikleri', {
            'fields': (
                'word_count',
                'sentence_count',
                'paragraph_count',
                'avg_sentence_length',
                'avg_word_length',
            )
        }),
        ('SEO Metrikleri', {
            'fields': (
                'primary_keyword',
                'primary_keyword_count',
                'secondary_keyword_count',
                'keyword_density',
                'meta_description_length',
                'internal_link_count',
            ),
            'classes': ('collapse',)
        }),
        ('Yapı Metrikleri', {
            'fields': (
                'heading_count',
                'h2_count',
                'h3_count',
                'has_lists',
                'list_count',
                'has_images',
                'image_count',
                'has_bold_text',
                'bold_count',
            ),
            'classes': ('collapse',)
        }),
        ('Genel Kalite', {
            'fields': ('overall_quality_score',)
        }),
        ('Tarihler', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def article_link(self, obj):
        url = reverse('admin:news_article_change', args=[obj.article.id])
        return format_html('<a href="{}">{}</a>', url, obj.article.title[:50])
    article_link.short_description = 'Makale'

    def overall_score_badge(self, obj):
        color = self._get_score_color(obj.overall_quality_score)
        return format_html(
            '<span style="background-color: {}; color: white; padding: 5px 10px; border-radius: 3px; font-weight: bold;">{:.1f}</span>',
            color,
            obj.overall_quality_score
        )
    overall_score_badge.short_description = 'Genel Puan'

    def readability_badge(self, obj):
        grade = obj.flesch_kincaid_grade
        if 8 <= grade <= 12:
            color = '#28a745'
        elif 6 <= grade <= 14:
            color = '#ffc107'
        else:
            color = '#dc3545'
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{:.1f}</span>',
            color,
            grade
        )
    readability_badge.short_description = 'Okunabilirlik'

    def keyword_density_badge(self, obj):
        density = obj.keyword_density
        if 1.5 <= density <= 3.0:
            color = '#28a745'
        elif 1.0 <= density <= 4.0:
            color = '#ffc107'
        else:
            color = '#dc3545'
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{:.2f}%</span>',
            color,
            density
        )
    keyword_density_badge.short_description = 'Anahtar Kelime'

    def _get_score_color(self, score):
        if score >= 80:
            return '#28a745'
        elif score >= 60:
            return '#ffc107'
        else:
            return '#dc3545'


@admin.register(ResearchSource)
class ResearchSourceAdmin(admin.ModelAdmin):
    list_display = (
        'source_title_preview',
        'article_link',
        'source_type_badge',
        'relevance_badge',
        'created_at',
    )
    list_filter = (
        'source_type',
        'created_at',
    )
    search_fields = ('source_title', 'article__title', 'source_url')
    readonly_fields = ('created_at',)

    fieldsets = (
        ('Makale', {
            'fields': ('article',)
        }),
        ('Kaynak Bilgileri', {
            'fields': (
                'source_url',
                'source_title',
                'source_type',
                'relevance_score',
            )
        }),
        ('Kullanım', {
            'fields': (
                'used_for',
                'extracted_text',
            ),
            'classes': ('collapse',)
        }),
        ('Tarih', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

    def source_title_preview(self, obj):
        return obj.source_title[:50]
    source_title_preview.short_description = 'Başlık'

    def article_link(self, obj):
        url = reverse('admin:news_article_change', args=[obj.article.id])
        return format_html('<a href="{}">{}</a>', url, obj.article.title[:40])
    article_link.short_description = 'Makale'

    def source_type_badge(self, obj):
        colors = {
            'news': '#0066cc',
            'academic': '#009900',
            'official': '#ff6600',
            'blog': '#9900cc',
            'social': '#00cccc',
            'other': '#666666',
        }
        color = colors.get(obj.source_type, '#666666')
        label = obj.get_source_type_display()
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            label
        )
    source_type_badge.short_description = 'Tür'

    def relevance_badge(self, obj):
        relevance = obj.relevance_score * 100
        color = '#28a745' if relevance >= 80 else '#ffc107' if relevance >= 60 else '#dc3545'
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{:.0f}%</span>',
            color,
            relevance
        )
    relevance_badge.short_description = 'Uygunluk'


@admin.register(ContentGenerationLog)
class ContentGenerationLogAdmin(admin.ModelAdmin):
    list_display = (
        'article_link',
        'stage_badge',
        'status_badge',
        'duration_display',
        'created_at',
    )
    list_filter = (
        'stage',
        'status',
        'created_at',
    )
    search_fields = ('article__title',)
    readonly_fields = (
        'created_at',
        'input_data',
        'output_data',
        'error_traceback',
    )

    fieldsets = (
        ('Makale', {
            'fields': ('article',)
        }),
        ('İşlem Bilgileri', {
            'fields': (
                'stage',
                'status',
                'duration',
                'ai_model_used',
            )
        }),
        ('API Bilgileri', {
            'fields': (
                'api_calls_count',
                'tokens_used',
            ),
            'classes': ('collapse',)
        }),
        ('Veri', {
            'fields': (
                'input_data',
                'output_data',
            ),
            'classes': ('collapse',)
        }),
        ('Hata', {
            'fields': (
                'error_message',
                'error_traceback',
            ),
            'classes': ('collapse',)
        }),
        ('Tarih', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )

    def article_link(self, obj):
        url = reverse('admin:news_article_change', args=[obj.article.id])
        return format_html('<a href="{}">{}</a>', url, obj.article.title[:40])
    article_link.short_description = 'Makale'

    def stage_badge(self, obj):
        colors = {
            'fetch': '#0066cc',
            'score': '#00cccc',
            'classify': '#009900',
            'research': '#ff6600',
            'generate': '#9900cc',
            'quality_check': '#ffcc00',
            'image_generation': '#ff3333',
            'publish': '#00cc00',
        }
        color = colors.get(obj.stage, '#666666')
        label = obj.get_stage_display()
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            label
        )
    stage_badge.short_description = 'Aşama'

    def status_badge(self, obj):
        colors = {
            'started': '#0066cc',
            'in_progress': '#ffc107',
            'completed': '#28a745',
            'failed': '#dc3545',
            'skipped': '#666666',
        }
        color = colors.get(obj.status, '#666666')
        label = obj.get_status_display()
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            label
        )
    status_badge.short_description = 'Durum'

    def duration_display(self, obj):
        if obj.duration < 1000:
            return f"{obj.duration}ms"
        else:
            return f"{obj.duration / 1000:.1f}s"
    duration_display.short_description = 'Süre'
