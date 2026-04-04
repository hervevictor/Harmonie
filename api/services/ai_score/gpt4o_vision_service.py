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

    is_groq = settings.OPENAI_API_KEY.startswith("gsk_")
    url = "https://api.groq.com/openai/v1/chat/completions" if is_groq else "https://api.openai.com/v1/chat/completions"
    model = "llama-3.2-11b-vision-preview" if is_groq else "gpt-4o"

    async with httpx.AsyncClient(timeout=45.0) as client:
        response = await client.post(
            url,
            headers={
                "Authorization": f"Bearer {settings.OPENAI_API_KEY}",
                "Content-Type": "application/json"
            },
            json={
                "model": model,
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
                                    "url": f"data:{mime_type};base64,{b64_image}"
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
