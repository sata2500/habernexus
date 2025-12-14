

from django.core.cache import cache
from django.core.management.base import BaseCommand
from django.utils.crypto import get_random_string


class Command(BaseCommand):
    help = "Creates a temporary migration token for server-to-server transfer"

    def handle(self, *args, **options):
        token = get_random_string(64)
        # Token valid for 1 hour
        cache.set(f"migration_token_{token}", True, timeout=3600)

        self.stdout.write(self.style.SUCCESS(f"Migration Token Created: {token}"))
        self.stdout.write(self.style.WARNING("This token is valid for 1 hour. Keep it secure!"))
