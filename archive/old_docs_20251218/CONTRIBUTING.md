# Contributing to Haber Nexus

Thank you for your interest in contributing to Haber Nexus! This document provides guidelines and instructions for contributing to the project.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing](#testing)
6. [Commit Messages](#commit-messages)
7. [Pull Request Process](#pull-request-process)
8. [Reporting Issues](#reporting-issues)
9. [Documentation](#documentation)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Help others learn and grow
- Report inappropriate behavior

---

## Getting Started

### Prerequisites

- Python 3.11+
- Docker and Docker Compose
- Git
- GitHub account

### Setup Development Environment

```bash
# 1. Fork the repository
# Visit https://github.com/sata2500/habernexus and click "Fork"

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/habernexus.git
cd habernexus

# 3. Add upstream remote
git remote add upstream https://github.com/sata2500/habernexus.git

# 4. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 5. Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Development dependencies

# 6. Setup database
cp .env.example .env
python manage.py migrate

# 7. Create superuser
python manage.py createsuperuser

# 8. Start development server
python manage.py runserver
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
# or for bug fixes
git checkout -b bugfix/issue-description
```

### Branch Naming Convention

- `feature/feature-name` - New features
- `bugfix/bug-description` - Bug fixes
- `docs/documentation-update` - Documentation updates
- `refactor/refactoring-description` - Code refactoring
- `test/test-description` - Test additions

### 2. Make Changes

```bash
# Edit files
# Test changes locally
python manage.py test

# Check code quality
flake8 .
black --check .
isort --check-only .
```

### 3. Commit Changes

```bash
git add .
git commit -m "feat: Add new feature description"
```

### 4. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 5. Create Pull Request

- Go to GitHub
- Click "Compare & pull request"
- Fill in the PR template
- Submit for review

---

## Coding Standards

### Python Style Guide

We follow PEP 8 with some modifications:

```python
# Good
def fetch_rss_feeds(source_id: int) -> List[Article]:
    """
    Fetch RSS feeds from the specified source.
    
    Args:
        source_id: The ID of the RSS source
        
    Returns:
        List of Article objects
        
    Raises:
        RssSourceNotFound: If the source doesn't exist
    """
    source = RssSource.objects.get(id=source_id)
    articles = []
    
    for item in source.fetch_items():
        article = Article(
            title=item.title,
            content=item.description,
            source=source
        )
        articles.append(article)
    
    return articles


# Bad
def fetch_rss_feeds(source_id):
    source = RssSource.objects.get(id=source_id)
    articles = []
    for item in source.fetch_items():
        articles.append(Article(title=item.title, content=item.description, source=source))
    return articles
```

### Code Formatting

```bash
# Format code with black
black .

# Sort imports with isort
isort .

# Check code quality with flake8
flake8 .

# Check type hints with mypy
mypy .
```

### Django Best Practices

```python
# Models
class Article(models.Model):
    """Article model for news content."""
    
    title = models.CharField(max_length=200)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return self.title


# Views
from django.views.generic import ListView
from django.contrib.auth.mixins import LoginRequiredMixin

class ArticleListView(LoginRequiredMixin, ListView):
    """Display list of articles."""
    
    model = Article
    paginate_by = 20
    context_object_name = 'articles'
    
    def get_queryset(self):
        return Article.objects.filter(status='published')


# Celery Tasks
from celery import shared_task

@shared_task(bind=True, max_retries=3)
def fetch_rss_feeds(self):
    """Fetch RSS feeds and create articles."""
    try:
        # Task logic
        pass
    except Exception as exc:
        self.retry(exc=exc, countdown=60)
```

### Documentation Strings

```python
def calculate_quality_score(article: Article) -> float:
    """
    Calculate the quality score of an article.
    
    This function analyzes multiple aspects of the article including
    readability, SEO optimization, and structural quality.
    
    Args:
        article: The Article object to analyze
        
    Returns:
        A float between 0 and 100 representing the quality score
        
    Raises:
        ValueError: If the article content is empty
        
    Example:
        >>> article = Article.objects.get(id=1)
        >>> score = calculate_quality_score(article)
        >>> print(f"Quality score: {score}")
        Quality score: 85.5
    """
    if not article.content:
        raise ValueError("Article content cannot be empty")
    
    # Calculate score
    return score
```

---

## Testing

### Running Tests

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test news

# Run specific test class
python manage.py test news.tests.ArticleTestCase

# Run with coverage
coverage run --source='.' manage.py test
coverage report
coverage html
```

### Writing Tests

```python
from django.test import TestCase
from news.models import Article, RssSource

class ArticleTestCase(TestCase):
    """Test cases for Article model."""
    
    def setUp(self):
        """Set up test data."""
        self.source = RssSource.objects.create(
            name='Test Source',
            url='https://example.com/rss'
        )
        self.article = Article.objects.create(
            title='Test Article',
            content='Test content',
            source=self.source
        )
    
    def test_article_creation(self):
        """Test that article is created correctly."""
        self.assertEqual(self.article.title, 'Test Article')
        self.assertEqual(self.article.source, self.source)
    
    def test_article_string_representation(self):
        """Test article __str__ method."""
        self.assertEqual(str(self.article), 'Test Article')
    
    def test_article_slug_generation(self):
        """Test that slug is generated from title."""
        self.assertIsNotNone(self.article.slug)
        self.assertIn('test-article', self.article.slug)
```

### Test Coverage Target

- **Minimum:** 70% code coverage
- **Target:** 80%+ code coverage
- **Critical paths:** 100% coverage

---

## Commit Messages

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat` - A new feature
- `fix` - A bug fix
- `docs` - Documentation only changes
- `style` - Changes that don't affect code meaning (formatting, etc.)
- `refactor` - Code change that neither fixes a bug nor adds a feature
- `perf` - Code change that improves performance
- `test` - Adding missing tests or correcting existing tests
- `chore` - Changes to build process, dependencies, etc.

### Examples

```bash
# Feature
git commit -m "feat(content): Add AI-powered headline scoring system"

# Bug fix
git commit -m "fix(celery): Resolve task timeout issue in content generation"

# Documentation
git commit -m "docs(installation): Update Docker setup instructions"

# Performance
git commit -m "perf(database): Add indexes to improve query performance"
```

---

## Pull Request Process

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally
- [ ] No breaking changes
```

### Review Process

1. **Automated Checks**
   - Tests must pass
   - Code coverage must not decrease
   - Linting must pass

2. **Code Review**
   - At least one maintainer review required
   - Constructive feedback provided
   - Changes requested addressed

3. **Approval and Merge**
   - Approved by maintainer
   - All conversations resolved
   - Merged to main branch

---

## Reporting Issues

### Issue Template

```markdown
## Description
Clear description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Ubuntu 22.04]
- Python: [e.g., 3.11]
- Django: [e.g., 5.0]

## Additional Context
Any additional information
```

### Issue Types

- **Bug Report:** Report a bug
- **Feature Request:** Suggest a new feature
- **Documentation:** Documentation improvements
- **Question:** Ask a question

---

## Documentation

### Documentation Standards

- Use clear, concise language
- Include code examples
- Add table of contents for long documents
- Use proper markdown formatting
- Keep documentation up-to-date

### Documentation Structure

```markdown
# Title

## Table of Contents

## Overview

## Prerequisites

## Step-by-Step Guide

## Examples

## Troubleshooting

## Additional Resources
```

### Documentation Locations

- **User Guides:** `docs/`
- **API Documentation:** `docs/API.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **Development:** `docs/DEVELOPMENT.md`
- **Inline Code Comments:** In source files

---

## Development Tools

### Recommended Tools

- **IDE:** VS Code, PyCharm, or similar
- **Version Control:** Git
- **Testing:** pytest, Django TestCase
- **Code Quality:** flake8, black, isort, mypy
- **Documentation:** Sphinx (optional)

### Useful Commands

```bash
# Format code
black .
isort .

# Check code quality
flake8 .
mypy .
pylint .

# Run tests
pytest
coverage run -m pytest
coverage report

# Build documentation
sphinx-build -b html docs _build/html
```

---

## Getting Help

- **Questions:** Open a GitHub Discussion
- **Bugs:** Open a GitHub Issue
- **Email:** salihtanriseven25@gmail.com
- **Documentation:** See `docs/` folder

---

## Recognition

Contributors will be recognized in:
- `CONTRIBUTORS.md` file
- GitHub contributors page
- Release notes

---

## License

By contributing, you agree that your contributions will be licensed under the project's license.

---

Thank you for contributing to Haber Nexus! 🎉
