import anthropic, json, re
from typing import Dict, Any, List, Optional
from config import settings
from openai import AsyncOpenAI

# Détecter si on doit utiliser Groq (si la clé commence par gsk_)
is_groq = settings.OPENAI_API_KEY.startswith("gsk_")
base_url = "https://api.groq.com/openai/v1" if is_groq else None

# Client OpenAI / Groq
_openai = AsyncOpenAI(api_key=settings.OPENAI_API_KEY, base_url=base_url)

# Client Anthropic (gardé pour compatibilité)
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
    Génère un cours complet et structuré via Groq/OpenAI ou Anthropic.
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

    content = ""
    try:
        model = "llama-3.3-70b-versatile" if is_groq else "gpt-4o"
        response = await _openai.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT_COURSES},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        content = response.choices[0].message.content
    except Exception:
        try:
            message = _claude.messages.create(
                model="claude-3-5-sonnet-latest",
                max_tokens=4000,
                system=SYSTEM_PROMPT_COURSES,
                messages=[{"role": "user", "content": prompt}]
            )
            content = message.content[0].text.strip()
        except Exception as e:
            return {"error": f"IA inaccessible : {str(e)}", "title": topic}

    content = content.strip()
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
