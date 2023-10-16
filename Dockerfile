# Install dependencies only when needed
FROM node:20.8.1-alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json ./
RUN yarn install # --immutable

# Rebuild the source code only when needed
FROM node:20.8.1-alpine AS builder
WORKDIR /app
COPY . .
COPY --from=deps /app/node_modules ./node_modules
RUN --mount=type=secret,id=SENTRY_AUTH_TOKEN \
  SENTRY_AUTH_TOKEN=$(cat /run/secrets/SENTRY_AUTH_TOKEN) \
  yarn build && yarn install # --immutable

# Production image, copy all the files and run Docusaurus
FROM node:20.8.1-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

COPY --from=builder /app/docusaurus.config.js ./
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

CMD ["yarn", "start"]
