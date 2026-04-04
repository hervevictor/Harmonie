# ── Étape 1 : Image légère Python ──────────────────────────────────────────
FROM python:3.11-slim AS base

# Éviter les prompts interactifs
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Dépendances système pour librosa/soundfile/basic-pitch
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsndfile1 \
    ffmpeg \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# ── Étape 2 : Installer les dépendances Python ────────────────────────────
WORKDIR /app

COPY requirements.txt .

# Installer les deps principales
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Installer basic-pitch séparément (peut nécessiter --no-deps)
RUN pip install --no-cache-dir basic-pitch>=0.4.0 || \
    pip install --no-cache-dir basic-pitch --no-deps

# ── Étape 3 : Copier le code ──────────────────────────────────────────────
COPY . .

# Créer le dossier temporaire
RUN mkdir -p /tmp/music_api

# ── Étape 4 : Exposer et lancer ───────────────────────────────────────────
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
