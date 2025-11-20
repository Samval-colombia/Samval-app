# Despliegue de Samval App en Dockploy con Docker

Esta guía explica cómo construir y desplegar Samval App (Angular 19) en Dockploy utilizando Docker. Cada paso se basa en documentación oficial para asegurarte de que las instrucciones se mantengan alineadas con las mejores prácticas.

## 1. Requisitos previos

1. **Angular CLI y build local**. Angular recomienda generar un build de producción con `ng build`, que por defecto usa la configuración `production` y coloca los artefactos en `dist/<app>`.
2. **Docker y Docker Compose**. Docker describe cómo usar `.dockerignore`, multi-stage builds y Compose para definir servicios.
3. **Acceso a Dockploy**. Debes contar con una instancia operativa (cloud o self-hosted) y acceso para crear Applications o Docker Compose deployments. Consulta el panel en `https://docs.dokploy.com` para confirmar la versión instalada.

## 2. Construcción local

```bash
npm ci
npm run build
```

- `npm run build` ejecuta `ng build` y habilita las optimizaciones de producción antes de subir artefactos a un servidor.
- Verifica que el output `dist/samval-ui` se genere correctamente.

## 3. Contenedorización

### 3.1 `.dockerignore`

- Mantén fuera del build context carpetas grandes como `node_modules`, `dist` y `.git` siguiendo la guía oficial de `.dockerignore`.

### 3.2 Dockerfile multi-stage

1. **Stage de build**: usa `node:20-alpine`, instala dependencias con `npm ci` y ejecuta `npm run build -- --configuration production`.
2. **Stage runtime**: usa `nginx:1.27-alpine`, instala `curl` para healthchecks y copia los artefactos estáticos a `/usr/share/nginx/html`.
3. **Config de NGINX**: reemplaza `default.conf` por `docker/nginx.conf` para que todas las rutas vuelvan a `index.html` (deep linking Angular) y habilita caché para `/assets`.
4. **Healthcheck**: `curl --fail http://localhost/ || exit 1` permite que Dokploy detecte contenedores sanos.

### 3.3 Compose opcional

El archivo `compose.yaml` expone el contenedor en `http://localhost:8080` para pruebas locales:

```yaml
services:
  samval-app:
    build:
      context: .
      target: runtime
    ports:
      - "8080:80"
    restart: unless-stopped
```

## 4. Pruebas locales

```bash
docker compose up --build -d
# navegar a http://localhost:8080
```

Usa `docker compose logs` y `docker compose down` para diagnosticar y detener el servicio.

## 5. Estrategias de despliegue en Dockploy

Dockploy ofrece dos enfoques principales: **Applications** (single container) y **Docker Compose**.

### 5.1 Application + Dockerfile (build en Dokploy)

1. En la sección **Applications → General**, elige `GitHub/GitLab/Bitbucket/Gitea` o `Git` como fuente.
2. Selecciona el branch que contiene este repositorio. Dokploy clona y construye usando el `Dockerfile` del root.
3. Define variables (`Environment` tab) si necesitas configuración de runtime.
4. Pulsa **Deploy** para crear la imagen y lanzar el contenedor.
5. Configura dominio y certificados en la pestaña `Domains` si aplica.

_Proveedor GitHub_: si conectas GitHub desde **Providers → GitHub**, cada push al branch configurado dispara auto deploys. Alternativamente, habilita `Auto Deploy` dentro de la aplicación y usa el webhook generado para otros proveedores.

### 5.2 Application + Docker Registry (build externo)

1. Construye y publica la imagen: `docker build -t my-org/samval-app:latest .` y `docker push ...`.
2. En Dokploy selecciona `Docker` como fuente, ingresa la URL del registry (Docker Hub por defecto) y credenciales/token si es privado.
3. Presiona **Deploy** para que Dokploy extraiga la imagen.
4. Activa Auto Deploy mediante webhooks de Docker Hub si quieres que cada `push` al tag despliegue automáticamente.

### 5.3 Servicio Docker Compose

1. Crea un servicio **Docker Compose** y selecciona el proveedor (Git, GitHub, Raw, etc.).
2. Sube el `compose.yaml` del repositorio o pégalo en el editor Raw.
3. En **Environment**, añade variables que necesite tu Compose file (se guarda como `.env`).
4. En **Advanced**, puedes añadir flags extra al comando `docker compose up` que Dokploy ejecuta internamente.
5. Despliega y monitoriza cada servicio desde la pestaña `Monitoring`.

## 6. Integraciones y automatización

- **Auto Deploys**: desde la pestaña `Deployments` activa auto deploy para Git (webhook) o Docker registries. GitHub conectado vía Providers despliega automáticamente cada push del branch configurado.
- **API / GitHub Action**: si necesitas pipelines personalizados, usa la API (`/api/application.deploy`) o la GitHub Action `Dokploy Deployment` con un token y `application_id`.

## 7. Checklist de despliegue

1. ✅ Ejecutar `npm run build` localmente.
2. ✅ Construir la imagen: `docker build -t samval-app .` (opcional si usas build externo).
3. ✅ Probar con `docker compose up --build -d`.
4. ✅ Configurar Application o Compose en Dockploy (fuente + branch o registry).
5. ✅ Asignar dominio/HTTPS si se expone públicamente.
6. ✅ Activar Auto Deploy o pipelines.

---

### Referencias

1. Angular CLI – Deploy & Manual deployment: https://angular.dev/tools/cli/deployment
2. Angular CLI – `ng build` referencia: https://angular.dev/tools/cli/build
3. Dockerfile reference y `.dockerignore`: https://docs.docker.com/reference/builder
4. Docker – Multi-stage & optimización: https://docs.docker.com/offload/optimize/
5. NGINX en Docker y `default.conf`: https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-docker/
6. Docker Compose CLI (`docker compose up`): https://docs.docker.com/reference/cli/docker/compose/up/
7. Compose file reference: https://docs.docker.com/reference/compose-file/
8. Dokploy Applications: https://docs.dokploy.com/docs/core/applications
9. Dokploy Docker Compose: https://docs.dokploy.com/docs/core/docker-compose
10. Dokploy GitHub provider: https://docs.dokploy.com/docs/core/github
11. Dokploy Auto Deploy: https://docs.dokploy.com/docs/core/auto-deploy
12. Dokploy Docker Registry: https://docs.dokploy.com/docs/core/Docker
