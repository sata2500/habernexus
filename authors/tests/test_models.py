"""Authors modeli için testler."""

from django.test import TestCase

import pytest

from authors.models import Author


@pytest.mark.django_db
class TestAuthorModel(TestCase):
    """Author modeli test sınıfı."""

    def test_author_creation(self):
        """Yazar oluşturma testi."""
        author = Author.objects.create(name="Ahmet Yılmaz", slug="ahmet-yilmaz", expertise="Teknoloji", bio="Test bio")

        assert author.name == "Ahmet Yılmaz"
        assert author.slug == "ahmet-yilmaz"
        assert author.expertise == "Teknoloji"
        assert author.bio == "Test bio"
        assert author.is_active is True

    def test_author_str_representation(self):
        """Yazar string temsili testi."""
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Spor")

        assert str(author) == "Test Yazar (Spor)"

    def test_author_get_absolute_url(self):
        """Yazar URL testi."""
        author = Author.objects.create(name="Test Yazar", slug="test-yazar", expertise="Ekonomi")

        url = author.get_absolute_url()
        assert url == f"/yazar/{author.slug}/"

    def test_author_slug_uniqueness(self):
        """Yazar slug benzersizlik testi."""
        Author.objects.create(name="Test Yazar 1", slug="test-yazar", expertise="Teknoloji")

        # Aynı slug ile ikinci yazar oluşturmaya çalış
        with pytest.raises(Exception):
            Author.objects.create(name="Test Yazar 2", slug="test-yazar", expertise="Spor")

    def test_author_ordering(self):
        """Yazar sıralama testi."""
        author1 = Author.objects.create(name="Zeynep", slug="zeynep", expertise="Teknoloji")
        author2 = Author.objects.create(name="Ahmet", slug="ahmet", expertise="Spor")

        authors = Author.objects.all()
        assert authors[0] == author2  # Ahmet (alfabetik olarak önce)
        assert authors[1] == author1  # Zeynep
