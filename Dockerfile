# --- Stage 1: build the React frontend ---
FROM node:20-alpine AS frontend-build
WORKDIR /build
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# --- Stage 2: Python backend serving API + built frontend ---
FROM python:3.11-slim

# Hugging Face Spaces runs as a non-root user; create one and own the workdir
RUN useradd -m -u 1000 app
WORKDIR /app

# System deps occasionally needed by chromadb / pypdf2 wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/ ./
COPY --from=frontend-build /build/dist ./frontend_dist

RUN chown -R app:app /app
USER app

ENV FRONTEND_DIST=/app/frontend_dist \
    PORT=7860

EXPOSE 7860
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
