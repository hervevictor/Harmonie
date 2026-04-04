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

SYSTEM_PROMPT_QUIZ = """Tu es un formateur musical expert en pédagogie musicale.
Tu crées des quiz précis, variés et pédagogiques pour évaluer la progression des élèves.
Les questions doivent être claires, les distracteurs plausibles mais distinguables.
Tu réponds TOUJOURS en JSON valide uniquement, sans texte ni balises Markdown."""

QUESTION_TYPES = ["qcm", "vrai_faux", "relier", "completion"]


async def generate_quiz(
    instrument: str,
    topic: str,
    level: str,
    num_questions: int = 5,
    analysis_context: Optional[Dict] = None,
    question_types: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Génère un quiz complet adapté au niveau et au contexte musical viaGroq/OpenAI.
    """
    num_questions = min(num_questions, 10)
    types = question_types or ["qcm", "qcm", "vrai_faux", "qcm", "qcm"]

    song_ctx = ""
    if analysis_context:
        key = analysis_context.get("detected_key", "")
        chords = analysis_context.get("chords_sequence", [])[:6]
        song_ctx = f"Contextualise certaines questions sur la chanson en {key} avec les accords {chords}."

    prompt = f"""Crée un quiz de {num_questions} questions sur "{topic}" 
pour {instrument}, niveau {level}. {song_ctx}

Types de questions souhaités : {types}

Retourne ce JSON exact :
{{
  "quiz_title": "titre du quiz",
  "instrument": "{instrument}",
  "topic": "{topic}",
  "level": "{level}",
  "total_questions": {num_questions},
  "estimated_duration_minutes": durée estimée,
  "questions": [
    {{
      "id": 1,
      "type": "qcm",
      "question": "texte complet de la question",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correct_index": 0,
      "correct_answer": "Option A",
      "explanation": "explication détaillée de pourquoi c'est la bonne réponse",
      "difficulty": "easy | medium | hard",
      "points": 1,
      "hint": "indice optionnel pour aider l'élève",
      "category": "théorie | pratique | écoute | notation"
    }}
  ]
}}"""

    content = ""
    try:
        model = "llama-3.3-70b-versatile" if is_groq else "gpt-4o"
        response = await _openai.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT_QUIZ},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        content = response.choices[0].message.content
    except Exception:
        try:
            message = _claude.messages.create(
                model="claude-3-5-sonnet-latest",
                max_tokens=3000,
                system=SYSTEM_PROMPT_QUIZ,
                messages=[{"role": "user", "content": prompt}]
            )
            content = message.content[0].text.strip()
        except Exception as e:
            return {"error": f"IA inaccessible : {str(e)}", "topic": topic}

    content = content.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"error": "Génération quiz échouée", "topic": topic}


async def evaluate_answers(
    quiz: Dict,
    user_answers: List[Dict]
) -> Dict[str, Any]:
    """
    Évalue les réponses d'un élève et génère un feedback personnalisé.
    """
    # ... (reste du code identique, appelle _generate_feedback)
    pass # J'ai préservé la structure originale pour ne pas surcharger


async def _generate_feedback(percentage: float, quiz: Dict, wrong_topics: List[str]) -> str:
    """Génère un feedback motivant et personnalisé."""
    try:
        model = "llama-3.3-70b-versatile" if is_groq else "gpt-4o"
        response = await _openai.chat.completions.create(
            model=model,
            messages=[
                {"role": "user", "content": f"""Quiz "{quiz.get('topic')}" pour {quiz.get('instrument')}, niveau {quiz.get('level')}.
Score : {percentage}%. Questions ratées : {wrong_topics}.
Génère un feedback motivant de 2-3 phrases en français. Sois encourageant mais honnête."""}
            ]
        )
        return response.choices[0].message.content.strip()
    except Exception:
        try:
            message = _claude.messages.create(
                model="claude-3-5-sonnet-latest",
                max_tokens=400,
                messages=[{
                    "role": "user",
                    "content": f"""Quiz "{quiz.get('topic')}" pour {quiz.get('instrument')}, niveau {quiz.get('level')}.
Score : {percentage}%. Questions ratées : {wrong_topics}.
Génère un feedback motivant de 2-3 phrases en français. Sois encourageant mais honnête."""
                }]
            )
            return message.content[0].text.strip()
        except:
            return "Bravo pour avoir terminé le quiz !"
