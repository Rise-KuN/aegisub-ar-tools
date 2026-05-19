# Name: Voxify Webhook
# Description: Send Audio To Voxify Bot via Discord Webhook.
# Version: 1.0.0
# Created By: Rise-KuN

import os
import requests
import json
import asyncio

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\adawet\\Voxify"
input_path = os.path.join(appdatapath, "audio.wav")
error_log_path = os.path.join(appdatapath, "error_log.txt")

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# Log errors to a file
def log_error(message):
    with open(error_log_path, "a", encoding="utf-8") as error_file:
        error_file.write(message + "\n")

# Webhook URL for the channel
WEBHOOK_URL = "ADD_YOUR_WEBHOOK_URL_HERE"  # Replace with your actual webhook URL

async def send_audio_via_webhook():
    try:
        # Check if the audio file exists
        if not os.path.exists(input_path):
            log_error(f"Error: Audio file not found at: {input_path}")
            print(f"Error: Audio file not found at {input_path}")
            return

        # Prepare the files for the webhook
        with open(input_path, 'rb') as f:
            files = {
                'file': (os.path.basename(input_path), f, 'audio/wav')
            }
            payload = {
                'content': 'Transcribe This:'  # Important
            }

            # Send the request to the webhook
            response = requests.post(WEBHOOK_URL, files=files, data=payload)
            #response.raise_for_status()  # Raise an exception for bad status codes
            if response.status_code == 200:
                print("Audio file sent via webhook")
            else:
                log_error(f"Failed to send audio file: {response.status_code}")
                print(f"Failed to send audio file: {response.status_code}")

        print(f"Audio file sent successfully to webhook from {input_path}")
    except requests.exceptions.RequestException as e:
        log_error(f"Failed to send audio via webhook: {str(e)}")
        print(f"Error: Failed to send audio via webhook - {str(e)}")
    except Exception as e:
        log_error(f"Unexpected error: {str(e)}")
        print(f"Error: Unexpected error - {str(e)}")

if __name__ == "__main__":
    try:
        asyncio.run(send_audio_via_webhook())
    except Exception as e:
        log_error(f"Startup error: {str(e)}")
        print(f"Error during startup: {str(e)}")