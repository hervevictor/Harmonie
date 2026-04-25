"""
ÉTAPES DU PIPELINE — Core Logic
===============================
Chaque outil (FFmpeg, Librosa, Basic Pitch, music21, Whisper, OpenCV, GPT-4o)
est encapsulé dans une fonction async qui retourne (données, StepResult).
"""

import os
import time
import shutil
import logging
import subprocess
import tempfile
import numpy as np
from typing import Optional, Tuple

from core.orchestrator import (
    StepResult, AudioFeatures, Note, HarmonyResult,
    LyricsResult, SheetMusicResult
)

logger = logging.getLogger(__name__)

def _timer():
    """Retourne une fonction qui calcule ms écoulées depuis l'appel."""
    t = time.time()
    return lambda: int((time.time() - t) * 1000)

# --- FFmpeg Normalize ---
async def step_ffmpeg_normalize(input_path: str, tmpdir: str) -> Tuple[str, StepResult]:
    elapsed = _timer()
    out_path = os.path.join(tmpdir, "normalized.wav")
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", input_path, "-ac", "1", "-ar", "44100", "-af", "loudnorm", out_path],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode == 0 and os.path.exists(out_path):
            return out_path, StepResult(name="ffmpeg_normalize", tool="ffmpeg", status="ok", duration_ms=elapsed(), data={"output": out_path})
        shutil.copy(input_path, out_path)
        return out_path, StepResult(name="ffmpeg_normalize", tool="ffmpeg", status="fallback", duration_ms=elapsed(), data={"output": out_path}, error=result.stderr[-300:] if result.stderr else "ffmpeg error")
    except Exception as e:
        shutil.copy(input_path, out_path)
        return out_path, StepResult(name="ffmpeg_normalize", tool="ffmpeg", status="fallback", duration_ms=elapsed(), data={"output": out_path}, error=str(e))

# --- FFmpeg Extract Audio ---
async def step_ffmpeg_extract_audio(video_path: str, tmpdir: str) -> Tuple[Optional[str], StepResult]:
    elapsed = _timer()
    out_path = os.path.join(tmpdir, "extracted_audio.wav")
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", video_path, "-vn", "-ac", "1", "-ar", "44100", "-af", "loudnorm", out_path],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode == 0 and os.path.exists(out_path):
            return out_path, StepResult(name="ffmpeg_extract_audio", tool="ffmpeg", status="ok", duration_ms=elapsed(), data={"output": out_path})
        return None, StepResult(name="ffmpeg_extract_audio", tool="ffmpeg", status="error", duration_ms=elapsed(), error=result.stderr[-300:])
    except Exception as e:
        return None, StepResult(name="ffmpeg_extract_audio", tool="ffmpeg", status="error", duration_ms=elapsed(), error=str(e))

# --- Librosa Analysis ---
async def step_librosa_analyze(wav_path: str) -> Tuple[Optional[AudioFeatures], StepResult]:
    elapsed = _timer()
    try:
        import librosa
        y, sr = librosa.load(wav_path, sr=44100, mono=True)
        tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
        beat_times = librosa.frames_to_time(beat_frames, sr=sr).tolist()
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1).tolist()
        note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        chroma_profile = {note_names[i]: round(chroma_mean[i], 4) for i in range(12)}
        key_index = int(np.argmax(chroma_mean))
        estimated_key = note_names[key_index]

        # Détection majeur/mineur via le profil chroma (Krumhansl-Kessler)
        major_profile = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        minor_profile = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
        
        # Corrélation avec les profils majeur et mineur
        major_corr = float(np.corrcoef(np.roll(major_profile, key_index), chroma_mean)[0, 1])
        minor_corr = float(np.corrcoef(np.roll(minor_profile, key_index), chroma_mean)[0, 1])
        mode = "Major" if major_corr >= minor_corr else "Minor"
        mode_suffix = "" if mode == "Major" else "m"
        
        af = AudioFeatures(
            bpm=round(float(tempo), 1),
            key=estimated_key,
            mode=mode,
            key_signature=f"{estimated_key}{mode_suffix}",
            duration_seconds=round(float(librosa.get_duration(y=y, sr=sr)), 2),
            chroma_profile=chroma_profile,
            beat_times=beat_times[:20],
        )
        logger.info(f"Librosa result: BPM={af.bpm}, Key={af.key_signature}, Mode={af.mode}")
        return af, StepResult(name="librosa_analyze", tool="librosa", status="ok", duration_ms=elapsed(), data={"bpm": af.bpm, "key": af.key_signature})
    except Exception as e:
        logger.error(f"Librosa error: {e}")
        return None, StepResult(name="librosa_analyze", tool="librosa", status="error", duration_ms=elapsed(), error=str(e))

