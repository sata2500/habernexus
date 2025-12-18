# Haber Nexus - Advanced Content Generation System

**Version:** 2.0  
**Date:** December 11, 2025  
**Author:** Manus AI

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture](#architecture)
3. [Content Generation Pipeline](#content-generation-pipeline)
4. [Database Schema](#database-schema)
5. [Quality Control System](#quality-control-system)
6. [Configuration](#configuration)
7. [Monitoring and Analytics](#monitoring-and-analytics)
8. [Troubleshooting](#troubleshooting)

---

## System Overview

The Haber Nexus content generation system is a sophisticated, multi-stage pipeline that transforms RSS feed headlines into high-quality, SEO-optimized news articles using Google Gemini AI. The system incorporates intelligent quality filtering, content classification, parallel processing, and comprehensive quality metrics.

### Key Features

- **Intelligent Headline Scoring:** Filters RSS headlines based on quality, originality, and relevance
- **AI-Powered Classification:** Categorizes content into news, analysis, features, opinions, and tutorials
- **Dynamic Content Generation:** Uses specialized prompts for each content type
- **Parallel Processing:** Handles multiple articles simultaneously for improved throughput
- **Quality Metrics:** Calculates readability, SEO scores, and structural quality
- **Fact-Checking Integration:** Tracks verification status of generated content
- **Image Generation:** Creates professional, contextually relevant article images
- **Comprehensive Logging:** Tracks every step of the generation process

---

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                    RSS Feed Sources                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              [1] Feed Fetching & Parsing                    │
│                  (fetch_rss_feeds_v2)                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              [2] Headline Scoring Engine                    │
│                  (score_headlines)                          │
│  • Originality Analysis                                     │
│  • Relevance Scoring                                        │
│  • Keyword Matching                                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           [3] AI Classification Module                      │
│              (classify_headlines)                           │
│  • Content Type Detection                                   │
│  • Research Depth Determination                             │
│  • Source Reliability Assessment                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│         [4] Parallel Content Generation                     │
│            (generate_ai_content_v2)                         │
│  ├─ Research Module (research_content)                      │
│  ├─ Prompt Builder (create_dynamic_prompt)                  │
│  └─ AI Engine (call_gemini_api)                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            [5] Quality Control System                       │
│              (calculate_quality_metrics)                    │
│  ├─ Readability Analysis (Flesch-Kincaid)                   │
│  ├─ SEO Optimization Check                                  │
│  ├─ Structural Validation                                   │
│  └─ Fact-Check Status                                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            [6] Image Generation                             │
│              (generate_article_image_v2)                    │
│  • Context-Aware Image Creation                             │
│  • Professional Styling                                     │
│  • Optimization & Compression                               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            [7] Publishing & Distribution                    │
│              (publish_article)                              │
│  • Database Storage                                         │
│  • SEO Indexing                                             │
│  • Social Media Integration (optional)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Content Generation Pipeline

### Stage 1: Feed Fetching

**Task:** `news.tasks_v2.fetch_rss_feeds_v2`  
**Frequency:** Every 15 minutes  
**Function:** Fetches RSS feeds and stores raw headlines

```python
# Process
1. Iterate through active RSS sources
2. Fetch and parse RSS feed
3. Extract headline, summary, link, publish date
4. Store in HeadlineScore model
5. Log any errors
```

### Stage 2: Headline Scoring

**Task:** `news.tasks_v2.score_headlines`  
**Frequency:** Hourly  
**Function:** Evaluates and scores headlines

**Scoring Criteria:**

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Originality | 30% | Uniqueness compared to existing articles |
| Relevance | 25% | Keyword matching and category fit |
| Timeliness | 20% | Recency and news value |
| Source Quality | 15% | Source reliability rating |
| Engagement | 10% | Estimated reader interest |

**Output:** Top 10 scored headlines selected for classification

### Stage 3: Classification

**Task:** `news.tasks_v2.classify_headlines`  
**Function:** Categorizes content and determines processing parameters

**Content Types:**

| Type | Description | Research Depth | Prompt Style |
|------|-------------|-----------------|--------------|
| **news** | Breaking news, current events | Normal | Factual, concise |
| **analysis** | In-depth analysis, opinion | Deep | Analytical, detailed |
| **feature** | Human interest, profiles | Normal | Narrative, engaging |
| **opinion** | Editorial, commentary | Minimal | Opinion-based |
| **tutorial** | How-to, guides | Deep | Instructional, step-by-step |

### Stage 4: Content Generation

**Task:** `news.tasks_v2.generate_ai_content_v2`  
**Processing:** Parallel (Celery Chord)  
**Function:** Generates article content using AI

**Process:**

1. **Research Phase** (if needed)
   - Fetch additional context from web
   - Gather supporting data
   - Verify facts

2. **Prompt Generation**
   - Create dynamic prompt based on content type
   - Include author profile and style guidelines
   - Add SEO keywords and structure requirements

3. **AI Generation**
   - Call Google Gemini API
   - Generate article content
   - Extract key information

4. **Content Processing**
   - Format HTML/Markdown
   - Extract summary/excerpt
   - Generate meta description

### Stage 5: Quality Control

**Task:** `news.tasks_v2.calculate_quality_metrics`  
**Function:** Evaluates generated content quality

**Metrics Calculated:**

| Metric | Range | Target | Description |
|--------|-------|--------|-------------|
| Readability Score | 0-100 | 60+ | Flesch-Kincaid index |
| Keyword Density | 0-10% | 2-3% | Primary keyword frequency |
| Word Count | - | 800-2000 | Article length |
| Sentence Length | - | 15-20 words | Readability indicator |
| Paragraph Length | - | 3-5 sentences | Content structure |
| Heading Count | - | 3-5 | Content organization |
| Link Count | - | 3-5 | Internal/external links |
| Image Count | - | 1-3 | Visual content |

**Quality Thresholds:**

- **Excellent:** Score > 80
- **Good:** Score 60-80
- **Acceptable:** Score 40-60
- **Poor:** Score < 40

### Stage 6: Image Generation

**Task:** `news.tasks_v2.generate_article_image_v2`  
**Function:** Creates professional article images

**Features:**

- Context-aware image generation
- Professional styling and branding
- Optimization for web (WebP format)
- Responsive sizing
- Alt-text generation

### Stage 7: Publishing

**Task:** `news.tasks_v2.publish_article`  
**Function:** Publishes article to website

**Process:**

1. Verify quality metrics meet threshold
2. Check for duplicate content
3. Generate SEO metadata
4. Create URL slug
5. Save to database
6. Update search indices
7. Trigger optional social media posting

---

## Database Schema

### HeadlineScore Model

```python
class HeadlineScore(models.Model):
    rss_source = ForeignKey(RssSource)
    headline = CharField(max_length=500)
    summary = TextField()
    source_url = URLField()
    publish_date = DateTimeField()
    
    # Scoring
    originality_score = FloatField(0-100)
    relevance_score = FloatField(0-100)
    timeliness_score = FloatField(0-100)
    source_quality_score = FloatField(0-100)
    engagement_score = FloatField(0-100)
    
    # Composite
    total_score = FloatField(0-100)
    is_selected = BooleanField(default=False)
    
    # Status
    status = CharField(choices=[
        ('pending', 'Pending'),
        ('classified', 'Classified'),
        ('generated', 'Generated'),
        ('published', 'Published'),
        ('rejected', 'Rejected')
    ])
    
    created_at = DateTimeField(auto_now_add=True)
    updated_at = DateTimeField(auto_now=True)
```

### ArticleClassification Model

```python
class ArticleClassification(models.Model):
    headline_score = ForeignKey(HeadlineScore)
    article_type = CharField(choices=[
        ('news', 'News'),
        ('analysis', 'Analysis'),
        ('feature', 'Feature'),
        ('opinion', 'Opinion'),
        ('tutorial', 'Tutorial')
    ])
    
    research_depth = IntegerField(choices=[
        (0, 'Minimal'),
        (1, 'Normal'),
        (2, 'Deep')
    ])
    
    source_reliability = FloatField(0-1)
    ai_model = CharField(max_length=50)
    prompt_template = TextField()
    
    classification_confidence = FloatField(0-1)
    
    created_at = DateTimeField(auto_now_add=True)
```

### ContentQualityMetrics Model

```python
class ContentQualityMetrics(models.Model):
    article = ForeignKey(Article)
    
    # Readability
    readability_score = FloatField()
    flesch_kincaid_grade = FloatField()
    average_sentence_length = FloatField()
    average_word_length = FloatField()
    
    # SEO
    keyword_density = FloatField()
    heading_count = IntegerField()
    link_count = IntegerField()
    image_count = IntegerField()
    
    # Structure
    word_count = IntegerField()
    paragraph_count = IntegerField()
    list_count = IntegerField()
    
    # Overall
    quality_score = FloatField(0-100)
    quality_grade = CharField(choices=[
        ('A', 'Excellent'),
        ('B', 'Good'),
        ('C', 'Acceptable'),
        ('D', 'Poor')
    ])
    
    created_at = DateTimeField(auto_now_add=True)
```

### ContentGenerationLog Model

```python
class ContentGenerationLog(models.Model):
    article = ForeignKey(Article, null=True)
    headline_score = ForeignKey(HeadlineScore)
    
    stage = CharField(choices=[
        ('fetching', 'Fetching'),
        ('scoring', 'Scoring'),
        ('classification', 'Classification'),
        ('generation', 'Generation'),
        ('quality_check', 'Quality Check'),
        ('image_generation', 'Image Generation'),
        ('publishing', 'Publishing')
    ])
    
    status = CharField(choices=[
        ('started', 'Started'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('failed', 'Failed')
    ])
    
    message = TextField()
    error_message = TextField(null=True)
    execution_time = FloatField(null=True)
    
    created_at = DateTimeField(auto_now_add=True)
```

---

## Quality Control System

### Quality Scoring Algorithm

```python
def calculate_quality_score(article):
    """
    Calculate comprehensive quality score
    """
    scores = {
        'readability': calculate_readability(article.content),
        'seo': calculate_seo_score(article),
        'structure': calculate_structure_score(article),
        'originality': calculate_originality(article),
        'engagement': calculate_engagement_score(article)
    }
    
    weights = {
        'readability': 0.25,
        'seo': 0.25,
        'structure': 0.20,
        'originality': 0.20,
        'engagement': 0.10
    }
    
    total_score = sum(
        scores[key] * weights[key] 
        for key in scores
    )
    
    return total_score
```

### Quality Thresholds

| Threshold | Action |
|-----------|--------|
| Score ≥ 80 | Auto-publish |
| Score 60-79 | Publish with review flag |
| Score 40-59 | Requires manual review |
| Score < 40 | Reject and log |

---

## Configuration

### Environment Variables

```ini
# Content Generation
CONTENT_MIN_QUALITY_SCORE=60
CONTENT_MAX_WORD_COUNT=2000
CONTENT_MIN_WORD_COUNT=800
CONTENT_TARGET_READABILITY=60

# AI Settings
GEMINI_API_KEY=your_api_key
GEMINI_MODEL=gemini-2.5-flash
GEMINI_TEMPERATURE=0.7
GEMINI_MAX_TOKENS=2000

# Processing
PARALLEL_GENERATION_WORKERS=5
HEADLINE_BATCH_SIZE=10
QUALITY_CHECK_ENABLED=True

# Scheduling
RSS_FETCH_INTERVAL_MINUTES=15
HEADLINE_SCORE_INTERVAL_MINUTES=60
CLASSIFICATION_INTERVAL_MINUTES=30
```

### Celery Configuration

```python
# habernexus_config/celery.py

app.conf.beat_schedule = {
    'fetch-rss-feeds': {
        'task': 'news.tasks_v2.fetch_rss_feeds_v2',
        'schedule': crontab(minute='*/15'),
    },
    'score-headlines': {
        'task': 'news.tasks_v2.score_headlines',
        'schedule': crontab(minute=0),
    },
    'classify-headlines': {
        'task': 'news.tasks_v2.classify_headlines',
        'schedule': crontab(minute='*/30'),
    },
}
```

---

## Monitoring and Analytics

### Key Metrics to Track

```python
# Daily metrics
- Headlines fetched
- Headlines scored
- Articles generated
- Articles published
- Average quality score
- Average generation time

# Weekly metrics
- Total content produced
- Quality distribution
- Error rate
- Processing efficiency
- API usage and costs

# Monthly metrics
- Content trends
- Performance improvements
- System reliability
- User engagement metrics
```

### Admin Dashboard

Access monitoring data in Django Admin:

1. **Headline Scores:** View all scored headlines
2. **Article Classifications:** See content categorization
3. **Content Quality Metrics:** Detailed quality analysis
4. **Generation Logs:** Complete process tracking

### Performance Optimization

```python
# Database Indexes
- HeadlineScore: (status, total_score, created_at)
- Article: (status, published_at, quality_score)
- ContentGenerationLog: (article_id, stage, status)

# Caching
- Cache headline scores for 1 hour
- Cache quality metrics for 24 hours
- Cache classification results for 6 hours
```

---

## Troubleshooting

### Common Issues

#### 1. Low Quality Scores

**Symptoms:** Most generated articles score below 60

**Solutions:**
- Review and adjust quality calculation weights
- Check GEMINI_TEMPERATURE setting (lower = more consistent)
- Verify prompt templates are appropriate
- Check source data quality

#### 2. Slow Content Generation

**Symptoms:** Articles taking > 5 minutes to generate

**Solutions:**
```bash
# Increase parallel workers
PARALLEL_GENERATION_WORKERS=10

# Check Celery worker status
celery -A habernexus_config inspect active

# Monitor API response times
docker-compose logs celery | grep "API call"
```

#### 3. Classification Failures

**Symptoms:** Articles not being classified correctly

**Solutions:**
- Verify Gemini API key is valid
- Check network connectivity
- Review classification prompt in admin
- Check error logs in ContentGenerationLog

#### 4. Image Generation Issues

**Symptoms:** Articles published without images

**Solutions:**
- Verify image generation is enabled
- Check API quotas
- Review image generation logs
- Manually trigger: `generate_article_image_v2.delay(article_id)`

### Debug Mode

Enable detailed logging:

```python
# In settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'DEBUG',
            'class': 'logging.FileHandler',
            'filename': 'content_generation.log',
        },
    },
    'loggers': {
        'news.tasks_v2': {
            'handlers': ['file'],
            'level': 'DEBUG',
        },
    },
}
```

---

## Advanced Topics

### Custom Prompt Templates

Create specialized prompts for different content types:

```python
PROMPT_TEMPLATES = {
    'news': """
    Write a breaking news article about: {headline}
    Style: Factual, timely, concise
    Word count: 800-1000
    Include: Who, What, When, Where, Why
    """,
    'analysis': """
    Write an in-depth analysis about: {headline}
    Style: Analytical, detailed, authoritative
    Word count: 1500-2000
    Include: Background, Analysis, Implications, Conclusion
    """,
}
```

### Custom Quality Metrics

Implement domain-specific quality checks:

```python
def calculate_domain_specific_quality(article):
    """
    Add custom quality checks for your domain
    """
    score = 0
    
    # Check for required sections
    if 'Introduction' in article.content:
        score += 10
    
    # Check for citations
    citation_count = article.content.count('[')
    score += min(citation_count * 5, 20)
    
    return score
```

---

## Performance Targets

**Goal:** Generate 10 high-quality articles every 2 hours

| Metric | Target | Current |
|--------|--------|---------|
| Headlines fetched per 15 min | 50+ | - |
| Headlines scored per hour | 100+ | - |
| Articles generated per hour | 5+ | - |
| Average generation time | < 2 min | - |
| Quality score average | > 75 | - |
| Success rate | > 95% | - |

---

## Support and Resources

- **Email:** salihtanriseven25@gmail.com
- **GitHub Issues:** https://github.com/sata2500/habernexus/issues
- **Documentation:** See `docs/` folder
