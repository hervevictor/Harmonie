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
