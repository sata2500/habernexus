# Caddy with Cloudflare DNS module
FROM caddy:2.8.4-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2.8.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:80/health || exit 1

# Expose ports
EXPOSE 80 443

# Default command
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
