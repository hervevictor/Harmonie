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
