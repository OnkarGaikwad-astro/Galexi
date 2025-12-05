from google.oauth2 import service_account
from google.auth.transport.requests import Request
import requests
SERVICE_ACCOUNT_FILE = "galexi-eebbe-firebase-adminsdk-fbsvc-b0687dd545.json"
PROJECT_ID = "galexi-eebbe"

DEVICE_TOKEN = "cyChkjJ3TnqCGi03b1w-fL:APA91bGboYHIWXNyk50OsETGXmcKvMzLyYtj_233wC1mBiiLP7e-0CPv4WrvFCFXX5aXe-MP8U6C-9spPlepUwHscdsbjt9sLphryU43sEMjD3aQZKlBCTw"
creds = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE,
    scopes=["https://www.googleapis.com/auth/firebase.messaging"]
)
creds.refresh(Request())
access_token = creds.token

url = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
message = {
    "message": {
        "token": DEVICE_TOKEN,
        "notification": {
            "title": "Greetings",
            "body": "Hello Onkar"
        },
        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": "high_importance_channel",
                "visibility": "PUBLIC",
                "default_sound": True
            }
        }
    }
}

res = requests.post(
    url,
    headers={
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    },
    json=message
)

print("Status:", res.status_code)
print("Response:", res.text)
