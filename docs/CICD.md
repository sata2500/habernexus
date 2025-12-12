# Habernexus CI/CD Pipeline Dokümantasyonu

Bu rehber, projenin GitHub Actions CI/CD Pipeline\ını açıklar.

---

## İçindekiler

1. [Genel Bakış](#genel-bakış)
2. [Workflow\lar](#workflowlar)
   - [CI Pipeline (ci.yml)](#ci-pipeline-ciyml)
   - [CD Pipeline (deploy.yml)](#cd-pipeline-deployyml)
   - [Security Scan (security.yml)](#security-scan-securityyml)
   - [Release (release.yml)](#release-releaseyml)
3. [Secrets ve Variables](#secrets-ve-variables)
4. [Deployment Süreci](#deployment-süreci)
5. [Troubleshooting](#troubleshooting)

---

## Genel Bakış

CI/CD Pipeline, kodun otomatik olarak test edilmesini, derlenmesini ve production ortamına deploy edilmesini sağlar.

## Workflow\lar

### CI Pipeline (ci.yml)

**Amaç:** Kodun test edilmesi, linting ve build işlemleri

**Tetikleyici:** `main` ve `develop` branch\lerine push ve pull request

**Jobs:**
- `test`: Python 3.10, 3.11, 3.12 ile testler çalıştırır
- `lint`: Kod kalitesini kontrol eder (black, isort, flake8)
- `build`: Docker image oluşturur ve test eder

### CD Pipeline (deploy.yml)

**Amaç:** Production ortamına deployment yapma

**Tetikleyici:** `v*.*.*` formatında tag push edildiğinde

**Jobs:**
- `deploy`: Google Cloud VM\e SSH ile bağlanarak deployment yapar

### Security Scan (security.yml)

**Amaç:** Güvenlik taraması yapma

**Tetikleyici:** Haftalık (Pazar günleri) ve push/pull request

**Jobs:**
- `dependency-check`: Bağımlılıkları kontrol eder (Safety)
- `bandit-scan`: Kod analizi yapar (Bandit)
- `codeql-scan`: CodeQL ile statik analiz yapar
- `secret-scan`: Gizli anahtarları tarar (TruffleHog)

### Release (release.yml)

**Amaç:** Release ve versioning otomasyonu

**Tetikleyici:** `v*.*.*` formatında tag push edildiğinde

**Jobs:**
- `create-release`: GitHub Release oluşturur ve changelog yayınlar

---

## Secrets ve Variables

| Secret | Açıklama |
|--------|----------|
| `VM_HOST` | VM IP adresi |
| `VM_USER` | VM kullanıcı adı |
| `VM_SSH_KEY` | VM SSH anahtarı |
| `DJANGO_SECRET_KEY` | Django secret key |
| `DB_PASSWORD` | Veritabanı şifresi |
| `GOOGLE_GEMINI_API_KEY` | Google Gemini API anahtarı |
| `CODECOV_TOKEN` | Codecov token |
| `SLACK_WEBHOOK` | Slack webhook URL |

| Variable | Açıklama |
|----------|----------|
| `ALLOWED_HOSTS` | İzin verilen host\lar |
| `DOMAIN` | Domain adı |
| `DB_NAME` | Veritabanı adı |
| `DB_USER` | Veritabanı kullanıcı adı |
| `DB_PORT` | Veritabanı portu |
| `CELERY_BROKER_URL` | Celery broker URL |
| `CELERY_RESULT_BACKEND` | Celery result backend URL |

---

## Deployment Süreci

1. `develop` branch\ine push yapılır
2. `ci.yml` çalışır, testler ve linting yapılır
3. `develop` branch\i `main` branch\ine merge edilir
4. `main` branch\ine `v*.*.*` formatında tag push edilir
5. `release.yml` çalışır, GitHub Release oluşturulur
6. `deploy.yml` çalışır, production ortamına deployment yapılır

---

## Troubleshooting

- **Deployment Başarısız:** GitHub Actions log\larını kontrol edin
- **Testler Başarısız:** Test raporlarını (artifact) inceleyin
- **Linting Hataları:** Kod stilini düzeltin (black, isort, flake8)
