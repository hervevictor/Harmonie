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
    questions = quiz.get("questions", [])
    results: List[Dict[str, Any]] = []
    total_score = 0
    max_score = 0
    wrong_topics: List[str] = []

    def normalize_value(value: Any) -> str:
        if value is None:
            return ""
        return str(value).strip().lower()

    for question in questions:
        question_id = question.get("id")
        points = int(question.get("points", 1) or 1)
        max_score += points

        answer_record = next(
            (item for item in user_answers if item.get("question_id") == question_id),
            {}
        )

        question_type = question.get("type", "qcm")
        user_choice = answer_record.get("answer_index")
        user_value = answer_record.get("answer_value")
        correct_answer = question.get("correct_answer")

        is_correct = False
        user_answer_text = ""

        if question_type == "qcm":
            options = question.get("options", []) or []
            if isinstance(user_choice, int) and 0 <= user_choice < len(options):
                user_answer_text = options[user_choice]
                is_correct = user_choice == question.get("correct_index")
        elif question_type == "vrai_faux":
            user_answer_text = str(user_value)
            expected_bool = str(correct_answer).strip().lower() in ["true", "vrai", "1", "oui"]
            provided_bool = str(user_value).strip().lower() in ["true", "vrai", "1", "oui"]
            is_correct = expected_bool == provided_bool
        else:
            user_answer_text = normalize_value(user_value)
            expected_text = normalize_value(correct_answer)
            is_correct = user_answer_text == expected_text

        if not is_correct and question.get("category"):
            wrong_topics.append(question.get("category"))
        elif not is_correct:
            wrong_topics.append(question.get("topic", question.get("question", "Réponse incorrecte")))

        if is_correct:
            total_score += points

        results.append({
            "question_id": question_id,
            "type": question_type,
            "question": question.get("question"),
            "user_answer": user_answer_text,
            "correct_answer": correct_answer,
            "is_correct": is_correct,
            "points_awarded": points if is_correct else 0,
            "max_points": points,
            "explanation": question.get("explanation", ""),
        })

    percentage = int(round((total_score / max_score) * 100)) if max_score else 0
    feedback = await _generate_feedback(percentage, quiz, wrong_topics)

    return {
        "total_score": total_score,
        "max_score": max_score,
        "percentage": percentage,
        "results": results,
        "feedback": feedback,
    }


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
