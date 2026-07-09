# =========================================================================
# ETAPA 1 - Builder: compila la SPA con Vite
# =========================================================================
FROM node:20-alpine AS builder
WORKDIR /app
ENV NODE_ENV=production

# Cache de dependencias: manifiestos primero
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# =========================================================================
# ETAPA 2 - Runtime: nginx no-root sirviendo la SPA
# =========================================================================
FROM nginx:1.27-alpine

# Config principal (pid/logs en /tmp para correr sin root)
COPY nginx-main.conf /etc/nginx/nginx.conf
# Plantilla: nginx aplica envsubst sobre /etc/nginx/templates/*.template al arrancar
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/dist /usr/share/nginx/html

# Upstreams por defecto (se sobreescriben con env vars en compose/ECS)
ENV VENTAS_UPSTREAM=http://backend-ventas:8080 \
    DESPACHOS_UPSTREAM=http://backend-despacho:8080

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:80/ >/dev/null 2>&1 || exit 1
