"""
HaberNexus v6.0 Admin Dashboard
Provides system status, monitoring, and configuration management
"""

import os
from datetime import datetime

from django.contrib.auth.decorators import login_required, user_passes_test
from django.http import JsonResponse
from django.shortcuts import render
from django.views.decorators.http import require_http_methods

import docker


def is_admin(user):
    """Check if user is admin"""
    return user.is_staff and user.is_superuser


@login_required
@user_passes_test(is_admin)
def dashboard(request):
    """Main admin dashboard"""
    context = {
        "page_title": "Admin Dashboard",
        "services_status": get_services_status(),
        "system_health": get_system_health(),
        "ssl_status": get_ssl_status(),
        "tunnel_status": get_tunnel_status(),
        "recent_logs": get_recent_logs(),
    }
    return render(request, "admin/dashboard.html", context)


def get_services_status():
    """Get status of all Docker services"""
    try:
        client = docker.from_env()
        containers = client.containers.list(all=True)

        services = {}
        for container in containers:
            if "habernexus" in container.name:
                services[container.name] = {
                    "status": container.status,
                    "state": container.state,
                    "health": container.attrs.get("State", {}).get("Health", {}).get("Status", "unknown"),
                    "image": container.image.tags[0] if container.image.tags else "unknown",
                    "created": container.attrs["Created"],
                }

        return services
    except Exception as e:
        return {"error": str(e)}


def get_system_health():
    """Get system health metrics"""
    try:
        import psutil

        health = {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "memory": psutil.virtual_memory()._asdict(),
            "disk": psutil.disk_usage("/")._asdict(),
            "timestamp": datetime.now().isoformat(),
        }

        return health
    except Exception as e:
        return {"error": str(e)}


def get_ssl_status():
    """Get SSL certificate status"""
    try:
        # Check Caddy certificate
        caddy_certs_path = "/data/caddy/certificates"

        if os.path.exists(caddy_certs_path):
            certs = []
            for root, dirs, files in os.walk(caddy_certs_path):
                for file in files:
                    if file.endswith(".crt"):
                        cert_path = os.path.join(root, file)
                        certs.append(
                            {
                                "path": cert_path,
                                "modified": datetime.fromtimestamp(os.path.getmtime(cert_path)).isoformat(),
                            }
                        )

            return {
                "certificates": certs,
                "status": "active" if certs else "none",
            }
        else:
            return {"status": "pending", "message": "Waiting for certificate"}
    except Exception as e:
        return {"error": str(e)}


def get_tunnel_status():
    """Get Cloudflare Tunnel status"""
    try:
        # Check if cloudflared is running
        client = docker.from_env()
        tunnel_container = client.containers.get("habernexus_cloudflared")

        return {
            "status": tunnel_container.status,
            "health": tunnel_container.attrs.get("State", {}).get("Health", {}).get("Status", "unknown"),
            "uptime": tunnel_container.attrs["State"]["StartedAt"],
        }
    except Exception as e:
        return {"error": str(e), "status": "unknown"}


def get_recent_logs(lines=50):
    """Get recent system logs"""
    try:
        logs = []
        client = docker.from_env()

        containers = client.containers.list(all=True)
        for container in containers:
            if "habernexus" in container.name:
                try:
                    container_logs = container.logs(tail=lines).decode("utf-8")
                    logs.append(
                        {
                            "container": container.name,
                            "logs": container_logs.split("\n")[-lines:],
                        }
                    )
                except Exception:
                    pass

        return logs
    except Exception as e:
        return [{"error": str(e)}]


@login_required
@user_passes_test(is_admin)
@require_http_methods(["GET"])
def api_services_status(request):
    """API endpoint for services status"""
    return JsonResponse(get_services_status())


@login_required
@user_passes_test(is_admin)
@require_http_methods(["GET"])
def api_system_health(request):
    """API endpoint for system health"""
    return JsonResponse(get_system_health())


@login_required
@user_passes_test(is_admin)
@require_http_methods(["GET"])
def api_ssl_status(request):
    """API endpoint for SSL status"""
    return JsonResponse(get_ssl_status())


@login_required
@user_passes_test(is_admin)
@require_http_methods(["GET"])
def api_tunnel_status(request):
    """API endpoint for tunnel status"""
    return JsonResponse(get_tunnel_status())


@login_required
@user_passes_test(is_admin)
@require_http_methods(["GET"])
def api_logs(request):
    """API endpoint for logs"""
    lines = request.GET.get("lines", 50)
    return JsonResponse({"logs": get_recent_logs(int(lines))})


@login_required
@user_passes_test(is_admin)
@require_http_methods(["POST"])
def restart_service(request):
    """Restart a service"""
    service_name = request.POST.get("service")

    try:
        client = docker.from_env()
        container = client.containers.get(service_name)
        container.restart()

        return JsonResponse(
            {
                "success": True,
                "message": f"Service {service_name} restarted",
            }
        )
    except Exception as e:
        return JsonResponse(
            {
                "success": False,
                "error": str(e),
            },
            status=400,
        )


@login_required
@user_passes_test(is_admin)
@require_http_methods(["POST"])
def stop_service(request):
    """Stop a service"""
    service_name = request.POST.get("service")

    try:
        client = docker.from_env()
        container = client.containers.get(service_name)
        container.stop()

        return JsonResponse(
            {
                "success": True,
                "message": f"Service {service_name} stopped",
            }
        )
    except Exception as e:
        return JsonResponse(
            {
                "success": False,
                "error": str(e),
            },
            status=400,
        )


@login_required
@user_passes_test(is_admin)
@require_http_methods(["POST"])
def start_service(request):
    """Start a service"""
    service_name = request.POST.get("service")

    try:
        client = docker.from_env()
        container = client.containers.get(service_name)
        container.start()

        return JsonResponse(
            {
                "success": True,
                "message": f"Service {service_name} started",
            }
        )
    except Exception as e:
        return JsonResponse(
            {
                "success": False,
                "error": str(e),
            },
            status=400,
        )
