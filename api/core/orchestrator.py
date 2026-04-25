"""
ORCHESTRATEUR CENTRAL — Cerveau du système
=========================================
Gère tous les pipelines : Audio, Vidéo, Image/Partition, Microphone
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

# --- Models ---

class InputType(str, Enum):
    AUDIO   = "audio"
    VIDEO   = "video"
    IMAGE   = "image"
    MIC     = "mic"

class PipelineStatus(str, Enum):
    PENDING    = "pending"
    PROCESSING = "processing"
    SUCCESS    = "success"
    PARTIAL    = "partial"
    FAILED     = "failed"

@dataclass
class StepResult:
    name: str
    tool: str
    status: str
    duration_ms: int
    data: dict = field(default_factory=dict)
    error: Optional[str] = None

@dataclass
class AudioFeatures:
    bpm: float = 0.0
    key: str = ""
    mode: str = ""
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
    chord_progression: list = field(default_factory=list)
    chords_timeline: list = field(default_factory=list)
    total_chords: int = 0
    musicxml: Optional[str] = None

@dataclass
class LyricsResult:
    text: str = ""
    segments: list = field(default_factory=list)
    language: str = ""

@dataclass
class SheetMusicResult:
    notes_raw: str = ""
    notes_structured: list = field(default_factory=list)
    key_signature: str = ""
    time_signature: str = ""
    clef: str = ""
    tempo_marking: str = ""
    dynamics: list = field(default_factory=list)
    musicxml_path: Optional[str] = None
    pdf_path: Optional[str] = None
    svg_path: Optional[str] = None
    svg_content: Optional[str] = None

@dataclass
class MusicResult:
    job_id: str = ""
    input_type: str = ""
    status: str = "pending"
    started_at: float = 0.0
    finished_at: float = 0.0
    total_duration_ms: int = 0
    steps: list = field(default_factory=list)
    audio_features: Optional[AudioFeatures] = None
    notes: list = field(default_factory=list)
    harmony: Optional[HarmonyResult] = None
    lyrics: Optional[LyricsResult] = None
    sheet_music: Optional[SheetMusicResult] = None
    source_filename: str = ""
    source_size_mb: float = 0.0
    target_instrument: str = ""  # Instrument cible choisi par l'utilisateur
    warnings: list = field(default_factory=list)  # Avertissements pour le frontend

    def to_dict(self) -> dict:
        d = asdict(self)
        d["steps"] = [asdict(s) if isinstance(s, StepResult) else s for s in self.steps]
        return d

# --- Orchestrator ---

class MusicOrchestrator:
    def __init__(self):
        self._jobs: dict[str, MusicResult] = {}

    async def process(self, input_type: InputType, file_path: str, filename: str = "", size_mb: float = 0.0, options: dict = None) -> MusicResult:
        options = options or {}
        job_id = str(uuid.uuid4())[:8]
        target_instrument = options.get("instrument", "") or options.get("instrument_id", "") or "piano"
        
        result = MusicResult(
            job_id=job_id, 
            input_type=input_type.value, 
            status=PipelineStatus.PROCESSING, 
            started_at=time.time(), 
            source_filename=filename, 
            source_size_mb=size_mb,
            target_instrument=target_instrument,
        )
        self._jobs[job_id] = result
        
        logger.info(f"[{job_id}] Starting {input_type.value} pipeline for '{filename}' ({size_mb:.1f}MB), instrument='{target_instrument}'")
        
        try:
            if input_type == InputType.AUDIO or input_type == InputType.MIC:
                await self._run_audio_pipeline(result, file_path, options)
            elif input_type == InputType.VIDEO:
                await self._run_video_pipeline(result, file_path, options)
            elif input_type == InputType.IMAGE:
                await self._run_image_pipeline(result, file_path, options)

            # Vérifier les étapes en erreur
            failed = [s for s in result.steps if s.status == "error"]
            ok_steps = [s for s in result.steps if s.status == "ok"]
            
            if not ok_steps:
                result.status = PipelineStatus.FAILED
                result.warnings.append("Aucune étape d'analyse n'a réussi. Vérifiez que le fichier est valide.")
            elif failed:
                result.status = PipelineStatus.PARTIAL
                for f in failed:
                    result.warnings.append(f"L'étape '{f.name}' a échoué: {f.error or 'erreur inconnue'}")
            else:
                result.status = PipelineStatus.SUCCESS
                
            # Avertissements spécifiques (pas de fallback silencieux)
            if not result.notes:
                result.warnings.append("Aucune note n'a pu être extraite du fichier audio. Le fichier est peut-être trop court ou ne contient pas de mélodie claire.")
            
            if not result.harmony or not result.harmony.chord_progression:
                result.warnings.append("La reconnaissance d'accords n'a pas produit de résultats. L'harmonie peut être trop complexe pour la détection automatique.")
                
        except Exception as e:
            logger.exception(f"[{job_id}] Pipeline crash: {e}")
            result.status = PipelineStatus.FAILED
            result.steps.append(StepResult(name="orchestrator", tool="core", status="error", duration_ms=0, error=str(e)))

        result.finished_at = time.time()
        result.total_duration_ms = int((result.finished_at - result.started_at) * 1000)
        
        logger.info(f"[{result.job_id}] Final: status={result.status}, {len(result.notes)} notes, "
                     f"{len(result.harmony.chord_progression) if result.harmony else 0} chords, "
                     f"instrument={result.target_instrument}, "
                     f"warnings={len(result.warnings)}")
        return result

    def get_job(self, job_id: str) -> Optional[MusicResult]:
        return self._jobs.get(job_id)

    async def _run_audio_pipeline(self, result: MusicResult, path: str, opts: dict):
        from core.steps import (
            step_ffmpeg_normalize, step_librosa_analyze, step_basic_pitch, 
            step_music21_build_score, step_musescore_render, step_whisper_transcribe,
            step_chord_recognition
        )
        with tempfile.TemporaryDirectory() as tmpdir:
            # 1. Normalisation Audio
            wav_path, step1 = await step_ffmpeg_normalize(path, tmpdir)
            result.steps.append(step1)
            
            # 2. Analyse Features (BPM, Key, Mode)
            af, step2 = await step_librosa_analyze(wav_path)
            result.steps.append(step2)
            if af: result.audio_features = af
            
            # 3. Extraction de Notes (MIDI) via Basic Pitch
            midi_path, notes, step3 = await step_basic_pitch(wav_path, tmpdir)
            result.steps.append(step3)
            result.notes = notes

            # 4. Reconnaissance d'accords (améliorée, par mesure)
            harmony, step_h = await step_chord_recognition(wav_path)
            result.steps.append(step_h)
            if harmony:
                result.harmony = harmony
            
            # 5. Transcription vocale (Paroles) — Optionnelle
            lyrics, step_w = await step_whisper_transcribe(wav_path)
            result.steps.append(step_w)
            if lyrics and lyrics.text.strip():
                result.lyrics = lyrics
            
            # 6. Génération Partition (MusicXML) avec l'instrument cible + accords
            if notes:
                target_instr = result.target_instrument or opts.get("target_key", "")
                # Récupérer les accords détectés pour le voicing
                detected_chords = []
                if result.harmony and result.harmony.chord_progression:
                    detected_chords = result.harmony.chord_progression
                
                xml_path, step_xml = await step_music21_build_score(
                    notes, 
                    af.key_signature if af else "C", 
                    int(af.bpm) if af else 120, 
                    tmpdir,
                    target_instrument=target_instr,
                    chords=detected_chords,
                )
                result.steps.append(step_xml)
                
                # 7. Rendu MuseScore (PDF, SVG)
                if xml_path:
                    pdf_path, svg_path, step_render = await step_musescore_render(xml_path, tmpdir)
                    result.steps.append(step_render)
                    
                    # Copier les fichiers vers le dossier permanent des exports
                    export_id = f"{result.job_id}_{int(time.time())}"
                    final_pdf_name = f"partition_{export_id}.pdf"
                    final_svg_name = f"partition_{export_id}.svg"
                    
                    final_pdf_path = os.path.join("exports", final_pdf_name)
                    final_svg_path = os.path.join("exports", final_svg_name)
                    
                    import shutil
                    if pdf_path and os.path.exists(pdf_path):
                        shutil.copy(pdf_path, final_pdf_path)
                    if svg_path and os.path.exists(svg_path):
                        shutil.copy(svg_path, final_svg_path)

                    # Charger le contenu SVG pour l'affichage direct sur mobile
                    svg_content = None
                    if os.path.exists(final_svg_path):
                        with open(final_svg_path, 'r', encoding='utf-8') as f:
                            svg_content = f.read()

                    result.sheet_music = SheetMusicResult(
                        musicxml_path=xml_path,
                        pdf_path=f"/exports/{final_pdf_name}",
                        svg_path=f"/exports/{final_svg_name}",
                        svg_content=svg_content,
                        key_signature=af.key_signature if af else "C",
                        time_signature="4/4",
                        tempo_marking=str(int(af.bpm)) if af else "120",
                    )

    async def _run_video_pipeline(self, result: MusicResult, path: str, opts: dict):
        from core.steps import step_ffmpeg_extract_audio
        with tempfile.TemporaryDirectory() as tmpdir:
            audio_path, step1 = await step_ffmpeg_extract_audio(path, tmpdir)
            result.steps.append(step1)
            if not audio_path: return
            await self._run_audio_pipeline(result, audio_path, opts)

    async def _run_image_pipeline(self, result: MusicResult, path: str, opts: dict):
        from core.steps import step_opencv_preprocess, step_gpt4o_vision_read_sheet, step_music21_from_sheet
        clean_path, step1 = await step_opencv_preprocess(path)
        result.steps.append(step1)
        sheet, step2 = await step_gpt4o_vision_read_sheet(clean_path or path, opts.get("openai_api_key", ""))
        result.steps.append(step2)
        if sheet:
            result.sheet_music = sheet
            harmony, step3 = await step_music21_from_sheet(sheet)
            result.steps.append(step3)
            if harmony: result.harmony = harmony

orchestrator = MusicOrchestrator()
