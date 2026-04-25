"""
ORCHESTRATEUR CENTRAL — Cerveau du système
=========================================
Gère tous les pipelines : Audio, Vidéo, Image/Partition, Microphone
Chaque analyse passe par ici. C'est le seul point d'entrée.

Flux :
  Input (audio|video|image|mic) 
    → Détection du type 
    → Pipeline spécialisé 
    → Fusion des résultats 
    → Enrichissement LLM 
    → MusicResult unifié
"""

import os
import time
import uuid
import asyncio
import logging
import tempfile
from enum import Enum
from typing import Optional, Any
from dataclasses import dataclass, field, asdict

logger = logging.getLogger(__name__)


# ══════════════════════════════════════════
# TYPES & MODÈLES DE DONNÉES
# ══════════════════════════════════════════

class InputType(str, Enum):
    AUDIO   = "audio"
    VIDEO   = "video"
    IMAGE   = "image"   # partition PDF/photo
    MIC     = "mic"     # enregistrement live

class PipelineStatus(str, Enum):
    PENDING    = "pending"
    PROCESSING = "processing"
    SUCCESS    = "success"
    PARTIAL    = "partial"   # succès avec certaines étapes échouées
    FAILED     = "failed"


@dataclass
class StepResult:
    """Résultat d'une étape du pipeline."""
    name: str
    tool: str
    status: str          # "ok" | "skipped" | "error" | "fallback"
    duration_ms: int
    data: dict = field(default_factory=dict)
    error: Optional[str] = None


@dataclass
class AudioFeatures:
    bpm: float = 0.0
    key: str = ""
    mode: str = ""           # major / minor
    key_signature: str = ""
    duration_seconds: float = 0.0
    chroma_profile: dict = field(default_factory=dict)
    spectral_centroid: float = 0.0
    rms_energy: float = 0.0
    beat_times: list = field(default_factory=list)


@dataclass
class Note:
    note: str
    midi: int
    onset: float
    duration: float
    frequency_hz: float
    velocity: int = 80


@dataclass
class Chord:
    offset: float
    root: str
    quality: str
    name: str
    pitches: list = field(default_factory=list)


@dataclass
class HarmonyResult:
    key_signature: str = ""
    key_confidence: float = 0.0
    chord_progression: list = field(default_factory=list)   # ["Am", "F", "C", "G"]
    chords_timeline: list = field(default_factory=list)     # [{offset, root, quality}...]
    total_chords: int = 0
    musicxml: Optional[str] = None   # MusicXML string pour export partition


@dataclass
class LyricsResult:
    text: str = ""
    segments: list = field(default_factory=list)   # [{start, end, text}]
    language: str = ""


@dataclass
class SheetMusicResult:
    """Résultat lecture partition (pipeline image)."""
    notes_raw: str = ""        # texte extrait par GPT-4o Vision
    notes_structured: list = field(default_factory=list)
    key_signature: str = ""
    time_signature: str = ""
    clef: str = ""
    tempo_marking: str = ""
    dynamics: list = field(default_factory=list)


@dataclass
class MusicResult:
    """
    Résultat unifié — sortie finale de l'orchestrateur.
    Quelle que soit l'entrée (audio/vidéo/image/mic),
    on obtient toujours ce même objet structuré.
    """
    # Identifiants
    job_id: str = ""
    input_type: str = ""
    status: str = "pending"

    # Timing
    started_at: float = 0.0
    finished_at: float = 0.0
    total_duration_ms: int = 0

    # Étapes executées
    steps: list = field(default_factory=list)   # [StepResult]

    # Données musicales
    audio_features: Optional[AudioFeatures] = None
    notes: list = field(default_factory=list)           # [Note]
    harmony: Optional[HarmonyResult] = None
    lyrics: Optional[LyricsResult] = None
    sheet_music: Optional[SheetMusicResult] = None

    # Métadonnées source
    source_filename: str = ""
    source_size_mb: float = 0.0

    def to_dict(self) -> dict:
        d = asdict(self)
        d["steps"] = [asdict(s) if isinstance(s, StepResult) else s for s in self.steps]
        return d


# ══════════════════════════════════════════
# ORCHESTRATEUR
# ══════════════════════════════════════════

