# 🎵 MUSIC AI API — Documentation Complète
### Stack : FastAPI · Supabase · Basic Pitch · music21 · Claude API · GPT-4o · ACRCloud

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture du projet](#2-architecture-du-projet)
3. [Installation & Configuration](#3-installation--configuration)
4. [Base de données Supabase](#4-base-de-données-supabase)
5. [Core — Authentification & Clients](#5-core--authentification--clients)
6. [Intégrations IA — Détail complet](#6-intégrations-ia--détail-complet)
   - 6.1 Basic Pitch (Spotify) — Transcription audio
   - 6.2 Librosa — Analyse tempo/tonalité
   - 6.3 ACRCloud — Identification de chanson
   - 6.4 GPT-4o Vision — Lecture de partition
   - 6.5 Audiveris — OCR musical
   - 6.6 music21 — Théorie musicale & harmonisation
   - 6.7 Magenta (Google) — Génération mélodique IA
   - 6.8 Claude API — Cours adaptatifs & Quiz
   - 6.9 Whisper — Transcription vocale
7. [Routers — Endpoints complets](#7-routers--endpoints-complets)
8. [Schémas Pydantic](#8-schémas-pydantic)
9. [Pipeline d'analyse complet](#9-pipeline-danalyse-complet)
10. [Migration SQL recommandée](#10-migration-sql-recommandée)
11. [Déploiement](#11-déploiement)

---

## 1. Vue d'ensemble

L'API est organisée en **5 pipelines distincts** :

```
┌─────────────────────────────────────────────────────────┐
│                    MUSIC AI API                         │
├──────────────┬───────────────┬───────────────┬──────────┤
│  AUDIO/VIDÉO │  PDF / IMAGE  │   HARMONIE    │  COURS   │
│  Basic Pitch │   GPT-4o      │   music21     │  Claude  │
│  Librosa     │   Audiveris   │   Magenta     │  Quiz IA │
│  ACRCloud    │   MuseScore   │   MIDI gen    │  Whisper │
└──────────────┴───────────────┴───────────────┴──────────┘
                          │
              ┌───────────▼───────────┐
              │   Supabase Database   │
              │   Supabase Storage    │
              └───────────────────────┘
```

**Technologies principales :**

| Couche | Technologie | Rôle |
|--------|-------------|------|
| Framework | FastAPI 0.111 | API REST async |
| Base de données | Supabase (PostgreSQL) | Stockage données |
| Stockage fichiers | Supabase Storage | Audio, MIDI, images |
| Auth | Supabase JWT | Authentification |
| Transcription audio | Basic Pitch (Spotify) | Audio → MIDI/Notes |
| Analyse audio | Librosa | Tempo, tonalité, timbre |
| Identification | ACRCloud | Reconnaissance de chanson |
| OCR partition | GPT-4o Vision + Audiveris | PDF/Image → Notes |
| Théorie musicale | music21 (MIT) | Accords, gammes, transposition |
| Génération mélodique | Magenta (Google) | IA composition |
| Pédagogie | Claude API (Anthropic) | Cours, quiz, feedback |
| Transcription voix | Whisper (OpenAI) | Quiz oral |

---

## 2. Architecture du projet

```
music_api/
│
├── main.py                         # Point d'entrée FastAPI
├── config.py                       # Variables d'environnement (Pydantic Settings)
├── requirements.txt
├── .env                            # Non versionné
│
├── core/
│   ├── __init__.py
│   ├── supabase_client.py          # Singleton client Supabase
│   ├── auth.py                     # Middleware JWT Supabase
│   ├── storage.py                  # Upload / Download Supabase Storage
│   └── exceptions.py               # Exceptions HTTP personnalisées
│
├── routers/
│   ├── __init__.py
│   ├── files.py                    # Upload fichiers (audio, vidéo, PDF, image)
│   ├── analyses.py                 # Lancer et consulter les analyses
│   ├── harmony.py                  # Accords, gammes, transposition
│   ├── scores.py                   # Génération de partition (MusicXML / PDF)
│   ├── instruments.py              # Liste et détail des instruments
│   ├── courses.py                  # Cours IA adaptatifs par instrument
│   ├── quiz.py                     # Génération et correction de quiz
│   ├── playbacks.py                # Historique d'écoute utilisateur
│   └── subscriptions.py            # Plans et abonnements Stripe
│
├── services/
│   ├── __init__.py
│   │
│   ├── # ── INTÉGRATIONS IA ──────────────────────────────
│   ├── ai_audio/
│   │   ├── basic_pitch_service.py   # Basic Pitch : audio → MIDI/notes
│   │   ├── librosa_service.py       # Librosa : tempo, tonalité, timbre
│   │   └── acrcloud_service.py      # ACRCloud : identification de chanson
│   │
│   ├── ai_score/
│   │   ├── gpt4o_vision_service.py  # GPT-4o Vision : lecture partition image
│   │   └── audiveris_service.py     # Audiveris : OCR partition PDF
│   │
│   ├── ai_harmony/
│   │   ├── music21_service.py       # music21 : accords, gammes, transposition
│   │   ├── magenta_service.py       # Magenta : génération mélodique IA
│   │   └── midi_generator.py        # Génération MIDI depuis notes/accords
│   │
│   ├── ai_pedagogy/
│   │   ├── claude_courses_service.py # Claude : cours adaptatifs
│   │   ├── claude_quiz_service.py    # Claude : quiz et évaluation
│   │   ├── claude_harmony_service.py # Claude : explication harmonique
│   │   └── whisper_service.py        # Whisper : transcription vocale quiz
│   │
│   └── pipeline.py                  # Orchestrateur principal d'analyse
│
├── schemas/
│   ├── __init__.py
│   ├── file.py
│   ├── analysis.py
│   ├── harmony.py
│   ├── score.py
│   ├── course.py
│   └── quiz.py
│
└── utils/
    ├── audio_converter.py           # Conversion formats audio (ffmpeg)
    └── file_helpers.py              # Helpers fichiers temporaires
```

---

## 3. Installation & Configuration

### 3.1 Prérequis système

```bash
# Python 3.11+
python --version

# ffmpeg (conversion audio/vidéo)
sudo apt-get install ffmpeg

# Java 11+ (requis pour Audiveris)
sudo apt-get install default-jdk

# Audiveris (OCR musical)
wget https://github.com/Audiveris/audiveris/releases/latest/download/audiveris.zip
unzip audiveris.zip -d /opt/audiveris
```

### 3.2 Installation Python

```bash
# Créer environnement virtuel
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows

# Installer les dépendances
pip install -r requirements.txt
```

### 3.3 `requirements.txt` complet

```txt
# Framework API
fastapi==0.111.0
uvicorn[standard]==0.30.0
python-multipart==0.0.9
pydantic-settings==2.3.0

# Supabase
supabase==2.5.0
pyjwt==2.8.0

# IA Audio - Basic Pitch & Librosa
basic-pitch==0.3.2
librosa==0.10.2
soundfile==0.12.1
audioread==3.0.1

# IA Musique - music21
music21==9.1.0

# IA Google - Magenta
magenta==2.1.4
tensorflow==2.13.0

# IA Anthropic - Claude
anthropic==0.29.0

# IA OpenAI - GPT-4o & Whisper
openai==1.35.0

# Traitement fichiers
httpx==0.27.0
aiofiles==23.2.1
python-magic==0.4.27
Pillow==10.3.0
pypdf2==3.0.1

# Utilitaires
numpy==1.26.4
scipy==1.13.1
requests==2.32.3
python-dotenv==1.0.1
```

### 3.4 Variables d'environnement (`.env`)

```env
# Supabase
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_JWT_SECRET=super-secret-jwt-token-from-supabase-dashboard

# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-api03-...

# OpenAI (GPT-4o + Whisper)
OPENAI_API_KEY=sk-proj-...

# ACRCloud
ACRCLOUD_HOST=identify-eu-west-1.acrcloud.com
ACRCLOUD_ACCESS_KEY=xxxxxxxxxxxxxxxxx
ACRCLOUD_SECRET_KEY=xxxxxxxxxxxxxxxxx

# Supabase Storage Buckets
STORAGE_BUCKET_FILES=music-files
STORAGE_BUCKET_MIDI=midi-outputs
STORAGE_BUCKET_AUDIO=generated-audio
STORAGE_BUCKET_SCORES=sheet-music

# App
APP_ENV=development
APP_PORT=8000
MAX_FILE_SIZE_MB=100
TEMP_DIR=/tmp/music_api
```

### 3.5 `config.py`

```python
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Supabase
    SUPABASE_URL: str
    SUPABASE_SERVICE_KEY: str
    SUPABASE_JWT_SECRET: str

    # IA APIs
    ANTHROPIC_API_KEY: str
    OPENAI_API_KEY: str
    ACRCLOUD_HOST: str
    ACRCLOUD_ACCESS_KEY: str
    ACRCLOUD_SECRET_KEY: str

    # Storage
    STORAGE_BUCKET_FILES: str = "music-files"
    STORAGE_BUCKET_MIDI: str = "midi-outputs"
    STORAGE_BUCKET_AUDIO: str = "generated-audio"
    STORAGE_BUCKET_SCORES: str = "sheet-music"

    # App
    APP_ENV: str = "development"
    APP_PORT: int = 8000
    MAX_FILE_SIZE_MB: int = 100
    TEMP_DIR: str = "/tmp/music_api"

    class Config:
        env_file = ".env"

@lru_cache()
def get_settings() -> Settings:
    return Settings()

settings = get_settings()
```

### 3.6 `main.py`

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import os
from config import settings
from routers import (
    files, analyses, harmony, scores,
    instruments, courses, quiz, playbacks, subscriptions
)

# Créer le répertoire temporaire
os.makedirs(settings.TEMP_DIR, exist_ok=True)

app = FastAPI(
    title="Music AI API",
    description="API d'analyse musicale alimentée par l'IA",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Restreindre en production : ["https://yourapp.com"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(files.router,         prefix="/api/v1", tags=["📁 Fichiers"])
app.include_router(analyses.router,      prefix="/api/v1", tags=["🔬 Analyses"])
app.include_router(harmony.router,       prefix="/api/v1", tags=["🎼 Harmonie"])
app.include_router(scores.router,        prefix="/api/v1", tags=["📄 Partitions"])
app.include_router(instruments.router,   prefix="/api/v1", tags=["🎸 Instruments"])
app.include_router(courses.router,       prefix="/api/v1", tags=["📚 Cours"])
app.include_router(quiz.router,          prefix="/api/v1", tags=["❓ Quiz"])
app.include_router(playbacks.router,     prefix="/api/v1", tags=["▶️ Playback"])
app.include_router(subscriptions.router, prefix="/api/v1", tags=["💳 Abonnements"])

@app.get("/health", tags=["Système"])
async def health_check():
    return {"status": "ok", "version": "1.0.0", "env": settings.APP_ENV}
```

---

## 4. Base de données Supabase

### 4.1 Schéma actuel (fourni)

Ton schéma couvre : `profiles`, `plans`, `subscriptions`, `instruments`,
`files`, `analyses`, `sessions`, `playbacks`, `usage_logs`, `user_instruments`.

### 4.2 Migrations complémentaires nécessaires

```sql
-- ============================================================
-- MIGRATION 001 : Corrections du schéma existant
-- ============================================================

-- Fix 1 : instrument_id dans sessions doit être uuid, pas text
ALTER TABLE public.sessions
  ALTER COLUMN instrument_id TYPE uuid USING instrument_id::uuid;

ALTER TABLE public.sessions
  ADD CONSTRAINT sessions_instrument_id_fkey
  FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);

-- Fix 2 : user_instruments.instrument_id doit être uuid
ALTER TABLE public.user_instruments
  ALTER COLUMN instrument_id TYPE uuid USING instrument_id::uuid;

ALTER TABLE public.user_instruments
  ADD CONSTRAINT user_instruments_instrument_id_fkey
  FOREIGN KEY (instrument_id) REFERENCES public.instruments(id);

-- Fix 3 : Ajouter current_plan_id sur profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS current_plan_id uuid REFERENCES public.plans(id);

-- ============================================================
-- MIGRATION 002 : Nouvelles tables pédagogiques
-- ============================================================

-- Table quiz_results : résultats des quiz par utilisateur
CREATE TABLE IF NOT EXISTS public.quiz_results (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  analysis_id uuid REFERENCES public.analyses(id),
  instrument_id uuid REFERENCES public.instruments(id),
  topic text NOT NULL,
  level text NOT NULL CHECK (level IN ('débutant', 'intermédiaire', 'avancé')),
  score integer NOT NULL CHECK (score >= 0),
  total_questions integer NOT NULL CHECK (total_questions > 0),
  answers jsonb,                   -- détail de chaque réponse
  duration_seconds integer,        -- temps pour compléter le quiz
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_results_pkey PRIMARY KEY (id)
);

-- Table courses_progress : suivi pédagogique
CREATE TABLE IF NOT EXISTS public.courses_progress (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  instrument_id uuid REFERENCES public.instruments(id),
  topic text NOT NULL,
  level text NOT NULL,
  course_data jsonb,               -- contenu complet du cours généré
  completed boolean DEFAULT false,
  completion_percentage integer DEFAULT 0 CHECK (completion_percentage BETWEEN 0 AND 100),
  last_accessed_at timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT courses_progress_pkey PRIMARY KEY (id),
  CONSTRAINT courses_progress_unique UNIQUE (user_id, instrument_id, topic, level)
);

-- Table generated_scores : partitions générées
CREATE TABLE IF NOT EXISTS public.generated_scores (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  analysis_id uuid NOT NULL REFERENCES public.analyses(id),
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  target_key text,
  format text CHECK (format IN ('musicxml', 'pdf', 'lilypond')),
  storage_path text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT generated_scores_pkey PRIMARY KEY (id)
);

-- ============================================================
-- MIGRATION 003 : RLS (Row Level Security) policies
-- ============================================================

ALTER TABLE public.analyses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_results     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playbacks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs       ENABLE ROW LEVEL SECURITY;

-- Policies : chaque utilisateur accède uniquement à ses données
CREATE POLICY "own_analyses"   ON public.analyses
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_files"      ON public.files
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_quiz"       ON public.quiz_results
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_progress"   ON public.courses_progress
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_scores"     ON public.generated_scores
  FOR ALL USING (user_id = auth.uid());

CREATE POLICY "own_playbacks"  ON public.playbacks
  FOR ALL USING (user_id = auth.uid());

-- instruments : lecture publique
CREATE POLICY "read_instruments" ON public.instruments
  FOR SELECT USING (true);

-- plans : lecture publique
CREATE POLICY "read_plans" ON public.plans
  FOR SELECT USING (true);
```

---

## 5. Core — Authentification & Clients

### 5.1 `core/supabase_client.py`

```python
from supabase import create_client, Client
from config import settings

_client: Client | None = None

def get_supabase() -> Client:
    """Retourne un singleton du client Supabase (service_role)."""
    global _client
    if _client is None:
        _client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY  # service_role : bypass RLS pour le backend
        )
    return _client
```

### 5.2 `core/auth.py`

```python
from fastapi import Depends, HTTPException, Header
from typing import Optional
import jwt
from config import settings

async def get_current_user(authorization: str = Header(...)) -> dict:
    """
    Vérifie le JWT Supabase et retourne le payload utilisateur.
    Le token est généré côté Flutter par supabase.auth.currentSession.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Format du token invalide")

    token = authorization.replace("Bearer ", "")
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        return payload

    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expiré — reconnectez-vous")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Token invalide : {e}")


async def get_optional_user(authorization: Optional[str] = Header(None)) -> Optional[dict]:
    """Pour les routes accessibles avec ou sans authentification."""
    if not authorization:
        return None
    try:
        return await get_current_user(authorization)
    except HTTPException:
        return None
```

### 5.3 `core/storage.py`

```python
from config import settings
from core.supabase_client import get_supabase
from fastapi import HTTPException

async def upload_to_storage(bucket: str, path: str, data: bytes, content_type: str) -> str:
    """Upload un fichier dans Supabase Storage. Retourne le chemin public."""
    db = get_supabase()
    try:
        db.storage.from_(bucket).upload(
            path=path,
            file=data,
            file_options={"content-type": content_type, "upsert": "true"}
        )
        public_url = db.storage.from_(bucket).get_public_url(path)
        return public_url
    except Exception as e:
        raise HTTPException(500, f"Erreur upload Storage : {e}")


async def download_from_storage(bucket: str, path: str) -> bytes:
    """Télécharge un fichier depuis Supabase Storage."""
    db = get_supabase()
    try:
        response = db.storage.from_(bucket).download(path)
        return response
    except Exception as e:
        raise HTTPException(500, f"Erreur download Storage : {e}")


async def delete_from_storage(bucket: str, path: str) -> None:
    """Supprime un fichier du Storage."""
    db = get_supabase()
    db.storage.from_(bucket).remove([path])
```

### 5.4 `core/exceptions.py`

```python
from fastapi import HTTPException

class PlanPermissionError(HTTPException):
    def __init__(self, feature: str):
        super().__init__(
            status_code=403,
            detail=f"Votre plan ne permet pas : {feature}. Passez à un plan supérieur."
        )

class AnalysisNotFoundError(HTTPException):
    def __init__(self, analysis_id: str):
        super().__init__(404, f"Analyse introuvable : {analysis_id}")

class FileNotFoundError(HTTPException):
    def __init__(self, file_id: str):
        super().__init__(404, f"Fichier introuvable : {file_id}")

class AIServiceError(HTTPException):
    def __init__(self, service: str, detail: str):
        super().__init__(502, f"Erreur service IA [{service}] : {detail}")
```

---

## 6. Intégrations IA — Détail complet

---

### 6.1 Basic Pitch (Spotify) — Transcription audio → MIDI/Notes

**Rôle** : Transforme un fichier audio (MP3, WAV, FLAC...) en séquence de notes MIDI avec détection de hauteur, durée, et vélocité.

**Documentation** : https://basicpitch.spotify.com

**Installation** : `pip install basic-pitch`

```python
# services/ai_audio/basic_pitch_service.py

import tempfile, os
from typing import List, Dict, Any
from basic_pitch.inference import predict, Model
from basic_pitch import ICASSP_2022_MODEL_PATH
import numpy as np

# Charger le modèle une seule fois au démarrage (lourd à charger)
_model: Model | None = None

def get_basic_pitch_model() -> Model:
    global _model
    if _model is None:
        _model = Model(ICASSP_2022_MODEL_PATH)
    return _model


async def transcribe_audio_to_notes(file_bytes: bytes, file_extension: str = ".wav") -> Dict[str, Any]:
    """
    Transcrit un fichier audio en séquence de notes musicales.

    Paramètres :
        file_bytes    : contenu du fichier audio en bytes
        file_extension: extension du fichier (.mp3, .wav, .flac...)

    Retourne :
        {
          "notes_sequence": [{"pitch": int, "start": float, "end": float, "confidence": float}],
          "midi_data"     : pretty_midi.PrettyMIDI object,
          "piano_roll"    : np.ndarray (pitch × time),
          "note_events"   : liste brute des événements
        }
    """
    with tempfile.NamedTemporaryFile(suffix=file_extension, delete=False) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        model = get_basic_pitch_model()

        # Prédiction : retourne (model_output, midi_data, note_events)
        model_output, midi_data, note_events = predict(
            audio_path=tmp_path,
            model_or_model_path=model,
            onset_threshold=0.5,       # seuil de détection d'attaque (0-1)
            frame_threshold=0.3,       # seuil de présence de note (0-1)
            minimum_note_length=58,    # durée minimale en millisecondes
            minimum_frequency=None,    # fréquence minimale (None = pas de limite)
            maximum_frequency=None,    # fréquence maximale
            multiple_pitch_bends=False,# un pitch bend par note
            melodia_trick=True,        # améliore la détection de mélodie principale
        )

        # Construire la séquence de notes structurée
        notes_sequence = []
        for event in note_events:
            start_time, end_time, pitch_midi, amplitude, pitch_bends = event
            notes_sequence.append({
                "pitch": int(pitch_midi),           # numéro MIDI (0-127)
                "pitch_name": midi_to_note_name(pitch_midi),  # ex: "C4", "G#3"
                "start": float(start_time),          # en secondes
                "end": float(end_time),
                "duration": float(end_time - start_time),
                "confidence": float(amplitude),      # vélocité/amplitude (0-1)
            })

        # Trier par temps de début
        notes_sequence.sort(key=lambda x: x["start"])

        return {
            "notes_sequence": notes_sequence,
            "midi_data": midi_data,
            "note_count": len(notes_sequence),
        }

    finally:
        os.unlink(tmp_path)


def midi_to_note_name(midi_number: int) -> str:
    """Convertit un numéro MIDI en nom de note (ex: 60 → 'C4')."""
    notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    octave = (midi_number // 12) - 1
    note = notes[midi_number % 12]
    return f"{note}{octave}"


async def save_midi_to_bytes(midi_data) -> bytes:
    """Sérialise un objet PrettyMIDI en bytes pour stockage."""
    with tempfile.NamedTemporaryFile(suffix=".mid", delete=False) as tmp:
        midi_data.write(tmp.name)
        tmp.seek(0)
        return open(tmp.name, "rb").read()
```

---

### 6.2 Librosa — Analyse tempo, tonalité, timbre

**Rôle** : Analyse les caractéristiques acoustiques d'un fichier audio (BPM, tonalité, chroma, spectrogramme).

**Documentation** : https://librosa.org/doc/latest/

**Installation** : `pip install librosa soundfile`

```python
# services/ai_audio/librosa_service.py

import tempfile, os
import librosa
import numpy as np
from typing import Dict, Any

NOTE_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
MAJOR_PROFILE = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
MINOR_PROFILE = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]


async def analyze_audio_features(file_bytes: bytes, file_extension: str = ".wav") -> Dict[str, Any]:
    """
    Analyse complète des caractéristiques audio :
    - Tempo (BPM) et beat tracking
    - Tonalité (clé musicale) avec algorithme de Krumhansl-Schmuckler
    - Signature rythmique estimée
    - Durée totale
    - Énergie RMS
    - Spectrogramme chroma (pour la détection d'accords)
    """
    with tempfile.NamedTemporaryFile(suffix=file_extension, delete=False) as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        # Charger le signal audio
        y, sr = librosa.load(tmp_path, sr=None, mono=True)
        duration = librosa.get_duration(y=y, sr=sr)

        # ── TEMPO & BEATS ──────────────────────────────────────
        tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
        beat_times = librosa.frames_to_time(beat_frames, sr=sr)

        # ── TONALITÉ (algorithme Krumhansl-Schmuckler) ─────────
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1)

        # Corrélation avec profils majeur et mineur pour chaque tonique
        major_scores = []
        minor_scores = []
        for i in range(12):
            rotated_major = np.roll(MAJOR_PROFILE, i)
            rotated_minor = np.roll(MINOR_PROFILE, i)
            major_scores.append(np.corrcoef(chroma_mean, rotated_major)[0, 1])
            minor_scores.append(np.corrcoef(chroma_mean, rotated_minor)[0, 1])

        best_major_idx = np.argmax(major_scores)
        best_minor_idx = np.argmax(minor_scores)

        if max(major_scores) >= max(minor_scores):
            detected_key = f"{NOTE_NAMES[best_major_idx]} major"
            key_confidence = float(max(major_scores))
        else:
            detected_key = f"{NOTE_NAMES[best_minor_idx]} minor"
            key_confidence = float(max(minor_scores))

        # ── SIGNATURE RYTHMIQUE (estimation) ───────────────────
        # Approche simplifiée basée sur le ratio temps forts/faibles
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        time_signature = estimate_time_signature(onset_env, tempo)

        # ── ÉNERGIE & DYNAMIQUE ────────────────────────────────
        rms = librosa.feature.rms(y=y)
        energy_mean = float(rms.mean())
        energy_std = float(rms.std())

        # ── CHROMA POUR ACCORDS ────────────────────────────────
        chroma_stft = librosa.feature.chroma_stft(y=y, sr=sr, n_chroma=12, n_fft=4096)

        return {
            "tempo_bpm": float(round(tempo, 1)),
            "detected_key": detected_key,
            "key_confidence": round(key_confidence, 3),
            "time_signature": time_signature,
            "duration_seconds": float(round(duration, 2)),
            "sample_rate": int(sr),
            "beat_count": len(beat_times),
            "energy_mean": round(energy_mean, 4),
            "chroma_vector": chroma_mean.tolist(),  # Utile pour music21
        }

    finally:
        os.unlink(tmp_path)


def estimate_time_signature(onset_env: np.ndarray, tempo: float) -> str:
    """Estime la signature rythmique (3/4, 4/4, 6/8...) depuis l'enveloppe d'onset."""
    # Méthode simplifiée : analyser la périodicité des temps forts
    # Pour une implémentation complète, utiliser librosa.beat.plp()
    if 50 <= tempo <= 80:
        return "6/8"
    elif 100 <= tempo <= 180:
        return "4/4"
    elif 60 <= tempo <= 100:
        return "3/4"
    return "4/4"
```

---

### 6.3 ACRCloud — Identification de chanson

**Rôle** : Identifie une chanson depuis un extrait audio (fingerprinting acoustique), retourne titre, artiste, album, ISRC.

**Documentation** : https://www.acrcloud.com/docs/

**Installation** : `pip install pyacrcloud` ou utilisation directe de l'API REST.

```python
# services/ai_audio/acrcloud_service.py

import hashlib, hmac, base64, time, httpx
from config import settings
from typing import Dict, Any, Optional

async def identify_song(file_bytes: bytes, file_format: str = "mp3") -> Dict[str, Any]:
    """
    Identifie une chanson via ACRCloud.
    Fonctionne avec un extrait de 10-30 secondes minimum.

    Retourne :
        {
          "title"    : "Nom de la chanson",
          "artist"   : "Nom de l'artiste",
          "album"    : "Nom de l'album",
          "release_date": "2023-01-15",
          "isrc"     : "USRC11600947",
          "duration_ms": 245000,
          "score"    : 100,            # score de confiance (0-100)
          "found"    : True/False
        }
    """
    # Construction de la signature HMAC-SHA1
    http_method = "POST"
    http_uri = "/v1/identify"
    access_key = settings.ACRCLOUD_ACCESS_KEY
    secret_key = settings.ACRCLOUD_SECRET_KEY
    data_type = "audio"
    signature_version = "1"
    timestamp = str(int(time.time()))

    string_to_sign = "\n".join([
        http_method, http_uri, access_key,
        data_type, signature_version, timestamp
    ])

    signature = base64.b64encode(
        hmac.new(
            secret_key.encode("utf-8"),
            string_to_sign.encode("utf-8"),
            digestmod=hashlib.sha1
        ).digest()
    ).decode("utf-8")

    # Prendre les 30 premières secondes si le fichier est plus long
    sample_bytes = file_bytes[:1024 * 1024]  # max 1MB

    async with httpx.AsyncClient(timeout=15.0) as client:
        response = await client.post(
            f"https://{settings.ACRCLOUD_HOST}/v1/identify",
            data={
                "access_key": access_key,
                "sample_bytes": len(sample_bytes),
                "timestamp": timestamp,
                "signature": signature,
                "data_type": data_type,
                "signature_version": signature_version,
            },
            files={"sample": ("audio.mp3", sample_bytes, f"audio/{file_format}")}
        )

    data = response.json()
    status_code = data.get("status", {}).get("code", -1)

    if status_code == 0:
        # Chanson trouvée
        music = data["metadata"]["music"][0]
        return {
            "found": True,
            "title": music.get("title", ""),
            "artist": ", ".join([a["name"] for a in music.get("artists", [])]),
            "album": music.get("album", {}).get("name", ""),
            "release_date": music.get("release_date", ""),
            "isrc": music.get("external_ids", {}).get("isrc", ""),
            "duration_ms": music.get("duration_ms", 0),
            "score": music.get("score", 0),
            "genres": [g["name"] for g in music.get("genres", [])],
            "label": music.get("label", ""),
        }
    elif status_code == 1001:
        return {"found": False, "reason": "Chanson non reconnue dans la base ACRCloud"}
    else:
        return {"found": False, "reason": data.get("status", {}).get("msg", "Erreur inconnue")}
```

---

### 6.4 GPT-4o Vision — Lecture de partition image/PDF

**Rôle** : Analyse visuellement une image de partition musicale et extrait les notes, accords, armure, tempo.

**Documentation** : https://platform.openai.com/docs/guides/vision

```python
# services/ai_score/gpt4o_vision_service.py

import base64, json, re, httpx
from typing import Dict, Any
from config import settings

SCORE_READING_PROMPT = """Tu es un expert en solfège et lecture de partitions musicales.
Analyse avec précision cette image de partition et retourne UNIQUEMENT un objet JSON valide, 
sans texte avant ni après, sans backticks Markdown.

Structure JSON attendue :
{
  "detected_key": "tonalité complète (ex: 'G major', 'D minor', 'Bb major')",
  "time_signature": "mesure (ex: '4/4', '3/4', '6/8', '12/8')",
  "tempo_marking": "indication textuelle si présente (ex: 'Allegro', 'Andante', null)",
  "tempo_bpm": estimation numérique du BPM si indication présente (null sinon),
  "clef": "clé de lecture (ex: 'treble', 'bass', 'alto')",
  "measures_count": nombre total de mesures visibles,
  "notes_sequence": [
    {
      "measure": numéro de mesure (1-indexé),
      "beat": temps dans la mesure (1.0, 1.5, 2.0...),
      "pitch": "nom de note avec octave (ex: 'C4', 'G#3', 'Bb5')",
      "duration": "ronde/blanche/noire/croche/double-croche",
      "duration_beats": valeur numérique (1.0=noire, 2.0=blanche, 0.5=croche...),
      "accidental": "sharp/#, flat/b, natural, null",
      "tied": false,
      "dotted": false
    }
  ],
  "chords_sequence": ["Am", "F", "C", "G"],
  "dynamic_markings": ["p", "mf", "crescendo"],
  "repeat_signs": false,
  "confidence": estimation de ta confiance (0.0 à 1.0)
}

Si la partition est illisible ou l'image de mauvaise qualité, retourne :
{"error": "raison de l'échec", "confidence": 0.0}
"""

async def read_score_from_image(image_bytes: bytes, mime_type: str = "image/jpeg") -> Dict[str, Any]:
    """
    Lit une partition depuis une image via GPT-4o Vision.

    Paramètres :
        image_bytes : contenu de l'image en bytes
        mime_type   : type MIME (image/jpeg, image/png, image/webp)

    Retourne : dict structuré avec notes, accords, tonalité...
    """
    b64_image = base64.b64encode(image_bytes).decode("utf-8")

    async with httpx.AsyncClient(timeout=45.0) as client:
        response = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": "gpt-4o",
                "max_tokens": 4000,
                "temperature": 0.1,     # Faible température pour plus de précision
                "messages": [
                    {
                        "role": "system",
                        "content": "Tu es un expert en solfège. Retourne uniquement du JSON valide."
                    },
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:{mime_type};base64,{b64_image}",
                                    "detail": "high"   # Mode haute résolution
                                }
                            },
                            {
                                "type": "text",
                                "text": SCORE_READING_PROMPT
                            }
                        ]
                    }
                ]
            }
        )

    data = response.json()

    if response.status_code != 200:
        return {"error": f"Erreur API OpenAI : {data.get('error', {}).get('message', 'Inconnue')}"}

    content = data["choices"][0]["message"]["content"].strip()

    # Nettoyage : supprimer les éventuels backticks Markdown
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError as e:
        return {"error": f"Réponse JSON invalide : {e}", "raw": content[:500]}


async def read_score_from_pdf(pdf_bytes: bytes) -> Dict[str, Any]:
    """
    Lit une partition depuis un PDF.
    Convertit chaque page en image puis analyse avec GPT-4o Vision.
    """
    import io
    from PIL import Image
    import pypdf2

    try:
        # Extraire la première page du PDF comme image
        # Note : pour une implémentation complète, utiliser pdf2image
        reader = pypdf2.PdfReader(io.BytesIO(pdf_bytes))
        first_page_text = reader.pages[0].extract_text()

        # Si le PDF contient du texte MusicXML encodé, l'extraire
        if "<score-partwise" in first_page_text or "<note>" in first_page_text:
            return parse_musicxml_text(first_page_text)

        # Sinon, convertir en image et utiliser GPT-4o Vision
        # Nécessite : pip install pdf2image poppler
        from pdf2image import convert_from_bytes
        images = convert_from_bytes(pdf_bytes, first_page=1, last_page=1, dpi=200)

        if images:
            img_bytes = io.BytesIO()
            images[0].save(img_bytes, format="JPEG", quality=95)
            return await read_score_from_image(img_bytes.getvalue(), "image/jpeg")

        return {"error": "Impossible de convertir le PDF en image"}

    except Exception as e:
        return {"error": f"Erreur traitement PDF : {e}"}


def parse_musicxml_text(xml_text: str) -> Dict[str, Any]:
    """Parse un texte MusicXML pour extraire les notes."""
    import xml.etree.ElementTree as ET
    # Implémentation simplifiée
    return {"raw_musicxml": xml_text[:1000], "format": "musicxml"}
```

---

### 6.5 music21 — Théorie musicale & Harmonisation

**Rôle** : Analyse harmonique complète, génération d'accords depuis notes, transposition, génération de partitions MusicXML.

**Documentation** : https://web.mit.edu/music21/doc/

**Installation** : `pip install music21`

```python
# services/ai_harmony/music21_service.py

from music21 import (
    stream, note, chord, key, roman, interval,
    scale as m21_scale, meter, tempo as m21_tempo,
    clef, musicxml
)
from typing import List, Dict, Any, Optional
import tempfile, os, io

# ── GAMMES SUPPORTÉES ────────────────────────────────────────
SCALE_TYPES = {
    "major":      m21_scale.MajorScale,
    "minor":      m21_scale.MinorScale,
    "harmonic_minor": m21_scale.HarmonicMinorScale,
    "melodic_minor":  m21_scale.MelodicMinorScale,
    "pentatonic_major": m21_scale.MajorPentatonicScale,
    "pentatonic_minor": m21_scale.MinorPentatonicScale,
    "blues":      m21_scale.BluesScale,
    "dorian":     m21_scale.DorianScale,
    "phrygian":   m21_scale.PhrygianScale,
    "lydian":     m21_scale.LydianScale,
    "mixolydian": m21_scale.MixolydianScale,
    "locrian":    m21_scale.LocrianScale,
    "whole_tone": m21_scale.WholeToneScale,
    "chromatic":  m21_scale.ChromaticScale,
}


def get_scale_notes(tonic: str, scale_type: str = "major") -> Dict[str, Any]:
    """
    Retourne toutes les notes d'une gamme donnée.

    Exemple :
        get_scale_notes("G", "major")
        → {"notes": ["G4", "A4", "B4", "C5", "D5", "E5", "F#5", "G5"],
           "degrees": ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]}
    """
    scale_class = SCALE_TYPES.get(scale_type, m21_scale.MajorScale)
    sc = scale_class(tonic)
    pitches = sc.getPitches()

    roman_degrees = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
    return {
        "tonic": tonic,
        "scale_type": scale_type,
        "notes": [str(p) for p in pitches],
        "note_names_only": [p.name for p in pitches],
        "degrees": roman_degrees[:len(pitches)],
        "total_notes": len(pitches)
    }


def generate_diatonic_chords(tonic: str, scale_type: str = "major") -> List[Dict[str, Any]]:
    """
    Génère les accords diatoniques (triades et septièmes) d'une gamme.

    Pour Do majeur : I(C), ii(Dm), iii(Em), IV(F), V(G), vi(Am), vii°(Bdim)
    """
    scale_class = SCALE_TYPES.get(scale_type, m21_scale.MajorScale)
    k = key.Key(tonic, scale_type if scale_type in ["major", "minor"] else "major")

    chords_list = []
    roman_numerals = ["I", "II", "III", "IV", "V", "VI", "VII"]

    for i, degree in enumerate(roman_numerals[:7], start=1):
        try:
            rn = roman.RomanNumeral(degree, k)
            c = rn.chord

            # Accord de 7e
            rn7 = roman.RomanNumeral(f"{degree}7", k)
            c7 = rn7.chord

            chords_list.append({
                "degree": degree,
                "degree_number": i,
                "chord_name": c.commonName,
                "chord_symbol": c.root().name + ("m" if c.quality == "minor" else ""),
                "notes": [str(p) for p in c.pitches],
                "seventh_chord": c7.commonName,
                "quality": c.quality,
                "function": get_harmonic_function(i, scale_type)
            })
        except Exception:
            continue

    return chords_list


def get_harmonic_function(degree: int, scale_type: str) -> str:
    """Retourne la fonction harmonique d'un degré."""
    functions = {
        1: "tonique", 2: "sous-dominante", 3: "médiane",
        4: "sous-dominante", 5: "dominante",
        6: "sous-médiante", 7: "sensible"
    }
    return functions.get(degree, "")


def get_chords_from_notes_sequence(
    notes_sequence: List[Dict],
    key_name: str,
    window_seconds: float = 1.0
) -> List[Dict[str, Any]]:
    """
    Analyse une séquence de notes et génère les accords correspondants
    en utilisant des fenêtres temporelles.
    """
    k = key.Key(key_name.split()[0])
    chords_result = []
    current_time = 0.0

    # Regrouper les notes par fenêtre de temps
    while current_time < max((n["end"] for n in notes_sequence), default=0):
        window_notes = [
            n for n in notes_sequence
            if n["start"] < current_time + window_seconds
            and n["end"] > current_time
        ]

        if window_notes:
            pitches = [n.get("pitch_name", f"C{n.get('pitch', 60) // 12}") for n in window_notes]
            try:
                c = chord.Chord(pitches[:4])  # Max 4 notes par accord
                rn = roman.romanNumeralFromChord(c, k)
                chords_result.append({
                    "time": current_time,
                    "chord": rn.figure,
                    "chord_name": c.commonName,
                    "notes": pitches[:4],
                    "quality": c.quality if hasattr(c, 'quality') else ""
                })
            except Exception:
                pass

        current_time += window_seconds

    return chords_result


def transpose_notes(
    notes_sequence: List[Dict],
    from_key: str,
    to_key: str
) -> Dict[str, Any]:
    """
    Transpose une séquence de notes d'une tonalité vers une autre.

    Exemple : transposer de C major vers G major (montée de quinte)
    """
    from_tonic = from_key.split()[0]
    to_tonic = to_key.split()[0]

    try:
        from_note = note.Note(from_tonic)
        to_note = note.Note(to_tonic)
        ivl = interval.Interval(from_note.pitch, to_note.pitch)

        transposed = []
        for n in notes_sequence:
            try:
                n_obj = note.Note(n.get("pitch_name", "C4"))
                transposed_note = n_obj.transpose(ivl)
                transposed.append({
                    **n,
                    "pitch_name": transposed_note.nameWithOctave,
                    "pitch": transposed_note.midi,
                    "original_pitch": n.get("pitch_name", "C4")
                })
            except Exception:
                transposed.append(n)

        return {
            "from_key": from_key,
            "to_key": to_key,
            "interval": str(ivl.directedName),
            "semitones": ivl.semitones,
            "notes_sequence": transposed
        }
    except Exception as e:
        return {"error": f"Erreur transposition : {e}"}


def generate_score_musicxml(
    notes_sequence: List[Dict],
    key_name: str = "C major",
    time_sig: str = "4/4",
    tempo_bpm: float = 120.0,
    instrument_name: str = "Piano",
    title: str = "Score généré"
) -> bytes:
    """
    Génère une partition MusicXML depuis une séquence de notes.
    Le MusicXML peut être ouvert dans MuseScore, Finale, Sibelius...
    """
    # Créer la partition
    score = stream.Score()
    score.metadata.title = title
    score.metadata.composer = "Music AI"

    # Créer la partie
    part = stream.Part()
    part.partName = instrument_name

    # Ajouter la clé, la mesure et le tempo
    tonic, mode = (key_name.split() + ["major"])[:2]
    part.append(key.Key(tonic, mode))
    part.append(meter.TimeSignature(time_sig))
    part.append(m21_tempo.MetronomeMark(number=tempo_bpm))

    # Ajouter les notes
    for n_data in notes_sequence:
        pitch_name = n_data.get("pitch_name", "C4")
        duration_beats = n_data.get("duration_beats", 1.0)

        try:
            n = note.Note(pitch_name)
            n.quarterLength = duration_beats
            part.append(n)
        except Exception:
            # Note invalide → silence
            r = note.Rest()
            r.quarterLength = max(duration_beats, 0.25)
            part.append(r)

    score.append(part)

    # Sérialiser en MusicXML
    with tempfile.NamedTemporaryFile(suffix=".xml", delete=False) as tmp:
        score.write("musicxml", fp=tmp.name)
        xml_content = open(tmp.name, "rb").read()
        os.unlink(tmp.name)

    return xml_content


def suggest_chord_progression(key_name: str, style: str = "pop") -> Dict[str, Any]:
    """
    Suggère des progressions d'accords populaires dans une tonalité.

    Styles supportés : pop, jazz, blues, classical, bossa_nova, flamenco
    """
    progressions = {
        "pop": [
            {"name": "I-V-vi-IV", "chords": [1, 5, 6, 4], "example": "Let It Be"},
            {"name": "I-IV-V-I",  "chords": [1, 4, 5, 1], "example": "Stand By Me"},
            {"name": "vi-IV-I-V", "chords": [6, 4, 1, 5], "example": "Zombie"},
        ],
        "jazz": [
            {"name": "ii-V-I",    "chords": [2, 5, 1],    "example": "Autumn Leaves"},
            {"name": "I-vi-ii-V", "chords": [1, 6, 2, 5], "example": "Fly Me to the Moon"},
        ],
        "blues": [
            {"name": "12-bar blues", "chords": [1,1,1,1, 4,4,1,1, 5,4,1,5], "example": "Sweet Home Chicago"},
        ],
        "classical": [
            {"name": "I-IV-V-I",  "chords": [1, 4, 5, 1], "example": "Cadence parfaite"},
            {"name": "I-V-I",     "chords": [1, 5, 1],    "example": "Cadence authentique"},
        ],
    }

    diatonic = generate_diatonic_chords(key_name.split()[0])
    style_progressions = progressions.get(style, progressions["pop"])

    result = []
    for prog in style_progressions:
        resolved_chords = []
        for degree in prog["chords"]:
            if degree <= len(diatonic):
                resolved_chords.append(diatonic[degree - 1]["chord_symbol"])
        result.append({
            **prog,
            "resolved_chords": resolved_chords,
            "key": key_name
        })

    return {"key": key_name, "style": style, "progressions": result}
```

---

### 6.6 Magenta (Google) — Génération mélodique IA

**Rôle** : Génère des mélodies, harmonisations et accompagnements via des modèles de machine learning entraînés sur de la musique.

**Documentation** : https://magenta.tensorflow.org/

**Installation** : `pip install magenta tensorflow`

> ⚠️ **Note** : Magenta nécessite TensorFlow et est lourd (~2GB). En production, envisager un microservice dédié ou une API serverless.

```python
# services/ai_harmony/magenta_service.py

import tempfile, os
import numpy as np
from typing import List, Dict, Any, Optional

# Import conditionnel pour éviter les erreurs si Magenta n'est pas installé
try:
    from magenta.models.melody_rnn import melody_rnn_sequence_generator
    from magenta.models.melody_rnn import melody_rnn_model
    from note_seq import midi_io, sequences_lib
    from note_seq.protobuf import generator_pb2, music_pb2
    MAGENTA_AVAILABLE = True
except ImportError:
    MAGENTA_AVAILABLE = False


async def generate_melody_continuation(
    seed_notes: List[Dict],
    key_name: str = "C major",
    num_steps: int = 128,
    temperature: float = 1.0,
    model_name: str = "attention_rnn"
) -> Dict[str, Any]:
    """
    Continue une mélodie amorcée avec des notes générées par IA.

    Paramètres :
        seed_notes  : notes de départ [{"pitch": 60, "start": 0.0, "end": 0.5}]
        key_name    : tonalité ("C major", "G minor"...)
        num_steps   : nombre de pas à générer (128 = ~8 mesures à 4/4)
        temperature : créativité (0.5=conservateur, 1.0=équilibré, 2.0=expérimental)
        model_name  : "attention_rnn", "basic_rnn", "lookback_rnn"

    Retourne : dict avec la mélodie générée en notes et MIDI bytes
    """
    if not MAGENTA_AVAILABLE:
        return _fallback_melody_generation(seed_notes, key_name, num_steps)

    try:
        # Convertir les notes seed en NoteSequence Magenta
        seed_sequence = _notes_to_note_sequence(seed_notes, key_name)

        # Charger le bundle du modèle
        bundle_file = _get_model_bundle(model_name)

        generator = melody_rnn_sequence_generator.MelodyRnnSequenceGenerator(
            model=melody_rnn_model.MelodyRnnModel(
                melody_rnn_model.default_configs[model_name]
            ),
            details=None,
            steps_per_quarter=4,
            bundle=bundle_file
        )

        # Configuration de la génération
        generator_options = generator_pb2.GeneratorOptions()
        generator_options.args["temperature"].float_value = temperature
        generator_options.generate_sections.add(
            start_time=len(seed_notes) * 0.5,
            end_time=len(seed_notes) * 0.5 + num_steps * 0.125
        )

        # Générer
        generated_sequence = generator.generate(seed_sequence, generator_options)

        # Convertir en format de sortie
        generated_notes = _note_sequence_to_notes(generated_sequence)

        # Exporter en MIDI
        midi_bytes = _sequence_to_midi_bytes(generated_sequence)

        return {
            "method": "magenta_ai",
            "model": model_name,
            "temperature": temperature,
            "generated_notes": generated_notes,
            "midi_bytes": midi_bytes,
            "steps_generated": num_steps,
        }

    except Exception as e:
        return _fallback_melody_generation(seed_notes, key_name, num_steps)


def _fallback_melody_generation(
    seed_notes: List[Dict],
    key_name: str,
    num_steps: int
) -> Dict[str, Any]:
    """
    Génération de mélodie de secours si Magenta n'est pas disponible.
    Utilise des règles musicales simples (gamme + marche diatonique).
    """
    from services.ai_harmony.music21_service import get_scale_notes

    scale_data = get_scale_notes(key_name.split()[0], "major")
    scale_pitches = [_note_name_to_midi(n) for n in scale_data["notes"]]

    if not seed_notes:
        current_pitch = scale_pitches[0]
    else:
        current_pitch = seed_notes[-1].get("pitch", scale_pitches[0])

    generated = []
    t = (seed_notes[-1]["end"] if seed_notes else 0.0)
    durations = [0.25, 0.5, 0.5, 1.0]  # Double-croche, croche, croche, noire

    for step in range(min(num_steps, 64)):
        # Mouvement par degrés conjoints avec légère randomisation
        movement = np.random.choice([-2, -1, 0, 1, 2], p=[0.1, 0.3, 0.2, 0.3, 0.1])
        current_idx = _closest_scale_degree(current_pitch, scale_pitches)
        new_idx = max(0, min(len(scale_pitches)-1, current_idx + movement))
        current_pitch = scale_pitches[new_idx]

        duration = np.random.choice(durations, p=[0.1, 0.4, 0.3, 0.2])
        generated.append({
            "pitch": current_pitch,
            "pitch_name": _midi_to_note_name(current_pitch),
            "start": round(t, 3),
            "end": round(t + duration, 3),
            "duration": duration,
            "confidence": 1.0
        })
        t += duration

    return {
        "method": "rule_based_fallback",
        "generated_notes": generated,
        "steps_generated": len(generated),
    }


def _note_name_to_midi(note_name: str) -> int:
    """Convertit 'C4' → 60, 'G#3' → 44..."""
    notes = {"C":0,"C#":1,"D":2,"D#":3,"E":4,"F":5,"F#":6,"G":7,"G#":8,"A":9,"A#":10,"B":11}
    # Extraire la note et l'octave
    if len(note_name) >= 2:
        if note_name[1] in ("#", "b"):
            note_part = note_name[:2]
            octave = int(note_name[2:]) if note_name[2:].lstrip("-").isdigit() else 4
        else:
            note_part = note_name[0]
            octave = int(note_name[1:]) if note_name[1:].lstrip("-").isdigit() else 4
        return (octave + 1) * 12 + notes.get(note_part, 0)
    return 60

def _midi_to_note_name(midi: int) -> str:
    notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
    return f"{notes[midi % 12]}{(midi // 12) - 1}"

def _closest_scale_degree(pitch: int, scale_pitches: List[int]) -> int:
    return min(range(len(scale_pitches)), key=lambda i: abs(scale_pitches[i] - pitch))
```

---

### 6.7 Claude API (Anthropic) — Cours adaptatifs & Quiz

**Rôle** : Génère des cours musicaux structurés, des quiz contextuels, des explications harmoniques, et du feedback pédagogique personnalisé.

**Documentation** : https://docs.anthropic.com

**Installation** : `pip install anthropic`

```python
# services/ai_pedagogy/claude_courses_service.py

import anthropic, json, re
from typing import Dict, Any, List, Optional
from config import settings

_claude = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)

# ── CONTEXTES PAR INSTRUMENT ─────────────────────────────────
INSTRUMENT_CONTEXTS = {
    "guitar": {
        "fr": "guitare acoustique et électrique",
        "specifics": "tablatures, accords de barré, techniques fingerpicking et plectrum, "
                     "positions sur le manche, solos pentatoniques",
        "notation": "tablature (TAB) et partition standard"
    },
    "piano": {
        "fr": "piano et clavier",
        "specifics": "position des deux mains, pédalisation, lecture des deux portées (clé de sol et clé de fa), "
                     "technique legato/staccato, arpèges et gammes",
        "notation": "grand staff (deux portées)"
    },
    "violin": {
        "fr": "violon",
        "specifics": "tenue de l'archet, positions (1ère à 7ème), vibrato, coups d'archet "
                     "(détaché, spiccato, martelé), cordes à vide et positions",
        "notation": "clé de sol, positions doigts 1-4"
    },
    "bass": {
        "fr": "basse électrique",
        "specifics": "lignes de basse, groove, techniques slap/pop/fingerstyle, "
                     "rôle rythmique et harmonique, modes de jeu",
        "notation": "tablature basse et clé de fa"
    },
    "drums": {
        "fr": "batterie",
        "specifics": "rudiments de caisse claire, coordination des 4 membres, "
                     "lecture de la notation batterie, grooves styles (rock, jazz, funk), "
                     "dynamique et nuances",
        "notation": "notation percussions sur portée"
    },
    "flute": {
        "fr": "flûte traversière",
        "specifics": "embouchure, doigtés, technique de souffle, "
                     "registres grave/médium/aigu, articulations (legato, staccato, doublé)",
        "notation": "clé de sol, transposition"
    },
    "ukulele": {
        "fr": "ukulélé",
        "specifics": "accords de base, techniques de strumming, fingerpicking, "
                     "accordage GCEA, différences avec la guitare",
        "notation": "tablature ukulélé et diagrammes d'accords"
    },
    "saxophone": {
        "fr": "saxophone",
        "specifics": "anche et embouchure, doigtés, registres, techniques jazz "
                     "(vibrato, growl, altissimo), transposition selon le modèle (alto, ténor...)",
        "notation": "clé de sol, notes transposées"
    },
}

SYSTEM_PROMPT_COURSES = """Tu es un professeur de musique expert, pédagogue et passionné.
Tu crées des cours structurés, progressifs et engageants adaptés au niveau de l'élève.
Tes explications sont claires, avec des exemples concrets et des exercices pratiques.
Tu réponds TOUJOURS en français, avec un ton bienveillant et motivant.
Tu retournes UNIQUEMENT du JSON valide, sans texte ni balises Markdown."""


async def generate_course_lesson(
    instrument: str,
    topic: str,
    level: str,
    analysis_context: Optional[Dict] = None,
    previous_lessons: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Génère un cours complet et structuré.

    Paramètres :
        instrument        : clé de l'instrument ("guitar", "piano"...)
        topic             : sujet du cours ("accords de base", "gamme pentatonique"...)
        level             : "débutant", "intermédiaire", "avancé"
        analysis_context  : contexte de la chanson analysée (tonalité, accords...)
        previous_lessons  : sujets des cours précédents (pour éviter les répétitions)
    """
    inst_ctx = INSTRUMENT_CONTEXTS.get(instrument, {"fr": instrument, "specifics": "", "notation": ""})

    song_context = ""
    if analysis_context:
        key = analysis_context.get("detected_key", "?")
        bpm = analysis_context.get("tempo_bpm", "?")
        chords = ", ".join(str(c) for c in analysis_context.get("chords_sequence", [])[:8])
        song_context = f"""
La chanson analysée est en {key} à {bpm} BPM, avec les accords : {chords}.
Intègre ces éléments spécifiques dans le cours pour le rendre contextualisé et pratique.
"""

    previous_ctx = ""
    if previous_lessons:
        previous_ctx = f"Leçons déjà couvertes (ne pas répéter) : {', '.join(previous_lessons)}"

    prompt = f"""Crée un cours complet de {inst_ctx['fr']} sur : "{topic}"
Niveau de l'élève : {level}
Spécificités de l'instrument : {inst_ctx['specifics']}
Notation utilisée : {inst_ctx['notation']}
{song_context}
{previous_ctx}

Retourne ce JSON exact :
{{
  "title": "titre accrocheur du cours",
  "subtitle": "sous-titre descriptif",
  "instrument": "{instrument}",
  "level": "{level}",
  "topic": "{topic}",
  "duration_minutes": durée estimée en minutes (entre 15 et 60),
  "objectives": [
    "Objectif 1 — compétence précise acquise à la fin du cours",
    "Objectif 2",
    "Objectif 3"
  ],
  "prerequisites": ["prérequis 1", "prérequis 2"],
  "sections": [
    {{
      "id": 1,
      "title": "titre de la section",
      "type": "theory | exercise | listening | practice",
      "duration_minutes": durée,
      "content": "explication détaillée et claire (3-5 paragraphes)",
      "key_points": ["point clé 1", "point clé 2"],
      "exercises": [
        {{
          "title": "titre de l'exercice",
          "description": "description détaillée de comment pratiquer",
          "tempo_bpm": tempo suggéré ou null,
          "duration_minutes": durée,
          "difficulty": "easy | medium | hard"
        }}
      ],
      "tips": ["conseil pro 1", "conseil pro 2"],
      "common_mistakes": ["erreur courante à éviter"]
    }}
  ],
  "notation_examples": [
    {{
      "description": "description de l'exemple notation",
      "notation_type": "tab | chord_diagram | standard_notation | rhythm_pattern",
      "content": "représentation ASCII de l'exemple (tab, diagramme d'accord...)"
    }}
  ],
  "practice_routine": {{
    "warmup_minutes": 5,
    "main_practice_minutes": 20,
    "cooldown_minutes": 5,
    "frequency_per_week": 3,
    "tips": "conseils pour la pratique quotidienne"
  }},
  "next_topics": ["suggestion de prochain cours 1", "suggestion 2"],
  "resources": ["ressource recommandée 1"],
  "summary": "résumé du cours en 2-3 phrases"
}}"""

    message = _claude.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=4000,
        system=SYSTEM_PROMPT_COURSES,
        messages=[{"role": "user", "content": prompt}]
    )

    content = message.content[0].text.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {
            "error": "Génération échouée",
            "raw_content": content[:500],
            "title": topic,
            "instrument": instrument
        }


async def explain_harmony(
    chords: List[str],
    key_name: str,
    instrument: str,
    level: str = "débutant"
) -> Dict[str, Any]:
    """
    Génère une explication pédagogique de la progression harmonique d'une chanson.
    """
    prompt = f"""Explique de façon pédagogique et adaptée à un niveau {level}
la progression harmonique suivante en {key_name} : {' → '.join(chords)}

Instrument de l'élève : {instrument}

Retourne ce JSON :
{{
  "key_analysis": "explication de la tonalité",
  "chord_explanations": [
    {{
      "chord": "nom de l'accord",
      "roman_numeral": "chiffre romain (I, IV, V...)",
      "function": "fonction harmonique",
      "notes": ["notes constituant l'accord"],
      "explanation": "pourquoi cet accord sonne bien ici",
      "fingering_tip": "conseil de doigté spécifique à l'instrument"
    }}
  ],
  "progression_feel": "description de l'ambiance émotionnelle de la progression",
  "similar_songs": ["chanson connue utilisant une progression similaire"],
  "practice_advice": "comment travailler cette progression",
  "theory_insight": "concept de théorie musicale illustré par cette progression"
}}"""

    message = _claude.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=2000,
        system=SYSTEM_PROMPT_COURSES,
        messages=[{"role": "user", "content": prompt}]
    )

    content = message.content[0].text.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"error": "Génération échouée"}
```

```python
# services/ai_pedagogy/claude_quiz_service.py

import anthropic, json, re
from typing import Dict, Any, List, Optional
from config import settings

_claude = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)

SYSTEM_PROMPT_QUIZ = """Tu es un formateur musical expert en pédagogie musicale.
Tu crées des quiz précis, variés et pédagogiques pour évaluer la progression des élèves.
Les questions doivent être claires, les distracteurs plausibles mais distinguables.
Tu réponds TOUJOURS en JSON valide uniquement, sans texte ni balises Markdown."""

QUESTION_TYPES = ["qcm", "vrai_faux", "relier", "completion"]


async def generate_quiz(
    instrument: str,
    topic: str,
    level: str,
    num_questions: int = 5,
    analysis_context: Optional[Dict] = None,
    question_types: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Génère un quiz complet adapté au niveau et au contexte musical.

    Paramètres :
        instrument      : instrument de l'élève
        topic           : sujet du quiz
        level           : "débutant", "intermédiaire", "avancé"
        num_questions   : nombre de questions (max 10)
        analysis_context: contexte chanson pour questions contextualisées
        question_types  : types de questions à inclure (None = mixte)
    """
    num_questions = min(num_questions, 10)
    types = question_types or ["qcm", "qcm", "vrai_faux", "qcm", "qcm"]

    song_ctx = ""
    if analysis_context:
        key = analysis_context.get("detected_key", "")
        chords = analysis_context.get("chords_sequence", [])[:6]
        song_ctx = f"Contextualise certaines questions sur la chanson en {key} avec les accords {chords}."

    prompt = f"""Crée un quiz de {num_questions} questions sur "{topic}" 
pour {instrument}, niveau {level}. {song_ctx}

Types de questions souhaités : {types}

Retourne ce JSON exact :
{{
  "quiz_title": "titre du quiz",
  "instrument": "{instrument}",
  "topic": "{topic}",
  "level": "{level}",
  "total_questions": {num_questions},
  "estimated_duration_minutes": durée estimée,
  "questions": [
    {{
      "id": 1,
      "type": "qcm",
      "question": "texte complet de la question",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0,
      "correct_answer": "Option A",
      "explanation": "explication détaillée de pourquoi c'est la bonne réponse",
      "difficulty": "easy | medium | hard",
      "points": 1,
      "hint": "indice optionnel pour aider l'élève",
      "category": "théorie | pratique | écoute | notation"
    }},
    {{
      "id": 2,
      "type": "vrai_faux",
      "question": "affirmation à évaluer",
      "correct_answer": true,
      "explanation": "explication",
      "difficulty": "easy",
      "points": 1,
      "category": "théorie"
    }}
  ]
}}"""

    message = _claude.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=3000,
        system=SYSTEM_PROMPT_QUIZ,
        messages=[{"role": "user", "content": prompt}]
    )

    content = message.content[0].text.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"error": "Génération quiz échouée", "topic": topic}


async def evaluate_answers(
    quiz: Dict,
    user_answers: List[Dict]
) -> Dict[str, Any]:
    """
    Évalue les réponses d'un élève et génère un feedback personnalisé.

    Paramètres :
        quiz        : quiz original avec les questions
        user_answers: [{"question_id": 1, "answer_index": 2, "time_seconds": 15}]
    """
    questions = quiz.get("questions", [])
    results = []
    total_score = 0
    max_score = sum(q.get("points", 1) for q in questions)

    for answer in user_answers:
        q_id = answer.get("question_id")
        question = next((q for q in questions if q["id"] == q_id), None)
        if not question:
            continue

        q_type = question.get("type", "qcm")
        is_correct = False

        if q_type == "qcm":
            is_correct = answer.get("answer_index") == question.get("correct_index")
        elif q_type == "vrai_faux":
            is_correct = answer.get("answer_value") == question.get("correct_answer")

        points = question.get("points", 1) if is_correct else 0
        total_score += points

        results.append({
            "question_id": q_id,
            "question": question["question"],
            "user_answer": answer.get("answer_index"),
            "correct_index": question.get("correct_index"),
            "correct_answer": question.get("correct_answer"),
            "is_correct": is_correct,
            "points": points,
            "explanation": question.get("explanation", ""),
            "time_seconds": answer.get("time_seconds", 0)
        })

    percentage = round((total_score / max_score * 100) if max_score > 0 else 0, 1)
    wrong_topics = [r["question"] for r in results if not r["is_correct"]]

    # Générer un feedback global avec Claude
    feedback = await _generate_feedback(
        percentage=percentage,
        quiz=quiz,
        wrong_topics=wrong_topics[:3]
    )

    return {
        "quiz_id": quiz.get("quiz_title", ""),
        "total_score": total_score,
        "max_score": max_score,
        "percentage": percentage,
        "grade": _get_grade(percentage),
        "results": results,
        "feedback": feedback,
        "weak_areas": wrong_topics,
        "recommendation": _get_recommendation(percentage, quiz.get("topic", ""))
    }


async def _generate_feedback(percentage: float, quiz: Dict, wrong_topics: List[str]) -> str:
    """Génère un feedback motivant et personnalisé."""
    message = _claude.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=400,
        messages=[{
            "role": "user",
            "content": f"""Quiz "{quiz.get('topic')}" pour {quiz.get('instrument')}, niveau {quiz.get('level')}.
Score : {percentage}%. Questions ratées : {wrong_topics}.
Génère un feedback motivant de 2-3 phrases en français. Sois encourageant mais honnête."""
        }]
    )
    return message.content[0].text.strip()


def _get_grade(percentage: float) -> str:
    if percentage >= 90: return "Excellent"
    if percentage >= 75: return "Très bien"
    if percentage >= 60: return "Bien"
    if percentage >= 50: return "Passable"
    return "À retravailler"


def _get_recommendation(percentage: float, topic: str) -> str:
    if percentage >= 80:
        return f"Excellent travail sur {topic} ! Passez au niveau suivant."
    elif percentage >= 60:
        return f"Bonne base sur {topic}. Révisez les points manqués avant de continuer."
    else:
        return f"Reprenez le cours sur {topic} et réessayez le quiz."
```

---

### 6.8 Whisper (OpenAI) — Transcription vocale pour quiz oral

**Rôle** : Transcrit la réponse vocale d'un utilisateur pour les quiz oraux (nommer une note, chanter un intervalle...).

**Documentation** : https://platform.openai.com/docs/guides/speech-to-text

```python
# services/ai_pedagogy/whisper_service.py

import httpx, tempfile, os
from typing import Dict, Any
from config import settings

async def transcribe_audio_answer(
    audio_bytes: bytes,
    language: str = "fr",
    prompt: str = ""
) -> Dict[str, Any]:
    """
    Transcrit une réponse audio pour un quiz oral.

    Paramètres :
        audio_bytes : enregistrement audio de la réponse (WAV ou MP3)
        language    : langue de transcription ("fr", "en"...)
        prompt      : contexte pour améliorer la précision (ex: "noms de notes de musique")

    Retourne :
        {"text": "Do dièse", "confidence": 0.95, "language": "fr"}
    """
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            "https://api.openai.com/v1/audio/transcriptions",
            headers={"Authorization": f"Bearer {settings.OPENAI_API_KEY}"},
            files={"file": ("answer.wav", audio_bytes, "audio/wav")},
            data={
                "model": "whisper-1",
                "language": language,
                "prompt": prompt or "Noms de notes musicales, accords, termes musicaux en français",
                "response_format": "verbose_json",
                "temperature": 0.0  # Déterministe pour meilleure précision
            }
        )

    if response.status_code != 200:
        return {"error": f"Erreur Whisper : {response.text}", "text": ""}

    data = response.json()
    return {
        "text": data.get("text", "").strip(),
        "language": data.get("language", language),
        "duration_seconds": data.get("duration", 0),
        "segments": [
            {"text": seg["text"], "confidence": seg.get("avg_logprob", 0)}
            for seg in data.get("segments", [])
        ]
    }


async def evaluate_oral_answer(
    transcription: str,
    expected_answer: str,
    question_type: str = "note_name"
) -> Dict[str, Any]:
    """
    Compare la transcription de la réponse orale avec la réponse attendue.

    Types : "note_name", "chord_name", "interval", "free_answer"
    """
    text = transcription.lower().strip()
    expected = expected_answer.lower().strip()

    # Normalisation des termes musicaux français
    aliases = {
        "do": ["c", "do"],
        "ré": ["d", "re", "ré"],
        "mi": ["e", "mi"],
        "fa": ["f", "fa"],
        "sol": ["g", "sol"],
        "la": ["a", "la"],
        "si": ["b", "si"],
        "dièse": ["sharp", "#", "dièse", "diese"],
        "bémol": ["flat", "b", "bémol", "bemol"],
    }

    # Vérification exacte ou par alias
    is_correct = text == expected
    if not is_correct:
        for canonical, alias_list in aliases.items():
            if expected in alias_list and text in alias_list:
                is_correct = True
                break

    return {
        "transcription": transcription,
        "expected": expected_answer,
        "is_correct": is_correct,
        "similarity_score": _text_similarity(text, expected),
        "normalized_answer": text
    }


def _text_similarity(a: str, b: str) -> float:
    """Score de similarité simple entre deux chaînes (0.0 à 1.0)."""
    if a == b:
        return 1.0
    if not a or not b:
        return 0.0
    matches = sum(c in b for c in a)
    return round(matches / max(len(a), len(b)), 2)
```

---

## 7. Routers — Endpoints complets

### 7.1 `routers/files.py`

```python
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from core.storage import upload_to_storage
from core.exceptions import PlanPermissionError
import uuid, mimetypes

router = APIRouter(prefix="/files", tags=["Fichiers"])

ALLOWED_TYPES = {
    "audio": ["audio/mpeg", "audio/wav", "audio/flac", "audio/ogg", "audio/mp4", "audio/aac"],
    "video": ["video/mp4", "video/quicktime", "video/webm", "video/avi"],
    "image": ["image/jpeg", "image/png", "image/webp", "image/tiff"],
    "pdf":   ["application/pdf"],
}
EXTENSION_MAP = {
    "audio/mpeg": ".mp3", "audio/wav": ".wav", "audio/flac": ".flac",
    "video/mp4": ".mp4", "image/jpeg": ".jpg", "image/png": ".png",
    "application/pdf": ".pdf"
}


@router.post("/upload", summary="Upload un fichier musical")
async def upload_file(
    file: UploadFile = File(...),
    user: dict = Depends(get_current_user)
):
    """
    Upload un fichier audio, vidéo, image ou PDF vers Supabase Storage.
    Vérifie les permissions selon le plan de l'utilisateur.

    **Entrée** : Multipart file
    **Sortie** : `{ file_id, status, file_type, size_bytes }`
    """
    user_id = user["sub"]
    content = await file.read()
    mime = file.content_type or mimetypes.guess_type(file.filename)[0] or ""

    # Déterminer le type de fichier
    file_type = next((k for k, mimes in ALLOWED_TYPES.items() if mime in mimes), None)
    if not file_type:
        raise HTTPException(400, f"Type non supporté : {mime}. Acceptés : audio, vidéo, image, PDF")

    # Vérifier la taille
    db = get_supabase()
    plan = await _get_user_plan(user_id, db)
    max_size = plan.get("max_file_size_mb", 25) * 1024 * 1024
    if len(content) > max_size:
        raise HTTPException(413, f"Fichier trop volumineux. Max : {plan['max_file_size_mb']}MB")

    # Vérifier les permissions de type
    if file_type == "video" and not plan.get("can_upload_video"):
        raise PlanPermissionError("upload de vidéos")
    if file_type == "pdf" and not plan.get("can_upload_pdf"):
        raise PlanPermissionError("upload de PDF")

    # Upload Storage
    ext = EXTENSION_MAP.get(mime, "")
    storage_path = f"{user_id}/{uuid.uuid4()}{ext}"
    await upload_to_storage("music-files", storage_path, content, mime)

    # Enregistrer en base
    record = db.table("files").insert({
        "user_id": user_id,
        "original_name": file.filename,
        "storage_path": storage_path,
        "file_type": file_type,
        "mime_type": mime,
        "size_bytes": len(content),
        "status": "ready"
    }).execute()

    # Logger l'action
    db.table("usage_logs").insert({
        "user_id": user_id,
        "action": "file_upload",
        "metadata": {"file_type": file_type, "size_bytes": len(content)}
    }).execute()

    return {
        "file_id": record.data[0]["id"],
        "status": "ready",
        "file_type": file_type,
        "size_bytes": len(content),
        "original_name": file.filename
    }


@router.get("/", summary="Liste les fichiers de l'utilisateur")
async def list_files(
    file_type: str = None,
    limit: int = 20,
    offset: int = 0,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("files").select("*").eq("user_id", user["sub"])
    if file_type:
        query = query.eq("file_type", file_type)
    result = query.order("uploaded_at", desc=True).range(offset, offset + limit - 1).execute()
    return {"files": result.data, "total": len(result.data)}


@router.delete("/{file_id}", summary="Supprime un fichier")
async def delete_file(file_id: str, user: dict = Depends(get_current_user)):
    db = get_supabase()
    record = db.table("files").select("*").eq("id", file_id).eq("user_id", user["sub"]).single().execute()
    if not record.data:
        raise HTTPException(404, "Fichier introuvable")
    from core.storage import delete_from_storage
    await delete_from_storage("music-files", record.data["storage_path"])
    db.table("files").delete().eq("id", file_id).execute()
    return {"message": "Fichier supprimé"}


async def _get_user_plan(user_id: str, db) -> dict:
    sub = db.table("subscriptions").select(
        "plans(max_file_size_mb, can_upload_video, can_upload_pdf, max_uploads_per_month)"
    ).eq("user_id", user_id).eq("status", "active").maybe_single().execute()
    return sub.data["plans"] if sub.data else {
        "max_file_size_mb": 10, "can_upload_video": False, "can_upload_pdf": False
    }
```

---

### 7.2 `routers/analyses.py`

```python
from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.pipeline import run_full_analysis_pipeline
import time

router = APIRouter(prefix="/analyses", tags=["Analyses"])


@router.post("/start", summary="Lance une analyse IA sur un fichier")
async def start_analysis(
    payload: dict,
    background_tasks: BackgroundTasks,
    user: dict = Depends(get_current_user)
):
    """
    Lance le pipeline d'analyse complet en arrière-plan.

    **Corps** : `{ file_id: uuid, instrument_id?: uuid }`
    **Sortie** : `{ analysis_id, status: "pending" }`

    Le pipeline inclut :
    - Basic Pitch (transcription audio → notes)
    - Librosa (tempo, tonalité)
    - ACRCloud (identification chanson, optionnel)
    - music21 (génération accords)
    """
    user_id = user["sub"]
    db = get_supabase()

    file_record = db.table("files").select("*")\
        .eq("id", payload["file_id"])\
        .eq("user_id", user_id)\
        .single().execute()

    if not file_record.data:
        raise HTTPException(404, "Fichier introuvable")

    analysis = db.table("analyses").insert({
        "file_id": payload["file_id"],
        "user_id": user_id,
        "instrument_id": payload.get("instrument_id"),
        "status": "pending"
    }).execute()

    analysis_id = analysis.data[0]["id"]

    background_tasks.add_task(
        run_full_analysis_pipeline,
        analysis_id=analysis_id,
        file_record=file_record.data
    )

    return {"analysis_id": analysis_id, "status": "pending", "message": "Analyse en cours..."}


@router.get("/{analysis_id}", summary="Récupère les résultats d'une analyse")
async def get_analysis(analysis_id: str, user: dict = Depends(get_current_user)):
    """
    **Statuts possibles** : `pending`, `processing`, `completed`, `error`
    """
    db = get_supabase()
    record = db.table("analyses").select("*, files(original_name, file_type), instruments(name)")\
        .eq("id", analysis_id)\
        .eq("user_id", user["sub"])\
        .single().execute()
    if not record.data:
        raise HTTPException(404, "Analyse introuvable")
    return record.data


@router.get("/", summary="Liste les analyses de l'utilisateur")
async def list_analyses(
    status: str = None,
    limit: int = 10,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("analyses").select("*, files(original_name)")\
        .eq("user_id", user["sub"])
    if status:
        query = query.eq("status", status)
    result = query.order("created_at", desc=True).limit(limit).execute()
    return {"analyses": result.data}


@router.post("/{analysis_id}/transpose", summary="Transpose une analyse vers une autre gamme")
async def transpose_analysis(
    analysis_id: str,
    payload: dict,
    user: dict = Depends(get_current_user)
):
    """
    **Corps** : `{ target_key: "G major" }`
    **Sortie** : notes transposées + nouveaux accords
    """
    from services.ai_harmony.music21_service import transpose_notes, get_chords_from_notes_sequence

    db = get_supabase()
    analysis = db.table("analyses").select("*")\
        .eq("id", analysis_id).eq("user_id", user["sub"])\
        .single().execute()

    if not analysis.data or analysis.data["status"] != "completed":
        raise HTTPException(400, "Analyse non disponible ou non terminée")

    data = analysis.data
    target_key = payload.get("target_key", "C major")

    result = transpose_notes(data["notes_sequence"], data["detected_key"], target_key)
    new_chords = get_chords_from_notes_sequence(result["notes_sequence"], target_key)

    return {
        "analysis_id": analysis_id,
        "original_key": data["detected_key"],
        "target_key": target_key,
        "transposed_notes": result["notes_sequence"],
        "new_chords": new_chords,
        "interval": result.get("interval", ""),
        "semitones": result.get("semitones", 0)
    }
```

---

### 7.3 `routers/harmony.py`

```python
from fastapi import APIRouter, Depends
from core.auth import get_current_user
from services.ai_harmony.music21_service import (
    get_scale_notes, generate_diatonic_chords, suggest_chord_progression
)
from services.ai_harmony.magenta_service import generate_melody_continuation
from services.ai_pedagogy.claude_harmony_service import explain_harmony

router = APIRouter(prefix="/harmony", tags=["Harmonie"])

@router.get("/scale", summary="Obtenir les notes d'une gamme")
async def get_scale(
    tonic: str = "C",
    scale_type: str = "major",
    user: dict = Depends(get_current_user)
):
    """
    **Gammes supportées** : major, minor, harmonic_minor, melodic_minor,
    pentatonic_major, pentatonic_minor, blues, dorian, phrygian,
    lydian, mixolydian, locrian, whole_tone, chromatic
    """
    return get_scale_notes(tonic, scale_type)


@router.get("/chords", summary="Accords diatoniques d'une gamme")
async def get_diatonic_chords(
    tonic: str = "C",
    scale_type: str = "major",
    user: dict = Depends(get_current_user)
):
    return {"tonic": tonic, "scale_type": scale_type, "chords": generate_diatonic_chords(tonic, scale_type)}


@router.get("/progressions", summary="Progressions d'accords suggérées")
async def get_progressions(
    tonic: str = "C",
    scale_type: str = "major",
    style: str = "pop",
    user: dict = Depends(get_current_user)
):
    """
    **Styles** : pop, jazz, blues, classical, bossa_nova
    """
    return suggest_chord_progression(f"{tonic} {scale_type}", style)


@router.post("/explain", summary="Explique une progression harmonique (IA)")
async def explain_harmony_route(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "chords": ["Am", "F", "C", "G"],
      "key": "A minor",
      "instrument": "guitar",
      "level": "débutant"
    }
    ```
    """
    return await explain_harmony(
        chords=payload.get("chords", []),
        key_name=payload.get("key", "C major"),
        instrument=payload.get("instrument", "guitar"),
        level=payload.get("level", "débutant")
    )


@router.post("/generate-melody", summary="Génère une continuation mélodique (IA Magenta)")
async def generate_melody(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "seed_notes": [{"pitch": 60, "start": 0.0, "end": 0.5}],
      "key": "C major",
      "num_steps": 64,
      "temperature": 1.0
    }
    ```
    """
    return await generate_melody_continuation(
        seed_notes=payload.get("seed_notes", []),
        key_name=payload.get("key", "C major"),
        num_steps=payload.get("num_steps", 64),
        temperature=payload.get("temperature", 1.0)
    )
```

---

### 7.4 `routers/courses.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.ai_pedagogy.claude_courses_service import generate_course_lesson
from schemas.course import CourseRequest
import uuid

router = APIRouter(prefix="/courses", tags=["Cours"])


@router.post("/generate", summary="Génère un cours adaptatif (IA Claude)")
async def generate_course(payload: CourseRequest, user: dict = Depends(get_current_user)):
    """
    Génère un cours musical complet et structuré via Claude.

    **Corps** :
    ```json
    {
      "instrument": "guitar",
      "topic": "La gamme pentatonique mineure",
      "level": "débutant",
      "analysis_id": "uuid-optionnel"
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    # Récupérer le contexte de l'analyse si fourni
    analysis_context = None
    if payload.analysis_id:
        analysis = db.table("analyses").select("detected_key,tempo_bpm,chords_sequence")\
            .eq("id", payload.analysis_id).eq("user_id", user_id)\
            .maybe_single().execute()
        if analysis.data:
            analysis_context = analysis.data

    # Récupérer les cours précédents pour éviter les répétitions
    previous = db.table("courses_progress").select("topic")\
        .eq("user_id", user_id).eq("instrument_id", payload.instrument)\
        .execute()
    previous_topics = [r["topic"] for r in (previous.data or [])]

    # Générer le cours avec Claude
    course = await generate_course_lesson(
        instrument=payload.instrument,
        topic=payload.topic,
        level=payload.level,
        analysis_context=analysis_context,
        previous_lessons=previous_topics
    )

    if "error" in course:
        raise HTTPException(502, f"Erreur génération cours : {course['error']}")

    # Sauvegarder la progression
    db.table("courses_progress").upsert({
        "user_id": user_id,
        "instrument_id": payload.instrument,
        "topic": payload.topic,
        "level": payload.level,
        "course_data": course,
        "completed": False,
        "completion_percentage": 0
    }, on_conflict="user_id,instrument_id,topic,level").execute()

    return course


@router.get("/", summary="Liste les cours de l'utilisateur")
async def list_courses(
    instrument: str = None,
    completed: bool = None,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("courses_progress").select("*").eq("user_id", user["sub"])
    if instrument:
        query = query.eq("instrument_id", instrument)
    if completed is not None:
        query = query.eq("completed", completed)
    result = query.order("last_accessed_at", desc=True).execute()
    return {"courses": result.data}


@router.patch("/{course_id}/progress", summary="Met à jour la progression d'un cours")
async def update_progress(
    course_id: str,
    payload: dict,
    user: dict = Depends(get_current_user)
):
    """**Corps** : `{ completion_percentage: 75, completed: false }`"""
    db = get_supabase()
    db.table("courses_progress").update({
        "completion_percentage": payload.get("completion_percentage", 0),
        "completed": payload.get("completed", False),
        "last_accessed_at": "now()"
    }).eq("id", course_id).eq("user_id", user["sub"]).execute()
    return {"message": "Progression mise à jour"}
```

---

### 7.5 `routers/quiz.py`

```python
from fastapi import APIRouter, Depends, HTTPException
from core.auth import get_current_user
from core.supabase_client import get_supabase
from services.ai_pedagogy.claude_quiz_service import generate_quiz, evaluate_answers
from services.ai_pedagogy.whisper_service import transcribe_audio_answer, evaluate_oral_answer
from fastapi import UploadFile, File

router = APIRouter(prefix="/quiz", tags=["Quiz"])


@router.post("/generate", summary="Génère un quiz adaptatif (IA Claude)")
async def generate_quiz_route(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "instrument": "piano",
      "topic": "Les intervalles musicaux",
      "level": "intermédiaire",
      "num_questions": 5,
      "analysis_id": "uuid-optionnel"
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    analysis_context = None
    if payload.get("analysis_id"):
        analysis = db.table("analyses").select("detected_key,chords_sequence")\
            .eq("id", payload["analysis_id"]).eq("user_id", user_id)\
            .maybe_single().execute()
        if analysis.data:
            analysis_context = analysis.data

    quiz = await generate_quiz(
        instrument=payload.get("instrument", "guitar"),
        topic=payload.get("topic", "Théorie musicale"),
        level=payload.get("level", "débutant"),
        num_questions=payload.get("num_questions", 5),
        analysis_context=analysis_context
    )
    return quiz


@router.post("/evaluate", summary="Évalue les réponses d'un quiz")
async def evaluate_quiz(payload: dict, user: dict = Depends(get_current_user)):
    """
    **Corps** :
    ```json
    {
      "quiz": { ...quiz_object... },
      "answers": [
        {"question_id": 1, "answer_index": 0, "time_seconds": 12},
        {"question_id": 2, "answer_value": true, "time_seconds": 8}
      ]
    }
    ```
    """
    user_id = user["sub"]
    db = get_supabase()

    quiz = payload.get("quiz", {})
    user_answers = payload.get("answers", [])

    result = await evaluate_answers(quiz, user_answers)

    # Sauvegarder le résultat
    db.table("quiz_results").insert({
        "user_id": user_id,
        "topic": quiz.get("topic", ""),
        "instrument_id": quiz.get("instrument"),
        "level": quiz.get("level", ""),
        "score": result["total_score"],
        "total_questions": result["max_score"],
        "answers": result["results"]
    }).execute()

    return result


@router.post("/oral-answer", summary="Transcrit et évalue une réponse vocale (Whisper)")
async def evaluate_oral(
    audio: UploadFile = File(...),
    expected: str = "",
    question_type: str = "note_name",
    user: dict = Depends(get_current_user)
):
    """
    Permet les quiz oraux : l'utilisateur répond en parlant.
    Whisper transcrit la réponse, puis elle est comparée à la réponse attendue.
    """
    audio_bytes = await audio.read()

    transcription = await transcribe_audio_answer(audio_bytes, language="fr")
    if "error" in transcription:
        raise HTTPException(502, f"Erreur transcription : {transcription['error']}")

    evaluation = await evaluate_oral_answer(
        transcription=transcription["text"],
        expected_answer=expected,
        question_type=question_type
    )

    return {
        "transcription": transcription["text"],
        "evaluation": evaluation
    }


@router.get("/history", summary="Historique des quiz de l'utilisateur")
async def quiz_history(
    instrument: str = None,
    limit: int = 10,
    user: dict = Depends(get_current_user)
):
    db = get_supabase()
    query = db.table("quiz_results").select("*").eq("user_id", user["sub"])
    if instrument:
        query = query.eq("instrument_id", instrument)
    result = query.order("created_at", desc=True).limit(limit).execute()
    return {"history": result.data}
```

---

## 8. Schémas Pydantic

```python
# schemas/course.py
from pydantic import BaseModel
from typing import Optional
import uuid

class CourseRequest(BaseModel):
    instrument: str                 # "guitar", "piano", "violin"...
    topic: str                      # "Gamme pentatonique", "Accords de barré"...
    level: str = "débutant"         # "débutant", "intermédiaire", "avancé"
    analysis_id: Optional[str] = None

# schemas/analysis.py
class AnalysisStartRequest(BaseModel):
    file_id: str
    instrument_id: Optional[str] = None

# schemas/quiz.py
class QuizRequest(BaseModel):
    instrument: str
    topic: str
    level: str = "débutant"
    num_questions: int = 5
    analysis_id: Optional[str] = None
```

---

## 9. Pipeline d'analyse complet

```python
# services/pipeline.py
import time
from core.supabase_client import get_supabase
from core.storage import download_from_storage, upload_to_storage
from services.ai_audio.basic_pitch_service import transcribe_audio_to_notes, save_midi_to_bytes
from services.ai_audio.librosa_service import analyze_audio_features
from services.ai_audio.acrcloud_service import identify_song
from services.ai_score.gpt4o_vision_service import read_score_from_image, read_score_from_pdf
from services.ai_harmony.music21_service import get_chords_from_notes_sequence
import uuid


async def run_full_analysis_pipeline(analysis_id: str, file_record: dict):
    """
    Pipeline d'analyse complet :
    1. Téléchargement du fichier
    2. Analyse selon le type (audio/vidéo/image/PDF)
    3. Génération des accords via music21
    4. Sauvegarde du MIDI généré
    5. Mise à jour de l'analyse en base
    """
    db = get_supabase()
    start_time = time.time()

    try:
        db.table("analyses").update({"status": "processing"}).eq("id", analysis_id).execute()

        # 1. Télécharger le fichier
        file_bytes = await download_from_storage("music-files", file_record["storage_path"])
        file_type = file_record["file_type"]
        mime = file_record.get("mime_type", "audio/wav")
        ext = "." + (file_record["original_name"].rsplit(".", 1)[-1] if "." in file_record.get("original_name","") else "wav")

        result = {}

        # 2. Pipeline selon le type de fichier
        if file_type in ("audio", "video"):

            # 2a. Transcription audio → notes (Basic Pitch)
            bp_result = await transcribe_audio_to_notes(file_bytes, ext)
            result["notes_sequence"] = bp_result["notes_sequence"]

            # 2b. Analyse acoustique (Librosa)
            lib_result = await analyze_audio_features(file_bytes, ext)
            result.update({
                "detected_key":   lib_result["detected_key"],
                "tempo_bpm":      lib_result["tempo_bpm"],
                "time_signature": lib_result["time_signature"],
            })

            # 2c. Identification de la chanson (ACRCloud) — optionnel
            try:
                song_info = await identify_song(file_bytes)
                if song_info.get("found"):
                    result["song_identification"] = song_info
            except Exception:
                pass  # ACRCloud optionnel, ne bloque pas le pipeline

            # 2d. Sauvegarder le MIDI généré
            if bp_result.get("midi_data"):
                midi_bytes = await save_midi_to_bytes(bp_result["midi_data"])
                midi_path = f"midi/{analysis_id}.mid"
                await upload_to_storage("midi-outputs", midi_path, midi_bytes, "audio/midi")
                result["midi_storage_path"] = midi_path

        elif file_type == "image":
            # Pipeline partition image → GPT-4o Vision
            score_result = await read_score_from_image(file_bytes, mime)
            result.update({
                "notes_sequence":  score_result.get("notes_sequence", []),
                "detected_key":    score_result.get("detected_key", ""),
                "time_signature":  score_result.get("time_signature", ""),
                "chords_sequence": score_result.get("chords_sequence", []),
                "tempo_bpm":       score_result.get("tempo_bpm"),
            })

        elif file_type == "pdf":
            # Pipeline partition PDF → GPT-4o Vision
            score_result = await read_score_from_pdf(file_bytes)
            result.update({
                "notes_sequence":  score_result.get("notes_sequence", []),
                "detected_key":    score_result.get("detected_key", ""),
                "time_signature":  score_result.get("time_signature", ""),
                "chords_sequence": score_result.get("chords_sequence", []),
            })

        # 3. Générer les accords depuis les notes (music21) si pas déjà faits
        if result.get("notes_sequence") and not result.get("chords_sequence"):
            if result.get("detected_key"):
                result["chords_sequence"] = get_chords_from_notes_sequence(
                    result["notes_sequence"],
                    result["detected_key"]
                )

        # 4. Mise à jour en base
        processing_ms = int((time.time() - start_time) * 1000)
        db.table("analyses").update({
            "status":            "completed",
            "detected_key":      result.get("detected_key"),
            "time_signature":    result.get("time_signature"),
            "tempo_bpm":         result.get("tempo_bpm"),
            "notes_sequence":    result.get("notes_sequence"),
            "chords_sequence":   result.get("chords_sequence"),
            "midi_storage_path": result.get("midi_storage_path"),
            "processing_time_ms": processing_ms,
            "updated_at":        "now()"
        }).eq("id", analysis_id).execute()

    except Exception as e:
        db.table("analyses").update({
            "status": "error",
            "error_message": str(e)[:500],
            "updated_at": "now()"
        }).eq("id", analysis_id).execute()
        raise
```

---

## 10. Migration SQL recommandée

Voir section 4.2 ci-dessus.

---

## 11. Déploiement

### 11.1 Lancement local

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 11.2 Docker

```dockerfile
FROM python:3.11-slim

# Dépendances système
RUN apt-get update && apt-get install -y ffmpeg default-jdk libsndfile1 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN mkdir -p /tmp/music_api

EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

```bash
docker build -t music-ai-api .
docker run -p 8000:8000 --env-file .env music-ai-api
```

### 11.3 Appel depuis Flutter

```dart
// Exemple d'appel depuis Flutter
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/analyses/start'),
  headers: {
    'Authorization': 'Bearer ${supabase.auth.currentSession!.accessToken}',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'file_id': fileId,
    'instrument_id': selectedInstrumentId,
  }),
);

final data = jsonDecode(response.body);
final analysisId = data['analysis_id'];

// Polling du statut
Timer.periodic(Duration(seconds: 2), (timer) async {
  final statusRes = await http.get(
    Uri.parse('$baseUrl/api/v1/analyses/$analysisId'),
    headers: {'Authorization': 'Bearer ${supabase.auth.currentSession!.accessToken}'},
  );
  final status = jsonDecode(statusRes.body)['status'];
  if (status == 'completed' || status == 'error') {
    timer.cancel();
    // Traiter le résultat
  }
});
```

### 11.4 Résumé des endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/files/upload` | Upload fichier |
| `GET` | `/api/v1/files/` | Lister les fichiers |
| `DELETE` | `/api/v1/files/{id}` | Supprimer un fichier |
| `POST` | `/api/v1/analyses/start` | Lancer une analyse |
| `GET` | `/api/v1/analyses/{id}` | Résultats analyse |
| `GET` | `/api/v1/analyses/` | Lister les analyses |
| `POST` | `/api/v1/analyses/{id}/transpose` | Transposer |
| `GET` | `/api/v1/harmony/scale` | Notes d'une gamme |
| `GET` | `/api/v1/harmony/chords` | Accords diatoniques |
| `GET` | `/api/v1/harmony/progressions` | Progressions suggérées |
| `POST` | `/api/v1/harmony/explain` | Explication IA (Claude) |
| `POST` | `/api/v1/harmony/generate-melody` | Génération mélodique (Magenta) |
| `GET` | `/api/v1/instruments/` | Liste instruments |
| `POST` | `/api/v1/courses/generate` | Générer cours (Claude) |
| `GET` | `/api/v1/courses/` | Lister cours |
| `PATCH` | `/api/v1/courses/{id}/progress` | Mise à jour progression |
| `POST` | `/api/v1/quiz/generate` | Générer quiz (Claude) |
| `POST` | `/api/v1/quiz/evaluate` | Évaluer réponses |
| `POST` | `/api/v1/quiz/oral-answer` | Réponse vocale (Whisper) |
| `GET` | `/api/v1/quiz/history` | Historique quiz |
| `GET` | `/api/v1/subscriptions/me` | Plan actif |

---

*Documentation générée pour Music AI API v1.0.0 — Stack FastAPI + Supabase + Basic Pitch + music21 + Claude + GPT-4o + Magenta + Whisper*
