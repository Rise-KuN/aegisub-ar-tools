script_name = "Spell Checker"
script_description = "Spell Checker"
script_author = "Rise-KuN"
script_version = "2.0.0"

import os
import json
import time
import requests
from dotenv import load_dotenv

load_dotenv()
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY")
headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}

# Hugging Face API Model Endpoint
API_URL = "https://api-inference.huggingface.co/models/asafaya/bert-base-arabic"

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\adawet\\SpellChecker"
input_path = os.path.join(appdatapath, "sp_input.json")
output_path = os.path.join(appdatapath, "sp_output.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# Log errors to a file
def log_error(message):
    with open(error_log_path, "a", encoding="utf-8") as error_file:
        error_file.write(message + "\n")

# Load the selected lines from input JSON file.
def load_input_data():
    with open(input_path, "r", encoding="utf-8") as file:
        return json.load(file)

# Save the corrected lines to output JSON file
def save_output_data(data):
    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
        
# Hugging Face API to detect spelling errors and make corrections      
def detect_and_correct_spelling(text, max_retries=5, retry_delay=5):
    words = text.split()
    corrected_text = []

    for word in words:
        # Mask the word to predict its correction
        masked_input = text.replace(word, "[MASK]")
        payload = {"inputs": masked_input}

        retries = 0
        while retries < max_retries:
            response = requests.post(API_URL, headers=headers, json=payload)
            if response.status_code == 200:
                try:
                    result = response.json()
                    # Extract the highest-probability token for masked position
                    predictions = result[0]["token_str"]
                    corrected_word = predictions.strip()
                    corrected_text.append(corrected_word)  # Append corrected word
                    break
                except Exception as e:
                    log_error(f"Error parsing API response: {e}")
                    corrected_text.append(word)  # Fallback to original word
                    break
            elif response.status_code == 503:
                estimated_time = response.json().get("estimated_time", retry_delay)
                log_error(f"Model loading, retrying in {estimated_time} seconds...")
                time.sleep(estimated_time)
                retries += 1
            else:
                log_error(f"API Error: {response.status_code}, {response.text}")
                corrected_text.append(word)  # Fallback to original word
                break

        if retries == max_retries:
            log_error(f"Max retries reached for word: {word}")
            corrected_text.append(word)  # Fallback if retries exhausted

    return " ".join(corrected_text)

if __name__ == "__main__":
    try:
        # Load input data
        data = load_input_data()
        selected_text = data.get("selected_text", [])

        # Apply spellcheck using Hugging Face API
        corrected_lines = []
        for text in selected_text:
            corrected_text = detect_and_correct_spelling(text)
            needs_review = corrected_text != text
            corrected_lines.append({
                "original_text": text,
                "corrected_text": corrected_text,
                "needs_review": needs_review
            })

        # Save the output with the original and corrected lines
        save_output_data(corrected_lines)

    except Exception as e:
        log_error(f"Error: {e}")
