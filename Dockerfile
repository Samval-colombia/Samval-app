# syntax=docker/dockerfile:1.7

FROM node:20-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci

FROM base AS build
ARG BUILD_CONFIGURATION=production
COPY . .
RUN npm run build -- --configuration ${BUILD_CONFIGURATION}

FROM nginx:1.27-alpine AS runtime
RUN apk add --no-cache curl
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/samval-ui/browser /usr/share/nginx/html
EXPOSE 80
HEALTHCHECK CMD curl --fail http://localhost/ || exit 1
