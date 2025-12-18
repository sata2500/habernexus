## HaberNexus Developer Guide

This guide is for developers who want to contribute to the HaberNexus project. It contains everything you need to know about coding standards, testing processes, commit message formats, and the Pull Request (PR) process.

Every contribution you make to the project is valuable. Before you start, we ask that you carefully read this guide and the `CONTRIBUTING.md` file in the project's root directory.

---

### 🚀 Getting Started

1.  **Fork the Project:** Create a copy of the project in your own GitHub account.
2.  **Clone it:** Clone the forked repository to your local machine.
    ```bash
    git clone https://github.com/YOUR_USERNAME/habernexus.git
    ```
3.  **Set up the Development Environment:** Prepare your local development environment by following the steps in the **[Installation Guide](Installation-Guide)**.

### 🌿 Branch Management

All development must be done on new branches created from the `main` branch. Committing directly to the `main` branch is not allowed.

-   **For New Features:**
    ```bash
    git checkout -b feature/new-feature-name
    ```
-   **For Bug Fixes:**
    ```bash
    git checkout -b fix/fixed-bug-name
    ```
-   **For Documentation Changes:**
    ```bash
    git checkout -b docs/updated-document-name
    ```

### ✍️ Coding Standards

To ensure a consistent and readable codebase in the project, it is mandatory to adhere to the following standards.

-   **Code Formatting:** All Python code must be formatted with `black`.
-   **Import Sorting:** Imports must be automatically sorted with `isort`.
-   **Code Quality:** The `ruff` tool is used to check code quality and style. Before committing, run the `ruff .` command to check for any errors or warnings.
-   **Type Hinting:** Python's type hints should be used wherever possible (function parameters, return values). This makes the code more understandable and sustainable.
-   **Docstrings:** Descriptive docstrings should be written for all modules, classes, and functions. Google-style docstring format is preferred.

### ✅ Testing Processes

Every new feature added or every bug fix made must be verified with tests.

-   **Running Tests:**
    ```bash
    pytest
    ```
-   **Checking Test Coverage:**
    ```bash
    pytest --cov=.
    ```
    Make sure that the changes made do not reduce the test coverage. Unit or integration tests must be written for new code.

### 💬 Commit Message Format

The **Conventional Commits** standard is used in the project. This allows the `CHANGELOG.md` file to be automatically generated and makes it easier to track changes.

**Format:** `<type>(<scope>): <description>`

-   **Types:**
    -   `feat`: When a new feature is added.
    -   `fix`: When a bug is fixed.
    -   `docs`: When only documentation is changed.
    -   `style`: Formatting changes that do not affect the meaning of the code (spaces, punctuation, etc.).
    -   `refactor`: Restructuring work that does not change the functionality of the code.
    -   `test`: Adding missing tests or correcting existing tests.
    -   `chore`: Changes that affect the development process, such as updating dependencies, CI/CD configuration.

-   **Sample Commit Messages:**
    ```
    feat(api): Add search functionality to articles endpoint
    fix(news): Correctly handle timezone conversion for published_at field
    docs(readme): Update installation instructions
    ```

### 🔄 Pull Request (PR) Process

1.  After completing and committing your changes, push your branch to your forked repository:
    ```bash
    git push origin feature/new-feature-name
    ```
2.  Open a Pull Request to the `main` branch of the `sata2500/habernexus` repository via GitHub.
3.  In the PR description, explain the changes you have made in detail. If there is a relevant issue number (such as `Closes #123`), specify it.
4.  Your PR will automatically trigger the CI/CD pipeline. Make sure that the tests and code quality checks pass successfully.
5.  Wait for the review by the project managers. If there is feedback, make the necessary corrections.
6.  Once your PR is approved, it will be merged into the `main` branch.
