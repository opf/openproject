FROM node:20.9 as build

COPY . /build
WORKDIR /build/frontend
RUN npm ci
RUN touch ./src/app/features/plugins/linked-plugins.styles.sass
RUN cp ./src/app/features/plugins/linked-plugins.module.ts.example ./src/app/features/plugins/linked-plugins.module.ts
RUN npm run storybook:build

FROM caddy:2-alpine as prod

ARG DOMAIN=my.pullpreview.com
ENV DOMAIN=$DOMAIN

RUN mkdir -p /srv
COPY --from=build /build/frontend/storybook-static /srv/storybook
WORKDIR /srv/storybook
CMD caddy file-server \
  --root /srv/storybook \
  --listen 0.0.0.0:8080

