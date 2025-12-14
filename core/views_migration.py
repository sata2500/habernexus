import os
import subprocess
import tempfile

from django.conf import settings
from django.core.cache import cache
from django.http import HttpResponseForbidden, StreamingHttpResponse
from django.utils.decorators import method_decorator
from django.views import View
from django.views.decorators.csrf import csrf_exempt


class StreamBackupView(View):
    @method_decorator(csrf_exempt)
    def dispatch(self, request, *args, **kwargs):
        return super().dispatch(request, *args, **kwargs)

    def post(self, request):
        token = request.POST.get("token")
        if not token or not cache.get(f"migration_token_{token}"):
            return HttpResponseForbidden("Invalid or expired migration token")

        # Invalidate token after use
        cache.delete(f"migration_token_{token}")

        def file_iterator():
            with tempfile.TemporaryDirectory() as temp_dir:
                backup_file = os.path.join(temp_dir, "backup.tar.gz")

                # 1. Dump Database
                db_config = settings.DATABASES["default"]
                env = os.environ.copy()
                env["PGPASSWORD"] = db_config["PASSWORD"]

                dump_cmd = [
                    "pg_dump",
                    "-h",
                    db_config["HOST"],
                    "-U",
                    db_config["USER"],
                    "-d",
                    db_config["NAME"],
                    "-F",
                    "c",  # Custom format
                    "-f",
                    os.path.join(temp_dir, "db.dump"),
                ]
                subprocess.run(dump_cmd, env=env, check=True)

                # 2. Create Archive including Media
                tar_cmd = ["tar", "-czf", backup_file, "-C", temp_dir, "db.dump", "-C", settings.MEDIA_ROOT, "."]
                subprocess.run(tar_cmd, check=True)

                # 3. Stream the file
                with open(backup_file, "rb") as f:
                    while True:
                        chunk = f.read(8192)
                        if not chunk:
                            break
                        yield chunk

        response = StreamingHttpResponse(file_iterator(), content_type="application/gzip")
        response["Content-Disposition"] = 'attachment; filename="habernexus_migration.tar.gz"'
        return response
