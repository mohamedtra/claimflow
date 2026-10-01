# syntax=docker/dockerfile:1
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# nginx 1.30 : branche stable maintenue. La 1.28 n'est plus corrigée en amont (CVE-2026-42945).
FROM nginxinc/nginx-unprivileged:1.30-alpine
# Applique les correctifs de sécurité publiés depuis la construction de l'image de base.
USER root
RUN apk upgrade --no-cache
USER 101
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 8080
