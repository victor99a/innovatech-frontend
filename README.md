# Innovatech Frontend — React SPA

Interfaz web (**React 18 + Vite 5 + Tailwind**) del sistema Innovatech Chile. Se sirve con **nginx** dentro de un contenedor y consume los microservicios de Ventas y Despachos vía enrutamiento por path (mismo origen → sin CORS). Desplegado en **AWS ECS Fargate** detrás de un **Application Load Balancer**.

## Arquitectura

```
Usuario → ALB (innovatech-alb)
           ├─ default            → tg-frontend  (nginx :80)
           ├─ /api/v1/ventas*    → tg-ventas    (:8080)
           └─ /api/v1/despachos* → tg-despachos (:8080)
```

En local, nginx hace de reverse-proxy `same-origin` hacia los backends (`VENTAS_UPSTREAM` /
`DESPACHOS_UPSTREAM`), replicando el comportamiento del ALB.

## Stack

React 18, Vite 5, Tailwind CSS, React Router, React Hook Form, Axios, SweetAlert2.

## Entorno local

```bash
npm install
npm run dev     # Vite dev server (proxy /api → localhost:8081 / 8082)
npm run build   # build de producción a dist/
npm run lint    # gate de calidad (también en CI)
```

Con Docker Compose (definido en el repo backend, clonar como carpeta hermana):
```bash
docker compose up --build
# UI: http://localhost:8080
```

## Contenedor

`Dockerfile` **multietapa**:
1. **builder** (`node:20-alpine`): `npm ci` + `vite build`.
2. **runtime** (`nginx:1.27-alpine`): usuario no-root (`pid` en `/tmp`), sirve `dist/` como SPA,
   y aplica `envsubst` sobre `default.conf.template` para configurar los upstreams por entorno.
   Incluye `HEALTHCHECK`.

```bash
docker build -t innovatech-frontend .
docker run -p 8080:80 innovatech-frontend
```

## CI/CD (`.github/workflows/deploy-frontend.yml`)

Push a `main`: **build + lint + build** → **push** a ECR (tag = SHA + `latest`) → **deploy** a
`frontend-service` en ECS Fargate (task definition, target group `tg-frontend` como acción default
del ALB, servicio) → espera despliegue estable.

### Secrets requeridos

`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_REGION`, `ALB_DNS` (DNS del ALB).

## Repos relacionados

- Backend: [innovatech-backend](https://github.com/victor99a/innovatech-backend)
