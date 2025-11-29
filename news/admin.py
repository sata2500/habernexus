from django.contrib import admin
from django.utils.html import format_html
from .models import Article, RssSource


@admin.register(RssSource)
class RssSourceAdmin(admin.ModelAdmin):
    list_display = ('name', 'category', 'frequency_display', 'is_active', 'last_checked')
    list_filter = ('is_active', 'category', 'frequency_minutes', 'created_at')
    search_fields = ('name', 'url', 'category')
    readonly_fields = ('created_at', 'updated_at', 'last_checked')
    
    fieldsets = (
        ('Temel Bilgiler', {
            'fields': ('name', 'category', 'url', 'is_active')
        }),
        ('Tarama Ayarları', {
            'fields': ('frequency_minutes', 'last_checked')
        }),
        ('Tarihler', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def frequency_display(self, obj):
        return f"{obj.frequency_minutes} dakika"
    frequency_display.short_description = 'Tarama Sıklığı'


@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ('title', 'author', 'category', 'status_badge', 'ai_badge', 'published_at', 'views_count')
    list_filter = ('status', 'is_ai_generated', 'category', 'published_at', 'created_at')
    search_fields = ('title', 'content', 'tags')
    prepopulated_fields = {'slug': ('title',)}
    readonly_fields = ('created_at', 'updated_at', 'views_count', 'slug')
    date_hierarchy = 'published_at'
    
    fieldsets = (
        ('Temel Bilgiler', {
            'fields': ('title', 'slug', 'status', 'author', 'category')
        }),
        ('İçerik', {
            'fields': ('content', 'excerpt')
        }),
        ('Görsel', {
            'fields': ('featured_image', 'featured_image_alt')
        }),
        ('SEO ve Etiketler', {
            'fields': ('tags',),
            'classes': ('collapse',)
        }),
        ('Yapay Zeka Bilgileri', {
            'fields': ('is_ai_generated', 'is_ai_image'),
            'classes': ('collapse',)
        }),
        ('RSS Kaynağı', {
            'fields': ('rss_source', 'original_url'),
            'classes': ('collapse',)
        }),
        ('İstatistikler', {
            'fields': ('views_count',),
            'classes': ('collapse',)
        }),
        ('Tarihler', {
            'fields': ('published_at', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

    def status_badge(self, obj):
        colors = {
            'draft': '#808080',
            'published': '#00cc00',
            'archived': '#cccccc',
        }
        labels = {
            'draft': 'Taslak',
            'published': 'Yayınlandı',
            'archived': 'Arşivlendi',
        }
        color = colors.get(obj.status, '#000000')
        label = labels.get(obj.status, obj.status)
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            color,
            label
        )
    status_badge.short_description = 'Durum'

    def ai_badge(self, obj):
        if obj.is_ai_generated:
            return format_html(
                '<span style="background-color: #0066cc; color: white; padding: 3px 8px; border-radius: 3px;">🤖 AI</span>'
            )
        return format_html(
            '<span style="background-color: #cccccc; color: black; padding: 3px 8px; border-radius: 3px;">Manual</span>'
        )
    ai_badge.short_description = 'Tür'

    actions = ['publish_articles', 'archive_articles']

    def publish_articles(self, request, queryset):
        updated = queryset.update(status='published')
        self.message_user(request, f'{updated} makale yayınlandı.')
    publish_articles.short_description = 'Seçili makaleleri yayınla'

    def archive_articles(self, request, queryset):
        updated = queryset.update(status='archived')
        self.message_user(request, f'{updated} makale arşivlendi.')
    archive_articles.short_description = 'Seçili makaleleri arşivle'
