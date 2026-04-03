from fastapi import HTTPException

class PlanPermissionError(HTTPException):
    def __init__(self, feature: str):
        super().__init__(
            status_code=403,
            detail=f"Votre plan ne permet pas : {feature}. Passez à un plan supérieur."
        )

class AnalysisNotFoundError(HTTPException):
    def __init__(self, analysis_id: str):
        super().__init__(404, f"Analyse introuvable : {analysis_id}")

class FileNotFoundError(HTTPException):
    def __init__(self, file_id: str):
        super().__init__(404, f"Fichier introuvable : {file_id}")

class AIServiceError(HTTPException):
    def __init__(self, service: str, detail: str):
        super().__init__(502, f"Erreur service IA [{service}] : {detail}")
