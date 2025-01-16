script_name = "المُشكل"
script_description = "تشكيل الكلمات العربية"
script_author = "Rise-KuN"
script_version = "2.1.5"

import os
import json
import re
import requests

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\adawet\\mochakel"
input_path = os.path.join(appdatapath, "cr_input.json")
output_path = os.path.join(appdatapath, "cr_output.json")
saved_version_path = os.path.join(appdatapath, "word-correction-mapping.json")
commit_hash_path = os.path.join(appdatapath, "commit_hash.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")

# URLs for the correction mapping JSON and commit history on GitHub
correction_url = "https://raw.githubusercontent.com/Rise-KuN/aegisub-ar-tools/main/Mochakel/Word%20Correction%20Mapping/word-correction-mapping.json"
commit_url = "https://api.github.com/repos/Rise-KuN/aegisub-ar-tools/commits?path=Mochakel/Word%20Correction%20Mapping/word-correction-mapping.json"

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# Log errors to a file
def log_error(message):
    with open(error_log_path, "a", encoding="utf-8") as error_file:
        error_file.write(message + "\n")

def fetch_latest_commit_hash():
    try:
        response = requests.get(commit_url)
        response.raise_for_status()
        commits = response.json()
        if commits:
            return commits[0]["sha"]  # Get the latest commit SHA
    except requests.exceptions.RequestException as e:
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(f"Error fetching commit data: {e}\n")
        print(f"An error occurred while fetching the commit data: {e}")
    return None

def fetch_corrections():
    try:
        response = requests.get(correction_url)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(f"Error fetching correction file: {e}\n")
        print(f"An error occurred while fetching the correction mapping: {e}")
        return {}

def save_corrections_to_file(corrections):
    with open(saved_version_path, "w", encoding="utf-8") as file:
        json.dump(corrections, file, ensure_ascii=False, indent=4)

def load_saved_corrections():
    if os.path.exists(saved_version_path):
        with open(saved_version_path, "r", encoding="utf-8") as file:
            return json.load(file)
    return {}

def save_commit_hash(hash_value):
    with open(commit_hash_path, "w", encoding="utf-8") as file:
        json.dump({"commit_hash": hash_value}, file, ensure_ascii=False, indent=4)

def load_commit_hash():
    if os.path.exists(commit_hash_path):
        with open(commit_hash_path, "r", encoding="utf-8") as file:
            data = json.load(file)
            return data.get("commit_hash")
    return None

def apply_corrections(selected_text, corrections):
    corrected_texts = []
    for text in selected_text:
        for original, corrected in corrections.items():
            # Regex pattern to match the exact word only if it's not followed or preceded by additional diacritics
            # It looks for the word boundaries (\b), ensuring no additional diacritics are added.
            # The \b ensures we match word boundaries, and [^\u064B-\u0652] to ensures no diacritics are around the word
            text = re.sub(rf"(?<![\u064B-\u0652])\b{re.escape(original)}\b(?![\u064B-\u0652])", corrected, text)
        corrected_texts.append(text)
    return corrected_texts

if __name__ == "__main__":
    try:
        # Fetch the latest commit hash
        latest_commit_hash = fetch_latest_commit_hash()
        if not latest_commit_hash:
            raise ValueError("Failed to retrieve the latest commit hash.")

        # Load the saved commit hash
        saved_commit_hash = load_commit_hash()

        # Initialize corrections data
        corrections = {}

        # Check if there is a new version
        if latest_commit_hash != saved_commit_hash:
            #print("New version detected, updating local file and commit hash.")
            corrections = fetch_corrections()
            if corrections:
                save_corrections_to_file(corrections)
                save_commit_hash(latest_commit_hash)
            else:
                raise ValueError("Failed to fetch corrections data.")
        else:
            #print("No changes in the correction mapping.")
            # Load saved corrections if no update is detected
            corrections = load_saved_corrections()

        # Create `cr_output.json` if it does not exist
        if not os.path.exists(output_path):
            with open(output_path, "w", encoding="utf-8") as file:
                json.dump([], file)

        # Read the input JSON file
        with open(input_path, "r", encoding="utf-8") as file:
            data = json.load(file)

        selected_text = data["selected_text"]

        # Apply corrections
        corrected_texts = apply_corrections(selected_text, corrections)

        # Write the corrected output to a file
        with open(output_path, "w", encoding="utf-8") as file:
            json.dump(corrected_texts, file, ensure_ascii=False, indent=4)

    except Exception as e:
        log_error(f"Error: {e}")
