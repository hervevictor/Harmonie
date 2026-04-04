import os
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

URL = os.getenv("SUPABASE_URL")
SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")

def test_supabase():
    try:
        client: Client = create_client(URL, SERVICE_KEY)
        print(f"Connecting to {URL}...")
        # Test query to check tables
        res = client.table("profiles").select("count", count="exact").limit(1).execute()
        print("✅ Connection to Supabase successful!")
        print(f"Table 'profiles' exists. Count: {res.count}")
    except Exception as e:
        print(f"❌ Connection failed: {e}")

if __name__ == "__main__":
    test_supabase()
