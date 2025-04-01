# syntax=docker/dockerfile:1.4

# Stage 1: Builder
FROM python:3.12.6-slim-bullseye as builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/task

# Upgrade pip and install pipenv
RUN python3 -m pip install --no-cache-dir --upgrade pip pipenv

# Copy Pipfile (and Pipfile.lock if it exists) first to leverage caching
COPY Pipfile ./
COPY Pipfile.lock ./

# Generate requirements.txt and install dependencies
RUN if [ ! -f Pipfile.lock ]; then pipenv lock; fi && \
    pipenv requirements > requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Final runtime
FROM python:3.12.6-slim-bullseye

WORKDIR /var/task

# Copy installed Python packages
COPY --from=builder /usr/local /usr/local

# Copy application code and assets
COPY app /var/task/app

# Set environment variables
ENV PYTHONPATH=/var/task

# Run app with uvicorn using 2 workers
CMD ["uvicorn", "--app-dir", "app", "main:app", "--host", "0.0.0.0", "--port", "8080", "--workers", "2"]
