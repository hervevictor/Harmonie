# Music Analysis Core — Dépendances

# pip install -r requirements.txt

fastapi==0.115.0
uvicorn[standard]==0.30.6
python-multipart==0.0.9
aiofiles==24.1.0

# Analyse audio (requis)

librosa==0.10.2
numpy>=1.24.0
scipy>=1.11.0
soundfile>=0.12.1

# Théorie musicale (requis)

music21==9.1.0

# Extraction MIDI haute précision (fortement recommandé)

# basic-pitch==0.3.4

# Transcription paroles (pipeline vidéo)

# openai-whisper==20240930

# Vision — lecture partition (pipeline image)

# openai>=1.0.0

# opencv-python>=4.9.0

# LLM — cours + quiz (phase 2)

# anthropic>=0.25.0

# Utilitaires

python-dotenv==1.0.0
httpx==0.27.0
python-magic==0.4.27
