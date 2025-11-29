from django.contrib import admin
from .models import Author


@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    list_display = ('name', 'expertise', 'is_active', 'created_at')
    list_filter = ('is_active', 'expertise', 'created_at')
    search_fields = ('name', 'bio', 'expertise')
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ('created_at', 'updated_at')
    
    fieldsets = (
        ('Temel Bilgiler', {
            'fields': ('name', 'slug', 'expertise', 'is_active')
        }),
        ('Biyografi ve İletişim', {
            'fields': ('bio', 'email', 'website')
        }),
        ('Profil Resmi', {
            'fields': ('profile_image',),
            'classes': ('collapse',)
        }),
        ('Tarihler', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
