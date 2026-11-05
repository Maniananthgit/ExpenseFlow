# Stage 1: Build Flutter Web application
FROM ghcr.io/cirruslabs/flutter:3.35.3 AS build-stage

WORKDIR /app

# Copy dependency configuration and download packages
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and build for production
COPY . .
RUN flutter build web --release

# Stage 2: Serve with lightweight Nginx
FROM nginx:alpine

# Copy built web artifacts to Nginx html directory
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

