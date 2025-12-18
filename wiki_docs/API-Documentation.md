## HaberNexus REST API Documentation

HaberNexus provides a comprehensive REST API that allows programmatic access to all project features. This document explains how to use the API, its endpoints, and data models.

---

### API Access and Documentation

You can access the interactive documentation for the API at the following addresses:

-   **Swagger UI:** `/api/docs/`
-   **ReDoc:** `/api/redoc/`

Through these interfaces, you can test all endpoints and review the schemas.

### Base URL

All API requests are made through the following base URL:

`https://habernexus.com/api/v1/`

### Authentication

The API includes endpoints that are public and those that require admin privileges. Admin endpoints require `IsAdminUser` permission, which is provided through users created in the Django admin panel. A JWT-based authentication system is planned for the future.

---

## Usage Examples

Below are `cURL` and `Python` examples of how to use the API.

### Example 1: Listing All Articles

**cURL:**
```bash
curl -X GET https://habernexus.com/api/v1/articles/
```

**Python (`requests` library):**
```python
import requests

response = requests.get("https://habernexus.com/api/v1/articles/")

if response.status_code == 200:
    data = response.json()
    for article in data["results"]:
        print(article["title"])
else:
    print(f"Error: {response.status_code}")
```

### Example 2: Getting the Details of a Single Article

**cURL:**
```bash
curl -X GET https://habernexus.com/api/v1/articles/artificial-intelligence-is-reshaping-art/
```

**Python:**
```python
import requests

slug = "artificial-intelligence-is-reshaping-art"
response = requests.get(f"https://habernexus.com/api/v1/articles/{slug}/")

if response.status_code == 200:
    article_details = response.json()
    print(article_details["content"])
```

### Example 3: Searching within Articles

**cURL:**
```bash
curl -X GET "https://habernexus.com/api/v1/articles/search/?q=technology"
```

**Python:**
```python
import requests

params = {
    "q": "technology"
}

response = requests.get("https://habernexus.com/api/v1/articles/search/", params=params)

if response.status_code == 200:
    search_results = response.json()
    print(f"{len(search_results["results"])} results found.")
```

---

## Main Endpoints

### Articles

-   **Endpoint:** `/articles/`
-   **Methods:** `GET`
-   **Description:** Lists all published articles. Supports pagination.

#### Article Detail

-   **Endpoint:** `/articles/{slug}/`
-   **Method:** `GET`
-   **Description:** Retrieves the details of a single article with the specified `slug`.

#### Article Search

-   **Endpoint:** `/articles/search/`
-   **Method:** `GET`
-   **Parameters:**
    -   `q` (required): The text to search for (minimum 2 characters).
-   **Description:** Searches within the article title, content, and tags.

### Authors

-   **Endpoint:** `/authors/`
-   **Methods:** `GET`
-   **Description:** Lists all active authors.

#### Author Detail

-   **Endpoint:** `/authors/{slug}/`
-   **Method:** `GET`
-   **Description:** Retrieves the information of the author with the specified `slug`.

#### Author's Articles

-   **Endpoint:** `/authors/{slug}/articles/`
-   **Method:** `GET`
-   **Description:** Lists all articles by the specified author.

### Categories

-   **Endpoint:** `/categories/`
-   **Method:** `GET`
-   **Description:** Lists all categories and the number of articles in each category.

### Stats

-   **Endpoint:** `/stats/`
-   **Method:** `GET`
-   **Description:** Returns general statistics about the site (total articles, views, number of authors, etc.).

### RSS Sources - *Admin Privileges Required*

-   **Endpoint:** `/rss-sources/`
-   **Methods:** `GET`, `POST`, `PUT`, `PATCH`, `DELETE`
-   **Description:** Used to manage RSS sources. Only administrators can access it.

### Health Check

-   **Endpoint:** `/health/`
-   **Method:** `GET`
-   **Description:** Used to check if the API and the system are running healthily.

---

## Data Models (Serializers)

### ArticleListSerializer

```json
{
  "url": "string",
  "title": "string",
  "slug": "string",
  "excerpt": "string",
  "featured_image": "string (URL)",
  "category": "string",
  "tags": "string",
  "author": {
    "name": "string",
    "slug": "string"
  },
  "published_at": "datetime"
}
```

### ArticleDetailSerializer

In addition to the `ArticleListSerializer` fields:

```json
{
  "content": "string (HTML)",
  "views_count": "integer",
  "is_ai_generated": "boolean"
}
```

### AuthorSerializer

```json
{
  "name": "string",
  "slug": "string",
  "bio": "string",
  "avatar": "string (URL)",
  "expertise": "string"
}
```
