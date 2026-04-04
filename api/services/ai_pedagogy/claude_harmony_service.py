import anthropic, json, re, httpx
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

    content = ""
    
    # Stratégie : Utiliser Groq/OpenAI en premier car Anthropic n'a plus de crédits
    try:
        model = "llama-3.3-70b-versatile" if is_groq else "gpt-4o"
        response = await _openai.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT_HARMONY},
                {"role": "user", "content": prompt}
            ],
            response_format={"type": "json_object"}
        )
        content = response.choices[0].message.content
    except Exception as e:
        # Fallback Anthropic (si jamais les crédits reviennent)
        try:
            message = _claude.messages.create(
                model="claude-3-5-sonnet-latest",
                max_tokens=2000,
                system=SYSTEM_PROMPT_HARMONY,
                messages=[{"role": "user", "content": prompt}]
            )
            content = message.content[0].text.strip()
        except Exception as anth_err:
            return {"error": f"IA inaccessible : {str(anth_err)}"}

    # Nettoyage JSON
    content = content.strip()
    content = re.sub(r'^```(?:json)?\s*', '', content)
    content = re.sub(r'\s*```$', '', content)

    try:
        return json.loads(content)
    except json.JSONDecodeError:
        return {"error": "Génération échouée"}
