"""
ÉTAPES DU PIPELINE
==================
Chaque outil (FFmpeg, Librosa, Basic Pitch, music21, Whisper, OpenCV, GPT-4o)
est encapsulé dans une fonction async qui retourne (données, StepResult).

Principe :
- Jamais de crash silencieux — chaque erreur est capturée et loggée dans StepResult
- Chaque étape est indépendante et testable seule
- Les fallbacks sont explicites (status="fallback")
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


# ══════════════════════════════════════════
# ÉTAPE 1a : FFmpeg — Normalisation audio
# ══════════════════════════════════════════

async def step_ffmpeg_normalize(input_path: str, tmpdir: str) -> Tuple[str, StepResult]:
    elapsed = _timer()
    out_path = os.path.join(tmpdir, "normalized.wav")

    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", input_path,
             "-ac", "1", "-ar", "44100",
             "-af", "loudnorm",
             out_path],
            capture_output=True, text=True, timeout=120
        )
        if result.returncode == 0 and os.path.exists(out_path):
            return out_path, StepResult(
                name="ffmpeg_normalize", tool="ffmpeg",
                status="ok", duration_ms=elapsed(),
                data={"output": out_path}
            )
        else:
            # FFmpeg absent ou erreur → copie brute
            shutil.copy(input_path, out_path)
            return out_path, StepResult(
                name="ffmpeg_normalize", tool="ffmpeg",
                status="fallback", duration_ms=elapsed(),
                data={"output": out_path},
                error=result.stderr[-300:] if result.stderr else "ffmpeg error"
            )
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        shutil.copy(input_path, out_path)
        return out_path, StepResult(
            name="ffmpeg_normalize", tool="ffmpeg",
            status="fallback", duration_ms=elapsed(),
            data={"output": out_path},
            error=f"ffmpeg indisponible: {e}"
        )


# ══════════════════════════════════════════
# ÉTAPE 1b : FFmpeg — Extraction audio depuis vidéo
# ══════════════════════════════════════════

async def step_ffmpeg_extract_audio(video_path: str, tmpdir: str) -> Tuple[Optional[str], StepResult]:
    elapsed = _timer()
    out_path = os.path.join(tmpdir, "extracted_audio.wav")

    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", video_path,
             "-vn",                    # pas de vidéo
             "-ac", "1", "-ar", "44100",
             "-af", "loudnorm",
             out_path],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode == 0 and os.path.exists(out_path):
            size = os.path.getsize(out_path)
            return out_path, StepResult(
                name="ffmpeg_extract_audio", tool="ffmpeg",
                status="ok", duration_ms=elapsed(),
                data={"output": out_path, "size_bytes": size}
            )
        return None, StepResult(
            name="ffmpeg_extract_audio", tool="ffmpeg",
            status="error", duration_ms=elapsed(),
            error=result.stderr[-300:]
        )
    except Exception as e:
        return None, StepResult(
            name="ffmpeg_extract_audio", tool="ffmpeg",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 2 : Librosa — Analyse audio
# ══════════════════════════════════════════

async def step_librosa_analyze(wav_path: str) -> Tuple[Optional[AudioFeatures], StepResult]:
    elapsed = _timer()
    try:
        import librosa

        y, sr = librosa.load(wav_path, sr=44100, mono=True)

        # BPM + beats
        tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
        beat_times = librosa.frames_to_time(beat_frames, sr=sr).tolist()

        # Chroma
        chroma = librosa.feature.chroma_cqt(y=y, sr=sr)
        chroma_mean = chroma.mean(axis=1).tolist()
        note_names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        chroma_profile = {note_names[i]: round(chroma_mean[i], 4) for i in range(12)}

        # Tonalité estimée
        key_index = int(np.argmax(chroma_mean))
        estimated_key = note_names[key_index]

        # Mode majeur/mineur
        major_t = np.array([1,0,1,0,1,1,0,1,0,1,0,1], dtype=float)
        minor_t = np.array([1,0,1,1,0,1,0,1,1,0,1,0], dtype=float)
        cn = np.array(chroma_mean)
        cn /= cn.sum() + 1e-8
        mj = max(np.dot(cn, np.roll(major_t, i)) for i in range(12))
        mn = max(np.dot(cn, np.roll(minor_t, i)) for i in range(12))
        mode = "major" if mj >= mn else "minor"

        # Features spectrales
        spectral_centroid = float(librosa.feature.spectral_centroid(y=y, sr=sr).mean())
        rms = float(librosa.feature.rms(y=y).mean())
        duration = float(librosa.get_duration(y=y, sr=sr))

        af = AudioFeatures(
            bpm=round(float(tempo), 1),
            key=estimated_key,
            mode=mode,
            key_signature=f"{estimated_key} {mode}",
            duration_seconds=round(duration, 2),
            chroma_profile=chroma_profile,
            spectral_centroid=round(spectral_centroid, 1),
            rms_energy=round(rms, 4),
            beat_times=beat_times[:20],
        )

        return af, StepResult(
            name="librosa_analyze", tool="librosa",
            status="ok", duration_ms=elapsed(),
            data={"bpm": af.bpm, "key_signature": af.key_signature}
        )

    except Exception as e:
        logger.error(f"Librosa error: {e}")
        return None, StepResult(
            name="librosa_analyze", tool="librosa",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 3a : Basic Pitch — Extraction MIDI
# ══════════════════════════════════════════

async def step_basic_pitch(
    wav_path: str, tmpdir: str
) -> Tuple[Optional[str], list, StepResult]:
    elapsed = _timer()
    try:
        from basic_pitch.inference import predict
        from basic_pitch import ICASSP_2022_MODEL_PATH

        _, midi_data, note_events = predict(
            wav_path,
            ICASSP_2022_MODEL_PATH,
            onset_threshold=0.5,
            frame_threshold=0.3,
            minimum_note_length=58,
        )

        midi_path = os.path.join(tmpdir, "output.mid")
        midi_data.write(midi_path)

        note_names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        notes = []
        for ne in note_events[:300]:
            start, end, pitch, amplitude = ne[:4]
            octave = (pitch // 12) - 1
            name = note_names[pitch % 12]
            notes.append(Note(
                note=f"{name}{octave}",
                midi=int(pitch),
                onset=round(float(start), 3),
                duration=round(float(end - start), 3),
                frequency_hz=round(float(440 * 2**((pitch - 69) / 12)), 1),
                velocity=int(amplitude * 127),
            ))

        return midi_path, notes, StepResult(
            name="basic_pitch", tool="basic-pitch",
            status="ok", duration_ms=elapsed(),
            data={"notes_count": len(notes), "midi_path": midi_path}
        )

    except ImportError:
        return None, [], StepResult(
            name="basic_pitch", tool="basic-pitch",
            status="skipped", duration_ms=elapsed(),
            error="basic-pitch non installé (pip install basic-pitch)"
        )
    except Exception as e:
        logger.error(f"Basic Pitch error: {e}")
        return None, [], StepResult(
            name="basic_pitch", tool="basic-pitch",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 3b : Librosa fallback — Notes par piptrack
# ══════════════════════════════════════════

async def step_librosa_notes_fallback(wav_path: str) -> Tuple[list, StepResult]:
    elapsed = _timer()
    try:
        import librosa

        y, sr = librosa.load(wav_path, sr=44100)
        pitches, magnitudes = librosa.piptrack(y=y, sr=sr, threshold=0.1)
        note_names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        hop = 512
        notes = []
        prev_midi = None
        onset_time = None

        for fi in range(pitches.shape[1]):
            best = magnitudes[:, fi].argmax()
            hz = pitches[best, fi]
            if hz > 60:
                midi = int(round(librosa.hz_to_midi(hz)))
                t = float(librosa.frames_to_time(fi, sr=sr, hop_length=hop))
                if midi != prev_midi:
                    if prev_midi is not None and onset_time is not None:
                        oct_ = (prev_midi // 12) - 1
                        nm = note_names[prev_midi % 12]
                        notes.append(Note(
                            note=f"{nm}{oct_}",
                            midi=prev_midi,
                            onset=round(onset_time, 3),
                            duration=round(t - onset_time, 3),
                            frequency_hz=round(float(librosa.midi_to_hz(prev_midi)), 1),
                        ))
                    prev_midi = midi
                    onset_time = t

        return notes[:200], StepResult(
            name="librosa_notes_fallback", tool="librosa",
            status="fallback", duration_ms=elapsed(),
            data={"notes_count": len(notes[:200])}
        )
    except Exception as e:
        return [], StepResult(
            name="librosa_notes_fallback", tool="librosa",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 4 : music21 — Analyse harmonique
# ══════════════════════════════════════════

async def step_music21_harmony(
    midi_path: Optional[str],
    notes: list,
    key_hint: str = "",
    target_key: Optional[str] = None,
) -> Tuple[Optional[HarmonyResult], StepResult]:
    elapsed = _timer()
    try:
        from music21 import stream, note as m21note, converter, pitch

        s = stream.Score()
        part = stream.Part()

        # Construire le stream depuis MIDI ou notes
        if midi_path and os.path.exists(midi_path):
            try:
                s = converter.parse(midi_path)
                part = s.parts[0] if s.parts else part
            except Exception as ex:
                logger.warning(f"music21 MIDI parse: {ex}")
                midi_path = None

        if not midi_path or not s.parts:
            for n in notes[:100]:
                try:
                    p = pitch.Pitch(n.note if hasattr(n, 'note') else n['note'])
                    obj = m21note.Note(p)
                    obj.quarterLength = max(0.25, (n.duration if hasattr(n,'duration') else n['duration']) * 2)
                    part.append(obj)
                except Exception:
                    pass
            s.append(part)

        # Analyse de la clé
        key_analysis = {}
        try:
            k = s.analyze("key")
            key_analysis = {
                "key": str(k.tonic.name),
                "mode": str(k.mode),
                "confidence": round(float(k.correlationCoefficient), 4),
                "key_signature": f"{k.tonic.name} {k.mode}",
            }
        except Exception as e:
            key_analysis = {"key_signature": key_hint, "confidence": 0.0}

        # Accords
        chords_found = []
        try:
            cs = s.chordify()
            for c in cs.flatten().getElementsByClass("Chord"):
                chords_found.append(Chord(
                    offset=round(float(c.offset), 2),
                    root=c.root().name if c.root() else "?",
                    quality=c.quality,
                    name=c.commonName,
                    pitches=[str(p) for p in c.pitches],
                ))
        except Exception as e:
            logger.warning(f"Chordify: {e}")

        # Progression dédupliquée
        progression = []
        prev = None
        for c in chords_found[:64]:
            lbl = f"{c.root} {c.quality}"
            if lbl != prev:
                progression.append(lbl)
                prev = lbl

        # Export MusicXML
        musicxml = None
        try:
            # Transposition si demandée
            if target_key:
                from music21 import key as m21key
                parts = target_key.strip().split()
                if len(parts) >= 2:
                    target_k = m21key.Key(parts[0], parts[1])
                    source_k = s.analyze("key")
                    interval = m21note.interval.Interval(source_k.tonic, target_k.tonic)
                    s = s.transpose(interval)

            musicxml = s.write("musicxml")
            # Lire le fichier écrit
            if musicxml and os.path.exists(str(musicxml)):
                with open(str(musicxml), 'r', encoding='utf-8') as f:
                    musicxml = f.read()
        except Exception as e:
            logger.warning(f"MusicXML export: {e}")
            musicxml = None

        harmony = HarmonyResult(
            key_signature=key_analysis.get("key_signature", key_hint),
            key_confidence=key_analysis.get("confidence", 0.0),
            chord_progression=progression[:16],
            chords_timeline=[
                {"offset": c.offset, "root": c.root, "quality": c.quality, "name": c.name}
                for c in chords_found[:32]
            ],
            total_chords=len(chords_found),
            musicxml=musicxml,
        )

        return harmony, StepResult(
            name="music21_harmony", tool="music21",
            status="ok", duration_ms=elapsed(),
            data={
                "key_signature": harmony.key_signature,
                "total_chords": harmony.total_chords,
                "progression": progression[:8],
                "has_musicxml": musicxml is not None,
            }
        )

    except Exception as e:
        logger.error(f"music21 error: {e}")
        return None, StepResult(
            name="music21_harmony", tool="music21",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 5 : Whisper — Transcription paroles
# ══════════════════════════════════════════

async def step_whisper_transcribe(audio_path: str) -> Tuple[Optional[LyricsResult], StepResult]:
    elapsed = _timer()
    try:
        import whisper
        model = whisper.load_model("base")
        result = model.transcribe(audio_path)

        lyrics = LyricsResult(
            text=result.get("text", "").strip(),
            language=result.get("language", ""),
            segments=[
                {"start": seg["start"], "end": seg["end"], "text": seg["text"]}
                for seg in result.get("segments", [])[:50]
            ],
        )
        return lyrics, StepResult(
            name="whisper_transcribe", tool="openai-whisper",
            status="ok", duration_ms=elapsed(),
            data={"language": lyrics.language, "words": len(lyrics.text.split())}
        )
    except ImportError:
        return None, StepResult(
            name="whisper_transcribe", tool="openai-whisper",
            status="skipped", duration_ms=elapsed(),
            error="whisper non installé (pip install openai-whisper)"
        )
    except Exception as e:
        return None, StepResult(
            name="whisper_transcribe", tool="openai-whisper",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 6 : OpenCV — Préprocessing image partition
# ══════════════════════════════════════════

async def step_opencv_preprocess(image_path: str) -> Tuple[Optional[str], StepResult]:
    elapsed = _timer()
    try:
        import cv2

        img = cv2.imread(image_path)
        if img is None:
            return None, StepResult(
                name="opencv_preprocess", tool="opencv",
                status="error", duration_ms=elapsed(),
                error="Image non lisible"
            )

        # Convertir en niveaux de gris
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Deskew — redresser l'image si penchée
        coords = np.column_stack(np.where(gray < 128))
        if len(coords) > 0:
            angle = cv2.minAreaRect(coords.astype(np.float32))[-1]
            if angle < -45:
                angle = -(90 + angle)
            else:
                angle = -angle
            if abs(angle) > 0.5:
                h, w = gray.shape
                M = cv2.getRotationMatrix2D((w//2, h//2), angle, 1.0)
                gray = cv2.warpAffine(gray, M, (w, h), flags=cv2.INTER_CUBIC,
                                      borderMode=cv2.BORDER_REPLICATE)

        # Amélioration contraste (CLAHE)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Sauvegarder
        out_path = image_path.rsplit(".", 1)[0] + "_clean.png"
        cv2.imwrite(out_path, enhanced)

        return out_path, StepResult(
            name="opencv_preprocess", tool="opencv",
            status="ok", duration_ms=elapsed(),
            data={"output": out_path, "deskew_angle": round(angle if len(coords) > 0 else 0, 2)}
        )

    except ImportError:
        return None, StepResult(
            name="opencv_preprocess", tool="opencv",
            status="skipped", duration_ms=elapsed(),
            error="opencv-python non installé"
        )
    except Exception as e:
        return image_path, StepResult(
            name="opencv_preprocess", tool="opencv",
            status="fallback", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 7 : GPT-4o Vision — Lecture partition
# ══════════════════════════════════════════

async def step_gpt4o_vision_read_sheet(
    image_path: str, api_key: str
) -> Tuple[Optional[SheetMusicResult], StepResult]:
    elapsed = _timer()

    if not api_key:
        return None, StepResult(
            name="gpt4o_vision", tool="openai-gpt4o",
            status="skipped", duration_ms=elapsed(),
            error="OPENAI_API_KEY manquante"
        )

    try:
        import base64, httpx, json

        with open(image_path, "rb") as f:
            img_b64 = base64.b64encode(f.read()).decode()

        ext = image_path.rsplit(".", 1)[-1].lower()
        mime = {"png": "image/png", "jpg": "image/jpeg",
                "jpeg": "image/jpeg", "pdf": "application/pdf"}.get(ext, "image/png")

        prompt = """Analyse cette partition musicale et retourne un JSON structuré avec :
{
  "key_signature": "ex: A minor",
  "time_signature": "ex: 4/4",
  "clef": "treble|bass|alto",
  "tempo_marking": "ex: Allegro, 120 BPM",
  "dynamics": ["mf", "f", "pp"],
  "notes": [
    {"note": "A4", "duration": "quarter", "beat": 1.0, "measure": 1},
    ...
  ],
  "raw_text": "description libre de la partition"
}
Retourne UNIQUEMENT le JSON, sans markdown."""

        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {api_key}",
                         "Content-Type": "application/json"},
                json={
                    "model": "gpt-4o",
                    "max_tokens": 2000,
                    "messages": [{
                        "role": "user",
                        "content": [
                            {"type": "image_url",
                             "image_url": {"url": f"data:{mime};base64,{img_b64}"}},
                            {"type": "text", "text": prompt}
                        ]
                    }]
                }
            )

        resp.raise_for_status()
        text = resp.json()["choices"][0]["message"]["content"]

        try:
            data = json.loads(text.strip())
        except json.JSONDecodeError:
            # GPT parfois ajoute du markdown malgré tout
            import re
            m = re.search(r'\{.*\}', text, re.DOTALL)
            data = json.loads(m.group()) if m else {}

        sheet = SheetMusicResult(
            notes_raw=data.get("raw_text", ""),
            notes_structured=data.get("notes", []),
            key_signature=data.get("key_signature", ""),
            time_signature=data.get("time_signature", ""),
            clef=data.get("clef", ""),
            tempo_marking=data.get("tempo_marking", ""),
            dynamics=data.get("dynamics", []),
        )

        return sheet, StepResult(
            name="gpt4o_vision", tool="openai-gpt4o",
            status="ok", duration_ms=elapsed(),
            data={
                "notes_count": len(sheet.notes_structured),
                "key_signature": sheet.key_signature,
            }
        )

    except Exception as e:
        logger.error(f"GPT-4o Vision error: {e}")
        return None, StepResult(
            name="gpt4o_vision", tool="openai-gpt4o",
            status="error", duration_ms=elapsed(), error=str(e)
        )


# ══════════════════════════════════════════
# ÉTAPE 8 : music21 depuis partition lue
# ══════════════════════════════════════════

async def step_music21_from_sheet(
    sheet: SheetMusicResult
) -> Tuple[Optional[HarmonyResult], StepResult]:
    elapsed = _timer()
    try:
        from music21 import stream, note as m21note, pitch, duration as m21dur

        dur_map = {
            "whole": 4.0, "half": 2.0, "quarter": 1.0,
            "eighth": 0.5, "sixteenth": 0.25, "dotted quarter": 1.5
        }

        part = stream.Part()
        for n in sheet.notes_structured[:100]:
            try:
                p = pitch.Pitch(n.get("note", "C4"))
                obj = m21note.Note(p)
                d = dur_map.get(n.get("duration", "quarter"), 1.0)
                obj.quarterLength = d
                part.append(obj)
            except Exception:
                pass

        s = stream.Score()
        s.append(part)

        notes_as_list = [
            Note(
                note=n.get("note","C4"), midi=60,
                onset=n.get("beat", 0.0), duration=1.0,
                frequency_hz=440.0
            )
            for n in sheet.notes_structured[:100]
        ]

        return await step_music21_harmony(None, notes_as_list, sheet.key_signature)

    except Exception as e:
        return None, StepResult(
            name="music21_from_sheet", tool="music21",
            status="error", duration_ms=elapsed(), error=str(e)
        )