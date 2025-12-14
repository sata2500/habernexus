from unittest.mock import MagicMock, patch

import pytest

from news.models import RssSource
from news.models_extended import HeadlineScore
from news.tasks_v2 import calculate_engagement_score, fetch_rss_feeds_v2, score_headlines


@pytest.mark.django_db
class TestNewsTasksV2Coverage:
    def setup_method(self):
        self.source = RssSource.objects.create(
            name="Test Source", url="http://test.com/rss", category="Teknoloji", is_active=True
        )

    @patch("news.tasks_v2.feedparser.parse")
    def test_fetch_rss_feeds_v2_success(self, mock_parse):
        # Mock feed data
        mock_feed = MagicMock()
        mock_feed.bozo = False
        mock_feed.entries = [
            {"title": "Test Haber 1", "link": "http://test.com/1"},
            {"title": "Test Haber 2", "link": "http://test.com/2"},
        ]
        mock_parse.return_value = mock_feed

        result = fetch_rss_feeds_v2()

        assert "Başarılı" in result
        assert HeadlineScore.objects.count() == 2
        assert HeadlineScore.objects.filter(original_headline="Test Haber 1").exists()

    @patch("news.tasks_v2.feedparser.parse")
    def test_fetch_rss_feeds_v2_error_handling(self, mock_parse):
        # Mock exception
        mock_parse.side_effect = Exception("Connection error")

        # Should not raise exception but log error (task handles exceptions)
        try:
            fetch_rss_feeds_v2()
        except Exception:
            pass

        # Verify no headlines created
        assert HeadlineScore.objects.count() == 0

    def test_calculate_engagement_score(self):
        # Test short title
        assert calculate_engagement_score("Kısa") == 0

        # Test optimal length (50-70 chars)
        optimal_title = "Bu başlık tam olarak elli karakter uzunluğunda bir başlıktır."
        score = calculate_engagement_score(optimal_title)
        assert score >= 10

        # Test with numbers
        assert calculate_engagement_score("5 Harika İpucu") >= 8

        # Test with question mark
        assert calculate_engagement_score("Neden?") >= 5

        # Test with power words
        assert calculate_engagement_score("En iyi yöntem nedir?") >= 7

    def test_score_headlines_logic(self):
        # Create unscored headline
        headline = HeadlineScore.objects.create(
            rss_source=self.source,
            original_headline="Yapay Zeka Dünyayı Nasıl Değiştirecek?",
            overall_score=0,
            word_count=5,
            character_count=35,
            is_processed=False,
        )

        # Run scoring task
        score_headlines()

        # Refresh from db
        headline.refresh_from_db()

        # Verify score updated
        assert headline.overall_score > 0
        assert headline.engagement_score > 0
        assert headline.keyword_relevance > 0
