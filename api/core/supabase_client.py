from supabase import create_client, Client
from config import settings

_client: Client | None = None

def get_supabase() -> Client:
    """Retourne un singleton du client Supabase (service_role)."""
    global _client
    if _client is None:
        _client = create_client(
            settings.SUPABASE_URL,
            settings.SUPABASE_SERVICE_KEY  # service_role : bypass RLS pour le backend
        )
    return _client
