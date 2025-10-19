FROM ghcr.io/usememos/memos:stable

EXPOSE 5230

# Environment variables (task definition will override these)
ENV MEMOS_MODE=prod
ENV MEMOS_PORT=5230

# Volume mount point (ECS task definition handles actual mounting)
VOLUME /var/opt/memos

# Health check for container
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5230/ || exit 1