# Haber Nexus - API Documentation

**Version:** 1.0  
**Last Updated:** December 11, 2025

---

## Table of Contents

1. [Introduction](#introduction)
2. [Authentication](#authentication)
3. [Rate Limiting](#rate-limiting)
4. [Endpoints](#endpoints)
   - [Articles](#articles)
   - [Categories](#categories)
   - [Authors](#authors)
   - [Tags](#tags)
   - [Search](#search)
   - [Sitemap](#sitemap)
5. [Error Codes](#error-codes)
6. [Future Development](#future-development)

---

## Introduction

Welcome to the Haber Nexus API documentation. This document provides a detailed overview of the available API endpoints, request/response formats, and authentication mechanisms.

**Base URL:** `https://habernexus.com/`

---

## Authentication

Currently, the API is public and does not require authentication for read-only operations. Future versions will implement API key-based authentication for write operations.

---

## Rate Limiting

To ensure fair usage, the API is rate-limited to **100 requests per minute** per IP address. Exceeding this limit will result in a `429 Too Many Requests` error.

---

## Endpoints

### Articles

#### Get a list of articles

- **Endpoint:** `/haberler/`
- **Method:** `GET`
- **Description:** Retrieves a paginated list of published articles.
- **Query Parameters:**
  - `page` (integer, optional): The page number to retrieve.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with a list of articles`

#### Get a single article

- **Endpoint:** `/haber/<slug>/`
- **Method:** `GET`
- **Description:** Retrieves a single article by its slug.
- **URL Parameters:**
  - `slug` (string, required): The slug of the article.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with the article details`
- **Error Response:**
  - **Code:** 404 Not Found

### Categories

#### Get articles by category

- **Endpoint:** `/kategori/<category>/`
- **Method:** `GET`
- **Description:** Retrieves a list of articles belonging to a specific category.
- **URL Parameters:**
  - `category` (string, required): The name of the category.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with a list of articles in the category`

### Authors

#### Get articles by author

- **Endpoint:** `/yazar/<slug>/`
- **Method:** `GET`
- **Description:** Retrieves a list of articles written by a specific author.
- **URL Parameters:**
  - `slug` (string, required): The slug of the author.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with the author's details and a list of their articles`

### Tags

#### Get articles by tag

- **Endpoint:** `/etiket/<tag>/`
- **Method:** `GET`
- **Description:** Retrieves a list of articles associated with a specific tag.
- **URL Parameters:**
  - `tag` (string, required): The slug of the tag.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with a list of articles for the tag`

### Search

#### Search for articles

- **Endpoint:** `/ara/`
- **Method:** `GET`
- **Description:** Searches for articles based on a query.
- **Query Parameters:**
  - `q` (string, required): The search query.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `HTML page with search results`

### Sitemap

#### Get the sitemap

- **Endpoint:** `/sitemap.xml`
- **Method:** `GET`
- **Description:** Retrieves the XML sitemap for the website.
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** `XML sitemap`

---

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 404 | Not Found | The requested resource could not be found. |
| 429 | Too Many Requests | You have exceeded the rate limit. |
| 500 | Internal Server Error | An unexpected error occurred on the server. |

---

## Future Development

The current URL structure serves HTML pages. A future version of the API will be developed to provide JSON responses, following RESTful principles. The proposed API structure is as follows:

**Base URL:** `/api/v1/`

### Proposed Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/articles/` | `GET` | Get a list of articles |
| `/api/v1/articles/<id>/` | `GET` | Get a single article |
| `/api/v1/articles/` | `POST` | Create a new article (admin) |
| `/api/v1/articles/<id>/` | `PUT` | Update an article (admin) |
| `/api/v1/articles/<id>/` | `DELETE` | Delete an article (admin) |
| `/api/v1/categories/` | `GET` | Get a list of categories |
| `/api/v1/authors/` | `GET` | Get a list of authors |
| `/api/v1/tags/` | `GET` | Get a list of tags |

This new API will be implemented using Django REST Framework and will include features such as:

- API key authentication
- JWT support
- Comprehensive filtering and sorting
- Detailed error messages
- OpenAPI/docs/api/ for interactive documentation (Swagger/OpenAPI) interactive documentation)
