FROM node:22-alpine AS build

WORKDIR /app

# git is required for GitHub fork dependencies (tsdav, tsdav-utils)
RUN apk add --no-cache git

COPY package*.json .npmrc ./
RUN npm ci --omit=dev

# --- Production image ---
FROM node:22-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

COPY --from=build /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

RUN chown -R nodejs:nodejs /app
USER nodejs

EXPOSE ${PORT:-3000}

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "const p = process.env.PORT || 3000; fetch('http://localhost:' + p + '/health').then(r => { process.exit(r.ok ? 0 : 1) }).catch(() => process.exit(1))"

CMD ["node", "src/server-http.js"]