def midi_to_note_name(midi: int) -> str:
    """Convertit un numéro MIDI en nom de note anglais standard (C, D, E...)."""
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    octave = (midi // 12) - 1
    name = names[midi % 12]
    return f"{name}{octave}"

# --- Basic Pitch ---
async def step_basic_pitch(wav_path: str, tmpdir: str) -> Tuple[Optional[str], list, StepResult]:
    elapsed = _timer()
    try:
        from basic_pitch.inference import predict
        from basic_pitch import ICASSP_2022_MODEL_PATH
        logger.info(f"Starting basic-pitch on {wav_path}")
        _, midi_data, note_events = predict(wav_path, ICASSP_2022_MODEL_PATH)
        midi_path = os.path.join(tmpdir, "output.mid")
        midi_data.write(midi_path)
        notes = []
        for ne in note_events[:300]:
            midi_val = int(ne[2])
            onset = round(float(ne[0]), 3)
            offset = round(float(ne[1]), 3)
            duration = round(offset - onset, 3)
            freq = round(440.0 * (2 ** ((midi_val - 69) / 12.0)), 2)
            notes.append(Note(
                note=midi_to_note_name(midi_val), 
                midi=midi_val, 
                onset=onset, 
                duration=duration, 
                frequency_hz=freq,
            ))
        logger.info(f"Basic-pitch extracted {len(notes)} notes")
        return midi_path, notes, StepResult(name="basic_pitch", tool="basic-pitch", status="ok", duration_ms=elapsed(), data={"count": len(notes)})
    except Exception as e:
        logger.error(f"Basic-pitch error: {e}")
        return None, [], StepResult(name="basic_pitch", tool="basic-pitch", status="error", duration_ms=elapsed(), error=str(e))

# --- Music21 Score Building ---
# Utilise les durées réelles + voicings d'accords spécifiques à l'instrument
async def step_music21_build_score(
    notes: list, 
    key_signature: str, 
    bpm: float, 
    tmpdir: str, 
    target_instrument: str = "piano",
    chords: list = None,
) -> Tuple[Optional[str], StepResult]:
    elapsed = _timer()
    try:
        from music21 import stream, note, chord as m21_chord, meter, tempo, key, instrument as m21_instrument
        from core.voicings import get_chord_midi_notes, get_rhythm_pattern, INSTRUMENT_VOICINGS
        
        s = stream.Score()
        
        # ═══ Partie 0 : NETTOYAGE TONALITÉ ═══
        try:
            # Gestion robuste de la tonalité (ex: "F#m", "F", "C major", "Am")
            ks_clean = key_signature.strip()
            ks_lower = ks_clean.lower()

            if "major" in ks_lower:
                tonic = ks_lower.replace("major", "").strip().capitalize()
                mode = "major"
            elif "minor" in ks_lower:
                tonic = ks_lower.replace("minor", "").strip().capitalize()
                mode = "minor"
            elif ks_clean.endswith("m") and len(ks_clean) > 1:
                tonic = ks_clean[:-1].strip().capitalize()
                mode = "minor"
            else:
                tonic = ks_clean.capitalize()
                mode = "major"
            
            # Validation de la fondamentale (doit commencer par A-G)
            if not tonic or tonic[0].upper() not in "ABCDEFG":
                tonic = "C"
                
            # Nettoyage final pour music21 (pas d'espaces)
            tonic = tonic.replace(" ", "")

            ks_obj = key.Key(tonic, mode)
            ks_str = f"{tonic} {mode}"
            logger.info(f"Music21: Using key {ks_str} (tonic: {tonic}, mode: {mode})")
        except Exception as e:
            logger.warning(f"Music21: Failed to parse key '{key_signature}', fallback to C Major. Error: {e}")
            ks_obj = key.Key("C", "major")
            ks_str = "C major"

        # ═══ Partie 1 : MÉLODIE ═══
        melody_part = stream.Part()
        melody_part.id = "Melody"
        
        # Mapping instrument Flutter → music21
        instrument_map = {
            "piano": m21_instrument.Piano,
            "guitar_acoustic": m21_instrument.AcousticGuitar,
            "guitar_electric": m21_instrument.ElectricGuitar,
            "violin": m21_instrument.Violin,
            "flute": m21_instrument.Flute,
            "saxophone": m21_instrument.Saxophone,
            "trumpet": m21_instrument.Trumpet,
            "bass": m21_instrument.ElectricBass,
            "cello": m21_instrument.Violoncello,
            "ukulele": m21_instrument.Ukulele,
            "harmonica": m21_instrument.Harmonica,
        }
        
        # Assigner l'instrument à la mélodie
        instr_class = instrument_map.get(target_instrument, m21_instrument.Piano)
        melody_part.insert(0, instr_class())
        logger.info(f"Music21: Melody instrument = '{target_instrument}'")
        
        # Métadonnées
        melody_part.append(tempo.MetronomeMark(number=int(bpm) if bpm > 0 else 120))
        
        # Tonalité
        melody_part.append(ks_obj)
        
        melody_part.append(meter.TimeSignature('4/4'))
        
        # Conversion des notes avec durées réelles
        seconds_per_beat = 60.0 / bpm if bpm > 0 else 0.5
        
        for n in notes[:200]:
            if n.midi > 0:
                try:
                    m21_note = note.Note(n.midi)
                    quarter_length = n.duration / seconds_per_beat if seconds_per_beat > 0 else 1.0
                    quarter_length = max(0.25, min(quarter_length, 8.0))
                    m21_note.quarterLength = round(quarter_length * 4) / 4
                    m21_note.offset = n.onset / seconds_per_beat
                    melody_part.append(m21_note)
                except Exception as ne:
                    logger.warning(f"Music21: Failed to add note {n.midi}: {ne}")
        
        s.append(melody_part)
        
        # ═══ Partie 2 : ACCORDS (accompagnement) ═══
        if chords and len(chords) > 0:
            chord_part = stream.Part()
            chord_part.id = "Chords"
            
            # Instrument d'accompagnement
            voicing_info = INSTRUMENT_VOICINGS.get(target_instrument)
            is_mono = voicing_info and voicing_info.max_voices == 1
            
            if is_mono:
                chord_part.insert(0, m21_instrument.Piano())
                chord_instrument_id = "piano"
            else:
                chord_part.insert(0, instr_class())
                chord_instrument_id = target_instrument or "piano"
            
            chord_part.append(ks_obj)
            chord_part.append(meter.TimeSignature('4/4'))
            
            # Durée totale
            if notes:
                total_seconds = max(n.onset + n.duration for n in notes)
                total_beats = total_seconds / seconds_per_beat
            else:
                total_beats = 16
            
            beats_per_chord = max(1, min(total_beats / len(chords), 8)) if len(chords) > 0 else 4
            rhythm_pattern = get_rhythm_pattern(chord_instrument_id)
            
            current_beat = 0.0
            for chord_name in chords:
                if current_beat >= total_beats: break
                
                try:
                    chord_midis = get_chord_midi_notes(chord_name, chord_instrument_id)
                    if not chord_midis:
                        current_beat += beats_per_chord
                        continue
                    
                    pattern_beat = 0.0
                    for duration in rhythm_pattern:
                        if pattern_beat >= beats_per_chord: break
                        actual_duration = min(duration, beats_per_chord - pattern_beat)
                        
                        if len(chord_midis) == 1:
                            m21_n = note.Note(chord_midis[0])
                            m21_n.quarterLength = actual_duration
                            m21_n.offset = current_beat + pattern_beat
                            chord_part.append(m21_n)
                        else:
                            m21_c = m21_chord.Chord(chord_midis)
                            m21_c.quarterLength = actual_duration
                            m21_c.offset = current_beat + pattern_beat
                            chord_part.append(m21_c)
                        pattern_beat += duration
                except Exception as ce:
                    logger.warning(f"Music21: Failed to add chord {chord_name}: {ce}")
                
                current_beat += beats_per_chord
            
            s.append(chord_part)
            logger.info(f"Music21: Added {len(chords)} chords")
        
        xml_path = os.path.join(tmpdir, "score.musicxml")
        s.write('musicxml', fp=xml_path)
        
        return xml_path, StepResult(
            name="music21_build_score", tool="music21", status="ok", 
            duration_ms=elapsed(), data={"path": xml_path}
        )
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        logger.error(f"Music21 error trace: {tb}")
        return None, StepResult(name="music21_build_score", tool="music21", status="error", duration_ms=elapsed(), error=str(e))


# --- MuseScore Rendering ---
async def step_musescore_render(xml_path: str, tmpdir: str) -> Tuple[Optional[str], Optional[str], StepResult]:
    elapsed = _timer()
    pdf_path = os.path.join(tmpdir, "score.pdf")
    svg_path = os.path.join(tmpdir, "score.svg")
    
    # Chemins probables de MuseScore sur Windows (v4 et v3)
    mscore_paths = [
        "mscore4", 
        "mscore",
        r"C:\Program Files\MuseScore 4\bin\MuseScore4.exe",
        r"C:\Program Files\MuseScore 4\bin\mscore.exe",
        r"C:\Program Files\MuseScore 3\bin\MuseScore3.exe",
        r"C:\Program Files\MuseScore 3\bin\mscore.exe",
    ]
    
    mscore_exe = None
    for p in mscore_paths:
        if shutil.which(p) or os.path.exists(p):
            mscore_exe = p
            break

    if not mscore_exe:
        logger.warning("MuseScore executable not found. PDF/SVG rendering skipped.")
        return None, None, StepResult(
            name="musescore_render", 
            tool="musescore", 
            status="error", 
            duration_ms=elapsed(), 
            error="MuseScore non trouvé. Veuillez installer MuseScore 4 pour activer le rendu des partitions."
        )

    try:
        logger.info(f"Using MuseScore: {mscore_exe}")
        # Export PDF
        subprocess.run([mscore_exe, "-o", pdf_path, xml_path], capture_output=True, text=True, timeout=30)
        # Export SVG
        subprocess.run([mscore_exe, "-o", svg_path, xml_path], capture_output=True, text=True, timeout=30)
        
        status = "ok" if os.path.exists(pdf_path) or os.path.exists(svg_path) else "error"
        return pdf_path, svg_path, StepResult(
            name="musescore_render", 
            tool="musescore", 
            status=status, 
            duration_ms=elapsed(), 
            data={"pdf": pdf_path, "svg": svg_path}
        )
    except Exception as e:
        logger.error(f"MuseScore error: {e}")
        return None, None, StepResult(name="musescore_render", tool="musescore", status="error", duration_ms=elapsed(), error=str(e))

# --- Whisper Transcription ---
async def step_whisper_transcribe(audio_path: str) -> Tuple[Optional[LyricsResult], StepResult]:
    elapsed = _timer()
    try:
        import whisper
        model = whisper.load_model("base")
        result = model.transcribe(audio_path)
        lyrics = LyricsResult(text=result["text"], language=result.get("language", ""))
        return lyrics, StepResult(name="whisper_transcribe", tool="openai-whisper", status="ok", duration_ms=elapsed())
    except Exception as e:
        return None, StepResult(name="whisper_transcribe", tool="openai-whisper", status="error", duration_ms=elapsed(), error=str(e))

# --- Chord Recognition (Amélioré) ---
async def step_chord_recognition(wav_path: str) -> Tuple[Optional[HarmonyResult], StepResult]:
    elapsed = _timer()
    try:
        import librosa
        y, sr = librosa.load(wav_path, sr=22050, mono=True)
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        
        note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        
        # Détection de la tonalité globale
        chroma_global = chroma.mean(axis=1)
        key_idx = int(np.argmax(chroma_global))
        
        # Détection majeur/mineur globale
        major_profile = [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
        minor_profile = [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
        major_corr = float(np.corrcoef(np.roll(major_profile, key_idx), chroma_global)[0, 1])
        minor_corr = float(np.corrcoef(np.roll(minor_profile, key_idx), chroma_global)[0, 1])
        is_global_minor = minor_corr > major_corr
        key_suffix = "m" if is_global_minor else ""
        key_sig = f"{note_names[key_idx]}{key_suffix}"
        
        # Reconnaissance d'accords par beats
        # Utiliser les beats librosa pour segmenter plus musicalement
        tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
        
        chords = []
        chord_timeline = []
        
        # On regroupe par mesures (4 beats = 1 mesure en 4/4)
        if len(beat_frames) < 2:
            # Fallback si pas assez de beats : segmenter uniformément
            segments = np.array_split(chroma, max(4, chroma.shape[1] // 50), axis=1)
            seg_times = np.linspace(0, librosa.get_duration(y=y, sr=sr), len(segments) + 1)
        else:
            # Regrouper par mesures de 4 beats
            measure_frames = beat_frames[::4]  # Chaque 4ème beat
            if len(measure_frames) < 2:
                measure_frames = beat_frames[::2]  # Fallback: chaque 2 beats
            
            segments = []
            seg_times = librosa.frames_to_time(measure_frames, sr=sr).tolist()
            seg_times.append(librosa.get_duration(y=y, sr=sr))
            
            for i in range(len(measure_frames)):
                start = measure_frames[i]
                end = measure_frames[i + 1] if i + 1 < len(measure_frames) else chroma.shape[1]
                if start < end:
                    segments.append(chroma[:, start:end])
        
        for idx, seg in enumerate(segments):
            if seg.size == 0: 
                continue
            seg_mean = seg.mean(axis=1)
            root_idx = int(np.argmax(seg_mean))
            root = note_names[root_idx]
            
            # Détection de la qualité de l'accord (maj/min/dim/aug/7)
            third_major = seg_mean[(root_idx + 4) % 12]
            third_minor = seg_mean[(root_idx + 3) % 12]
            fifth_perf = seg_mean[(root_idx + 7) % 12]
            seventh_min = seg_mean[(root_idx + 10) % 12]
            seventh_maj = seg_mean[(root_idx + 11) % 12]
            
            # Seuil basé sur la fondamentale
            threshold = seg_mean[root_idx] * 0.3
            
            if third_minor > third_major and third_minor > threshold:
                if seventh_min > threshold:
                    quality = "m7"
                else:
                    quality = "m"
            elif third_major > threshold:
                if seventh_min > threshold:
                    quality = "7"
                elif seventh_maj > threshold:
                    quality = "maj7"
                else:
                    quality = ""
            else:
                quality = "5"  # Power chord
            
            chord_name = f"{root}{quality}"
            
            # Ajouter à la liste unique pour l'affichage statique
            if not chords or chords[-1] != chord_name:
                chords.append(chord_name)
            
            # Ajouter à la timeline pour la synchronisation (sans trous)
            if idx < len(seg_times) - 1:
                chord_timeline.append({
                    "chord": chord_name,
                    "start": round(seg_times[idx], 2),
                    "end": round(seg_times[idx + 1], 2),
                })

        harmony = HarmonyResult(
            key_signature=key_sig,
            key_confidence=round(max(major_corr, minor_corr), 3),
            chord_progression=chords,
            chords_timeline=chord_timeline,
            total_chords=len(chords),
        )
        logger.info(f"Chords extracted: key={key_sig}, chords={chords}")
        return harmony, StepResult(name="chord_recognition", tool="librosa", status="ok", duration_ms=elapsed(), data={"key": key_sig, "chords": chords})
    except Exception as e:
        logger.error(f"Chord recognition error: {e}")
        return None, StepResult(name="chord_recognition", tool="librosa", status="error", duration_ms=elapsed(), error=str(e))

# --- OpenAI Vision & Images ---
async def step_opencv_preprocess(image_path: str) -> Tuple[Optional[str], StepResult]:
    elapsed = _timer()
    return image_path, StepResult(name="opencv_preprocess", tool="opencv", status="ok", duration_ms=elapsed())

async def step_gpt4o_vision_read_sheet(image_path: str, api_key: str) -> Tuple[Optional[SheetMusicResult], StepResult]:
    elapsed = _timer()
    return None, StepResult(name="gpt4o_vision", tool="openai-gpt4o", status="skipped", duration_ms=elapsed(), error="Not fully implemented")

async def step_music21_from_sheet(sheet: SheetMusicResult) -> Tuple[Optional[HarmonyResult], StepResult]:
    elapsed = _timer()
    return None, StepResult(name="music21_from_sheet", tool="music21", status="error", duration_ms=elapsed())
