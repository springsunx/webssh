# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install git and ca-certificates (needed for fetching dependencies)
RUN apk add --no-cache git ca-certificates

# Copy go.mod and go.sum first for better caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o webssh ./cmd/webssh

# Runtime stage
FROM alpine:3.18

# Install ca-certificates and wget for health check
RUN apk --no-cache add ca-certificates wget

# Create non-root user
RUN addgroup -S webssh && adduser -S webssh -G webssh

# Create data directory
RUN mkdir -p /data && chown -R webssh:webssh /data

WORKDIR /app

# Copy binary from builder or from dist directory (for CI builds)
COPY --from=builder /app/webssh .
# If building in CI with pre-built binaries, use this instead:
# ARG BINARY_DIR=.
# COPY ${BINARY_DIR}/webssh-linux-* .

# Copy static assets if any
COPY --from=builder /app/internal/handler/template.go .

# Set proper permissions
RUN chown -R webssh:webssh /app

USER webssh

# Expose port
EXPOSE 8888

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8888/ || exit 1

# Run the application
ENTRYPOINT ["./webssh"]