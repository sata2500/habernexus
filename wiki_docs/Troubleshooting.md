## HaberNexus Troubleshooting Guide

This guide contains common problems that may be encountered during the installation and use of HaberNexus and their solutions.

---

### Installation Issues

#### Problem: The `get-habernexus.sh` script is giving an error.

-   **Solution 1: Check Permissions**
    Make sure the script is run with `sudo` privileges:
    ```bash
    curl ... | sudo bash
    ```

-   **Solution 2: Dependencies**
    Make sure that basic packages such as `curl` and `git` are installed on your system. The script tries to install most of them, but deficiencies can cause problems.

-   **Solution 3: Review Logs**
    The logs generated during installation are usually saved to the `/tmp/habernexus_install.log` file. You can identify the source of the error by examining this file.

#### Problem: "port is already allocated" error when starting Docker Compose.

-   **Explanation:** This error means that ports such as `80` or `443` are being used by another service (e.g., Apache, Nginx).
-   **Solution:** Stop or remove the service using the port.
    ```bash
    # Find out which service is using the port
    sudo lsof -i :80
    sudo lsof -i :443

    # Example: Stopping Apache
    sudo systemctl stop apache2
    sudo systemctl disable apache2
    ```

### Application Runtime Issues

#### Problem: The site is not opening, I am getting a "502 Bad Gateway" error.

-   **Explanation:** This usually means that the Caddy reverse proxy cannot reach the Django application behind it (the app service).

-   **Solution 1: Check the Status of the Services**
    Make sure all Docker containers are running.
    ```bash
    docker compose ps
    ```
    If one of the `app`, `postgres`, or `redis` services is not in the `running` state, examine its logs:
    ```bash
    docker compose logs app
    ```

-   **Solution 2: Database Connection**
    Check the logs of the `app` service for a database connection error. Make sure that the variables starting with `DB_` in the `.env` file are configured correctly.

-   **Solution 3: Run Migrations**
    The database schema may not be up to date. Run the migrations manually:
    ```bash
    docker compose exec app python manage.py migrate
    ```

#### Problem: News is not updating, no new content is coming.

-   **Explanation:** This problem is usually caused by the Celery services (worker or beat) not working properly.

-   **Solution 1: Check Celery Services**
    Check if the `celery` and `celery-beat` containers are running.
    ```bash
    docker compose ps
    ```

-   **Solution 2: Review Celery Logs**
    Check the service logs for errors. Redis connection errors are especially common.
    ```bash
    docker compose logs celery
    docker compose logs celery-beat
    ```

-   **Solution 3: Check RSS Sources**
    Go to the **News > RSS Sources** section from the Django admin panel. Make sure the sources are `active` and their URLs are correct.

### Development Issues

#### Problem: I am getting database errors when running `pytest`.

-   **Explanation:** A separate test database is created for the tests. Sometimes permission issues or configuration deficiencies can cause this error.
-   **Solution:** Check if you have a special configuration for the test database in your `.env` file. Usually, the main database user needs to have permission to create new databases.

#### Problem: Static files (CSS, JS) are not loading or updating.

-   **Solution 1: Run the `collectstatic` Command**
    Django needs to collect static files in a single directory.
    ```bash
    docker compose exec app python manage.py collectstatic --noinput
    ```

-   **Solution 2: Clear the Browser Cache**
    Your browser may be loading old files from the cache. Refresh the page with `Ctrl + Shift + R` (or `Cmd + Shift + R`) to bypass the cache.

-   **Solution 3: Tailwind CSS Compilation**
    If you have made changes to the `tailwind.config.js` file or `css` files, Tailwind needs to recompile the CSS. This is usually automatic in the development environment, but if you have problems, you can run the following command:
    ```bash
    docker compose exec app python manage.py tailwind build
    ```
