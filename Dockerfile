# Stage 1: Builder
FROM python:3.11.3-slim AS builder

WORKDIR /app

COPY src/requirements.txt .
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11.3-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy source
COPY src/ .

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate && gunicorn demo.wsgi:application --bind 0.0.0.0:8000"]