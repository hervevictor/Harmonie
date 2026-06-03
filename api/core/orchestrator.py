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

from core.supabase_client import get_supabase
from core.storage import upload_to_storage

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
    time_signature: str = "4/4"   # NEW — detected meter (e.g. "4/4", "3/4", "6/8")

@dataclass
class Note:
    note: str
    midi: int
    onset: float
    duration: float
    frequency_hz: float
    amplitude: float = 1.0

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
        user_id = options.get("user_id")
        
        logger.info(f"[{job_id}] Processing request: user={user_id}, file={filename} ({size_mb:.1f}MB)")
        
        # ═══ ÉTAPE 1 : DE DÉTECTION DU CACHE SUPABASE ═══
        if user_id:
            try:
                db = get_supabase()
                # 1. Rechercher si ce fichier a déjà été analysé par l'utilisateur
                file_query = db.table("files").select("id").eq("user_id", user_id).eq("original_name", filename).execute()
                if file_query.data:
                    file_ids = [f["id"] for f in file_query.data]
                    # 2. Chercher une analyse complétée pour ce fichier
                    analysis_query = db.table("analyses").select("*").in_("file_id", file_ids).eq("status", "completed").order("created_at", desc=True).limit(1).execute()
                    if analysis_query.data:
                        ana = analysis_query.data[0]
                        logger.info(f"[{job_id}] Cache hit in Supabase for '{filename}'! Skipping computation.")
                        
                        # Reconstituer les notes
                        notes_list = []
                        for n in (ana.get("notes_sequence") or []):
                            notes_list.append(Note(
                                note=n.get("note", ""),
                                midi=n.get("midi", 0),
                                onset=n.get("onset", 0.0),
                                duration=n.get("duration", 0.0),
                                frequency_hz=n.get("frequency_hz", 0.0),
                                amplitude=n.get("amplitude", 1.0)
                            ))
                        
                        # Reconstituer l'harmonie
                        chord_prog = ana.get("chords_sequence") or []
                        harmony = HarmonyResult(
                            key_signature=ana.get("detected_key") or "C",
                            chord_progression=chord_prog,
                            chords_timeline=[],
                            total_chords=len(chord_prog)
                        )
                        
                        af = AudioFeatures(
                            bpm=float(ana.get("tempo_bpm") or 120.0),
                            key_signature=ana.get("detected_key") or "C",
                            duration_seconds=float(ana.get("processing_time_ms") or 0) / 1000.0
                        )
                        
                        # Reconstituer la partition si présente
                        sheet = None
                        if ana.get("midi_storage_path"):
                            # On déduit les URLs de partitions depuis le midi
                            sheet = SheetMusicResult(
                                key_signature=ana.get("detected_key") or "C",
                                time_signature=ana.get("time_signature") or "4/4",
                                pdf_path=ana.get("midi_storage_path").replace(".mid", ".pdf").replace("midi-outputs", "partitions"),
                                musicxml_path=ana.get("midi_storage_path").replace(".mid", ".xml").replace("midi-outputs", "partitions")
                            )
                        
                        result = MusicResult(
                            job_id=job_id,
                            input_type=input_type.value,
                            status=PipelineStatus.SUCCESS,
                            started_at=time.time(),
                            finished_at=time.time(),
                            total_duration_ms=10,
                            steps=[StepResult(name="supabase_cache", tool="supabase", status="ok", duration_ms=1)],
                            audio_features=af,
                            notes=notes_list,
                            harmony=harmony,
                            sheet_music=sheet,
                            source_filename=filename,
                            source_size_mb=size_mb,
                            target_instrument=target_instrument,
                            warnings=["Résultat chargé depuis le cache persistant (Supabase) pour des performances maximales."]
                        )
                        self._jobs[job_id] = result
                        return result
            except Exception as ce:
                logger.warning(f"Failed to query Supabase cache: {ce}")

        # ═══ ÉTAPE 2 : PERSISTANCE INITIALE (Pendant le traitement) ═══
        db_file_id = None
        db_analysis_id = None
        if user_id:
            try:
                db = get_supabase()
                file_size_bytes = os.path.getsize(file_path) if os.path.exists(file_path) else int(size_mb * 1024 * 1024)
                
                # 1. Enregistrer le fichier en base
                storage_path = f"{user_id}/{job_id}_{filename}"
                file_record = db.table("files").insert({
                    "user_id": user_id,
                    "original_name": filename,
                    "storage_path": storage_path,
                    "file_type": input_type.value,
                    "mime_type": "audio/wav" if input_type in (InputType.AUDIO, InputType.MIC) else "image/png",
                    "size_bytes": file_size_bytes,
                    "status": "ready"
                }).execute()
                
                if file_record.data:
                    db_file_id = file_record.data[0]["id"]
                    
                    # 2. Upload le fichier original dans le bucket 'music-files'
                    if os.path.exists(file_path):
                        with open(file_path, "rb") as f:
                            file_data = f.read()
                        db.storage.from_("music-files").upload(
                            path=storage_path,
                            file=file_data,
                            file_options={"upsert": "true"}
                        )
                    
                    # 3. Créer l'enregistrement d'analyse pending
                    analysis_record = db.table("analyses").insert({
                        "file_id": db_file_id,
                        "user_id": user_id,
                        "instrument_id": target_instrument,
                        "status": "processing"
                    }).execute()
                    if analysis_record.data:
                        db_analysis_id = analysis_record.data[0]["id"]
                        options["db_analysis_id"] = db_analysis_id
                        options["user_id"] = user_id
            except Exception as dbe:
                logger.warning(f"Failed to initialize Supabase records: {dbe}")

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
        
        try:
            if input_type == InputType.AUDIO or input_type == InputType.MIC:
                await self._run_audio_pipeline(result, file_path, options)
            elif input_type == InputType.VIDEO:
                await self._run_video_pipeline(result, file_path, options)
            elif input_type == InputType.IMAGE:
                await self._run_image_pipeline(result, file_path, options)

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
                
            if not result.notes:
                result.warnings.append("Aucune note n'a pu être extraite du fichier audio.")
            
        except Exception as e:
            logger.exception(f"[{job_id}] Pipeline crash: {e}")
            result.status = PipelineStatus.FAILED
            result.steps.append(StepResult(name="orchestrator", tool="core", status="error", duration_ms=0, error=str(e)))

        result.finished_at = time.time()
        result.total_duration_ms = int((result.finished_at - result.started_at) * 1000)

        # ═══ ÉTAPE 3 : PERSISTANCE FINALE (Enregistrement des résultats en base) ═══
        if db_analysis_id:
            try:
                db = get_supabase()
                notes_json = []
                for n in result.notes:
                    notes_json.append({
                        "note": n.note,
                        "midi": n.midi,
                        "onset": n.onset,
                        "duration": n.duration,
                        "frequency_hz": n.frequency_hz,
                        "amplitude": n.amplitude
                    })
                
                chords_json = []
                if result.harmony:
                    for c in result.harmony.chords_timeline:
                        chords_json.append({
                            "chord": c.chord,
                            "start": c.start,
                            "end": c.end,
                            "confidence": c.confidence
                        })
                
                # Récupérer l'URL MIDI uploadée lors du pipeline si présente
                midi_storage_path = options.get("midi_storage_url")
                
                db.table("analyses").update({
                    "status": "completed" if result.status == PipelineStatus.SUCCESS else "error",
                    "detected_key": result.harmony.key_signature if result.harmony else None,
                    "time_signature": result.sheet_music.time_signature if result.sheet_music else "4/4",
                    "tempo_bpm": result.audio_features.bpm if result.audio_features else 120.0,
                    "notes_sequence": notes_json,
                    "chords_sequence": result.harmony.chord_progression if result.harmony else [],
                    "midi_storage_path": midi_storage_path,
                    "processing_time_ms": result.total_duration_ms,
                    "error_message": "; ".join(result.warnings) if result.warnings else None,
                    "updated_at": "now()"
                }).eq("id", db_analysis_id).execute()
                logger.info(f"[{job_id}] Successfully persisted analysis results to Supabase analyses table (ID: {db_analysis_id})")
            except Exception as dbe:
                logger.warning(f"Failed to update final Supabase analysis record: {dbe}")

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
            
            # Upload du MIDI vers Supabase Storage si authentifié
            user_id = opts.get("user_id")
            if notes and midi_path and os.path.exists(midi_path) and user_id:
                try:
                    with open(midi_path, "rb") as f:
                        midi_data = f.read()
                    midi_storage_path = f"{user_id}/midi/{result.job_id}.mid"
                    midi_url = await upload_to_storage("midi-outputs", midi_storage_path, midi_data, "audio/midi")
                    opts["midi_storage_url"] = midi_url
                    logger.info(f"[{result.job_id}] Successfully uploaded MIDI file to Supabase Storage: {midi_url}")
                except Exception as midi_err:
                    logger.warning(f"Failed to upload MIDI file to Supabase Storage: {midi_err}")

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

                    # Déterminer les URLs de téléchargement (locales par défaut, Supabase si authentifié)
                    pdf_url = f"/exports/{final_pdf_name}"
                    svg_url = f"/exports/{final_svg_name}"
                    
                    user_id = opts.get("user_id")
                    if user_id:
                        try:
                            if pdf_path and os.path.exists(pdf_path):
                                with open(pdf_path, "rb") as f:
                                    pdf_data = f.read()
                                pdf_storage_path = f"{user_id}/partitions/partition_{export_id}.pdf"
                                pdf_url = await upload_to_storage("partitions", pdf_storage_path, pdf_data, "application/pdf")
                            
                            if svg_path and os.path.exists(svg_path):
                                with open(svg_path, "rb") as f:
                                    svg_data = f.read()
                                svg_storage_path = f"{user_id}/partitions/partition_{export_id}.svg"
                                svg_url = await upload_to_storage("partitions", svg_storage_path, svg_data, "image/svg+xml")
                            logger.info(f"[{result.job_id}] Successfully uploaded partitions (PDF/SVG) to Supabase Storage.")
                        except Exception as storage_err:
                            logger.warning(f"Failed to upload partitions to Supabase Storage: {storage_err}")

                    result.sheet_music = SheetMusicResult(
                        musicxml_path=xml_path,
                        pdf_path=pdf_url,
                        svg_path=svg_url,
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
