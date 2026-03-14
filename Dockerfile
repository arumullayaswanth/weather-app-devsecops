FROM node:20-alpine AS builder

ARG REACT_APP_OPENWEATHER_API_KEY
ENV REACT_APP_OPENWEATHER_API_KEY=$REACT_APP_OPENWEATHER_API_KEY

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM nginxinc/nginx-unprivileged:1.27-alpine

USER root
RUN apk upgrade --no-cache --available

COPY --chown=10001:10001 nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=10001:10001 --from=builder /app/build /usr/share/nginx/html

USER 10001

EXPOSE 8080
