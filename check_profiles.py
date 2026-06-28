import urllib.request
import json

url = "https://rdwpusqhwpdoeigkixud.supabase.co/rest/v1/profiles?limit=5"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkd3B1c3Fod3Bkb2VpZ2tpeHVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzMjI2ODQsImV4cCI6MjA5Njg5ODY4NH0.uB_tz-ibhnn4O6IBp6oUC7-YXDnkqLVsrmNK5WIcmL0",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkd3B1c3Fod3Bkb2VpZ2tpeHVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzMjI2ODQsImV4cCI6MjA5Njg5ODY4NH0.uB_tz-ibhnn4O6IBp6oUC7-YXDnkqLVsrmNK5WIcmL0"
}

req = urllib.request.Request(url, headers=headers)
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        print(json.dumps(data, indent=2))
except Exception as e:
    print(f"Error: {e}")
