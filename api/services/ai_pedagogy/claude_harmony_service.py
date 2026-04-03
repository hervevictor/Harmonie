import anthropic, json, re
from typing import Dict, Any, List, Optional
from config import settings

_claude = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)

SYSTEM_PROMPT_HARMONY = """Tu es un professeur de musique expert en harmonie et analyse musicale.
Tu expliques les progressions d'accords de façon claire, pédagogique et imagée.
Tu réponds TOUJOURS en français, avec un ton bienveillant.
Tu retournes UNIQUEMENT du JSON valide, sans texte ni balises Markdown."""


async def explain_harmony(
    chords: List[str],
    key_name: str,
    instrument: str,
    level: str = "débutant"
) -> Dict[str, Any]:
    """
    Génère une explication pédagogique de la progression harmonique d'une chanson.
    """
    prompt = f"""Explique de façon pédagogique et adaptée à un niveau {level}
la progression harmonique suivante en {key_name} : {' → '.join(chords)}

Instrument de l'élève : {instrument}

Retourne ce JSON :
{{
  "key_analysis": "explication de la tonalité",
  "chord_explanations": [
    {{
      "chord": "nom de l'accord",
      "roman_numeral": "chiffre romain (I, IV, V...)",
      "function": "fonction harmonique",
      "notes": ["notes constituant l'accord"],
      "explanation": "pourquoi cet accord sonne bien ici",
      "fingering_tip": "conseil de doigté spécifique à l'instrument"
    }}
  ],
  "progression_feel": "description de l'ambiance émotionnelle de la progression",
  "similar_songs": ["chanson connue utilisant une progression similaire"],
  "practice_advice": "comment travailler cette progression",
  "theory_insight": "concept de théorie musicale illustré par cette progression"
}}"""

    message = _claude.messages.create(
        model="claude-3-5-sonnet-latest",
        max_tokens=2000,
        system=SYSTEM_PROMPT_HARMONY,
        messages=[{"role": "user", "content": prompt}]
    )

    content = message.content[0].text.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"error": "Génération échouée"}
