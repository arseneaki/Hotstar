# ============================================
# Stage 1: Build
# ============================================
FROM node:18-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (production + dev for build)
RUN npm ci --include=dev

# Copy source code
COPY . .

# Build React application
RUN npm run build

# ============================================
# Stage 2: Production
# ============================================
FROM node:18-alpine

# Install security updates
RUN apk update && apk upgrade && \
    apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies + express for server
RUN npm ci --only=production && \
    npm install express compression helmet

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/build ./build

# Copy server file
COPY --chown=nodejs:nodejs server.js ./

# Create tmp directory for writable files
RUN mkdir -p /tmp && chown nodejs:nodejs /tmp

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
