from pydantic import BaseModel
from typing import Optional
import uuid

class CourseRequest(BaseModel):
    instrument: str                 # "guitar", "piano", "violin"...
    topic: str                      # "Gamme pentatonique", "Accords de barré"...
    level: str = "débutant"         # "débutant", "intermédiaire", "avancé"
    analysis_id: Optional[str] = None