class MusicOrchestrator:
    """
    Cœur du système. Reçoit n'importe quelle entrée musicale,
    choisit et exécute le pipeline adapté, retourne un MusicResult unifié.
    """

    def __init__(self):
        self._jobs: dict[str, MusicResult] = {}   # store en mémoire (remplacer par Supabase)

    # ──────────────────────────────────────
    # Point d'entrée unique
    # ──────────────────────────────────────

    async def process(
        self,
        input_type: InputType,
        file_path: str,
        filename: str = "",
        size_mb: float = 0.0,
        options: dict = None,
    ) -> MusicResult:
        """
        Méthode principale. Appelle automatiquement le bon pipeline.
        """
        options = options or {}
        job_id = str(uuid.uuid4())[:8]

        result = MusicResult(
            job_id=job_id,
            input_type=input_type.value,
            status=PipelineStatus.PROCESSING,
            started_at=time.time(),
            source_filename=filename,
            source_size_mb=size_mb,
        )
        self._jobs[job_id] = result
        logger.info(f"[{job_id}] Démarrage pipeline {input_type.value} → {filename}")

        try:
            if input_type == InputType.AUDIO:
                await self._run_audio_pipeline(result, file_path, options)
            elif input_type == InputType.VIDEO:
                await self._run_video_pipeline(result, file_path, options)
            elif input_type == InputType.IMAGE:
                await self._run_image_pipeline(result, file_path, options)
            elif input_type == InputType.MIC:
                await self._run_mic_pipeline(result, file_path, options)

            # Vérification résultats partiels
            failed = [s for s in result.steps if s.status == "error"]
            result.status = (
                PipelineStatus.PARTIAL if failed else PipelineStatus.SUCCESS
            )

        except Exception as e:
            logger.exception(f"[{job_id}] Pipeline crash: {e}")
            result.status = PipelineStatus.FAILED
            result.steps.append(StepResult(
                name="orchestrator", tool="core",
                status="error", duration_ms=0, error=str(e)
            ))

        result.finished_at = time.time()
        result.total_duration_ms = int((result.finished_at - result.started_at) * 1000)
        logger.info(f"[{job_id}] Terminé en {result.total_duration_ms}ms — {result.status}")
        return result

    def get_job(self, job_id: str) -> Optional[MusicResult]:
        return self._jobs.get(job_id)

    # ──────────────────────────────────────
    # PIPELINE AUDIO
    # ──────────────────────────────────────

    async def _run_audio_pipeline(self, result: MusicResult, path: str, opts: dict):
        """
        Étape 1 → FFmpeg normalize
        Étape 2 → Librosa (BPM, chroma, tonalité)
        Étape 3 → Basic Pitch ou fallback (notes MIDI)
        Étape 4 → music21 (accords, gamme, MusicXML)
        """
        from core.steps import (
            step_ffmpeg_normalize,
            step_librosa_analyze,
            step_basic_pitch,
            step_librosa_notes_fallback,
            step_music21_harmony,
        )

        with tempfile.TemporaryDirectory() as tmpdir:
            # Étape 1 : Normalisation
            wav_path, step1 = await step_ffmpeg_normalize(path, tmpdir)
            result.steps.append(step1)

            # Étape 2 : Librosa
            af, step2 = await step_librosa_analyze(wav_path)
            result.steps.append(step2)
            if af:
                result.audio_features = af

            # Étape 3 : Notes MIDI
            midi_path, notes, step3 = await step_basic_pitch(wav_path, tmpdir)
            result.steps.append(step3)

            if not midi_path:
                notes, step3b = await step_librosa_notes_fallback(wav_path)
                result.steps.append(step3b)

            result.notes = notes

            # Étape 4 : Harmonie
            harmony, step4 = await step_music21_harmony(
                midi_path, notes,
                af.key_signature if af else "",
                opts.get("target_key")
            )
            result.steps.append(step4)
            if harmony:
                result.harmony = harmony

    # ──────────────────────────────────────
    # PIPELINE VIDÉO
    # ──────────────────────────────────────

    async def _run_video_pipeline(self, result: MusicResult, path: str, opts: dict):
        """
        Étape 1 → FFmpeg extract audio
        Étape 2 → Whisper (paroles + timestamps)
        Étape 3 → Pipeline audio sur la piste extraite
        """
        from core.steps import step_ffmpeg_extract_audio, step_whisper_transcribe

        with tempfile.TemporaryDirectory() as tmpdir:
            # Étape 1 : Extraction audio
            audio_path, step1 = await step_ffmpeg_extract_audio(path, tmpdir)
            result.steps.append(step1)

            if not audio_path:
                return

            # Étapes 2a+2b en parallèle : Whisper + pipeline audio
            lyrics_task = step_whisper_transcribe(audio_path)
            audio_task  = self._run_audio_pipeline_inner(audio_path, tmpdir, opts)

            lyrics_result, audio_steps_data = await asyncio.gather(
                lyrics_task, audio_task, return_exceptions=True
            )

            # Paroles
            if isinstance(lyrics_result, tuple):
                lyrics, step_w = lyrics_result
                result.steps.append(step_w)
                result.lyrics = lyrics
            elif isinstance(lyrics_result, Exception):
                result.steps.append(StepResult(
                    name="whisper", tool="openai-whisper",
                    status="error", duration_ms=0,
                    error=str(lyrics_result)
                ))

            # Résultats audio
            if isinstance(audio_steps_data, dict):
                result.audio_features = audio_steps_data.get("audio_features")
                result.notes           = audio_steps_data.get("notes", [])
                result.harmony         = audio_steps_data.get("harmony")
                result.steps.extend(audio_steps_data.get("steps", []))

    async def _run_audio_pipeline_inner(self, wav_path: str, tmpdir: str, opts: dict) -> dict:
        """Version interne du pipeline audio (pour appel depuis vidéo)."""
        from core.steps import (
            step_librosa_analyze,
            step_basic_pitch,
            step_librosa_notes_fallback,
            step_music21_harmony,
        )
        steps = []
        af, s2 = await step_librosa_analyze(wav_path)
        steps.append(s2)

        midi_path, notes, s3 = await step_basic_pitch(wav_path, tmpdir)
        steps.append(s3)
        if not midi_path:
            notes, s3b = await step_librosa_notes_fallback(wav_path)
            steps.append(s3b)

        harmony, s4 = await step_music21_harmony(
            midi_path, notes,
            af.key_signature if af else "",
            opts.get("target_key")
        )
        steps.append(s4)

        return {"audio_features": af, "notes": notes, "harmony": harmony, "steps": steps}

    # ──────────────────────────────────────
    # PIPELINE IMAGE / PARTITION PDF
    # ──────────────────────────────────────

    async def _run_image_pipeline(self, result: MusicResult, path: str, opts: dict):
        """
        Étape 1 → OpenCV deskew + enhance
        Étape 2 → GPT-4o Vision (lire partition)
        Étape 3 → music21 (structurer les notes lues)
        """
        from core.steps import (
            step_opencv_preprocess,
            step_gpt4o_vision_read_sheet,
            step_music21_from_sheet,
        )

        # Étape 1 : Préprocessing image
        clean_path, step1 = await step_opencv_preprocess(path)
        result.steps.append(step1)

        # Étape 2 : Lecture partition par GPT-4o Vision
        sheet, step2 = await step_gpt4o_vision_read_sheet(
            clean_path or path,
            opts.get("openai_api_key", os.getenv("OPENAI_API_KEY", ""))
        )
        result.steps.append(step2)
        if sheet:
            result.sheet_music = sheet

        # Étape 3 : Structuration music21
        if sheet and sheet.notes_structured:
            harmony, step3 = await step_music21_from_sheet(sheet)
            result.steps.append(step3)
            if harmony:
                result.harmony = harmony

    # ──────────────────────────────────────
    # PIPELINE MICROPHONE (streaming)
    # ──────────────────────────────────────

    async def _run_mic_pipeline(self, result: MusicResult, path: str, opts: dict):
        """
        Enregistrement sauvegardé → même pipeline audio
        + marquage spécial "live recording"
        """
        result.source_filename = result.source_filename or "live_recording.wav"
        await self._run_audio_pipeline(result, path, opts)
        # Tag spécial
        result.steps.insert(0, StepResult(
            name="mic_capture", tool="pyaudio/webaudio",
            status="ok", duration_ms=0,
            data={"source": "microphone", "mode": "live"}
        ))


# Singleton global
orchestrator = MusicOrchestrator()