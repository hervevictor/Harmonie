import anthropic, json, re
from typing import Dict, Any, List, Optional
from config import settings

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
    Génère un quiz complet adapté au niveau et au contexte musical.

    Paramètres :
        instrument      : instrument de l'élève
        topic           : sujet du quiz
        level           : "débutant", "intermédiaire", "avancé"
        num_questions   : nombre de questions (max 10)
        analysis_context: contexte chanson pour questions contextualisées
        question_types  : types de questions à inclure (None = mixte)
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
    }},
    {{
      "id": 2,
      "type": "vrai_faux",
      "question": "affirmation à évaluer",
      "correct_answer": true,
      "explanation": "explication",
      "difficulty": "easy",
      "points": 1,
      "category": "théorie"
    }}
  ]
}}"""

    message = _claude.messages.create(
        model="claude-3-5-sonnet-latest",
        max_tokens=3000,
        system=SYSTEM_PROMPT_QUIZ,
        messages=[{"role": "user", "content": prompt}]
    )

    content = message.content[0].text.strip()
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

    Paramètres :
        quiz        : quiz original avec les questions
        user_answers: [{"question_id": 1, "answer_index": 2, "time_seconds": 15}]
    """
    questions = quiz.get("questions", [])
    results = []
    total_score = 0
    max_score = sum(q.get("points", 1) for q in questions)

    for answer in user_answers:
        q_id = answer.get("question_id")
        question = next((q for q in questions if q["id"] == q_id), None)
        if not question:
            continue

        q_type = question.get("type", "qcm")
        is_correct = False

        if q_type == "qcm":
            is_correct = answer.get("answer_index") == question.get("correct_index")
        elif q_type == "vrai_faux":
            is_correct = answer.get("answer_value") == question.get("correct_answer")

        points = question.get("points", 1) if is_correct else 0
        total_score += points

        results.append({
            "question_id": q_id,
            "question": question["question"],
            "user_answer": answer.get("answer_index"),
            "correct_index": question.get("correct_index"),
            "correct_answer": question.get("correct_answer"),
            "is_correct": is_correct,
            "points": points,
            "explanation": question.get("explanation", ""),
            "time_seconds": answer.get("time_seconds", 0)
        })

    percentage = round((total_score / max_score * 100) if max_score > 0 else 0, 1)
    wrong_topics = [r["question"] for r in results if not r["is_correct"]]

    # Générer un feedback global avec Claude
    feedback = await _generate_feedback(
        percentage=percentage,
        quiz=quiz,
        wrong_topics=wrong_topics[:3]
    )

    return {
        "quiz_id": quiz.get("quiz_title", ""),
        "total_score": total_score,
        "max_score": max_score,
        "percentage": percentage,
        "grade": _get_grade(percentage),
        "results": results,
        "feedback": feedback,
        "weak_areas": wrong_topics,
        "recommendation": _get_recommendation(percentage, quiz.get("topic", ""))
    }


async def _generate_feedback(percentage: float, quiz: Dict, wrong_topics: List[str]) -> str:
    """Génère un feedback motivant et personnalisé."""
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


def _get_grade(percentage: float) -> str:
    if percentage >= 90: return "Excellent"
    if percentage >= 75: return "Très bien"
    if percentage >= 60: return "Bien"
    if percentage >= 50: return "Passable"
    return "À retravailler"


def _get_recommendation(percentage: float, topic: str) -> str:
    if percentage >= 80:
        return f"Excellent travail sur {topic} ! Passez au niveau suivant."
    elif percentage >= 60:
        return f"Bonne base sur {topic}. Révisez les points manqués avant de continuer."
    else:
        return f"Reprenez le cours sur {topic} et réessayez le quiz."
