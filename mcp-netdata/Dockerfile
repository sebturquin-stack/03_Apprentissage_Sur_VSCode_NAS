# syntax=docker/dockerfile:1.7

FROM node:20.11.0-bookworm-slim AS deps

ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./

RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --no-audit --no-fund \
    && npm cache clean --force


FROM node:20.11.0-bookworm-slim AS runtime

ENV NODE_ENV=production
WORKDIR /app

RUN set -eux; \
    if ! getent group 1000 >/dev/null; then groupadd --gid 1000 mcp; fi; \
    if ! id -u 1000 >/dev/null 2>&1; then useradd --uid 1000 --gid 1000 --create-home --shell /usr/sbin/nologin mcp; fi

COPY --from=deps --chown=1000:1000 /app/node_modules ./node_modules
COPY --chown=1000:1000 package.json package-lock.json netdata-mcp.js ./

USER 1000:1000

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD ["node", "/app/netdata-mcp.js", "--healthcheck"]

CMD ["node", "/app/netdata-mcp.js"]
