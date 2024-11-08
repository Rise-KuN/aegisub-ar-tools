script_name = "ترجمة متعددة"
script_description = "ترجمة سطر مختار من لغة إلى لغة أخرى"
script_author = "Rise-KuN"
script_version = "2.0"

import os
import json
import re
import requests
from os import path

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\CR"
input_path = os.path.join(appdatapath, "cr_input.json")
output_path = os.path.join(appdatapath, "cr_output.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")
local_correction_path = os.path.join(appdatapath, "word-correction-mapping.json")

# URL for the word correction mapping JSON file on GitHub
correction_url = "https://raw.githubusercontent.com/Rise-KuN/al-mochakel/master/word-correction-mapping.json"
commit_url = "https://api.github.com/repos/Rise-KuN/al-mochakel/commits?path=word-correction-mapping.json"

def get_latest_commit_hash():
    try:
        # Fetch the commit information for the file from GitHub
        response = requests.get(commit_url)
        response.raise_for_status()  # Will raise an error if the response is not successful
        commits = response.json()
        
        # Return the commit hash of the most recent commit
        if commits:
            return commits[0]['sha']
        else:
            return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching commit info: {e}")
        return None

def fetch_corrections():
    try:
        # Fetch the word correction mapping from the GitHub URL
        response = requests.get(correction_url)
        response.raise_for_status()  # Will raise an error if the response is not successful
        corrections = response.json()  # Return the JSON as a dictionary

        # Save the fetched corrections to a local file
        with open(local_correction_path, "w", encoding="utf-8") as local_file:
            json.dump(corrections, local_file, ensure_ascii=False, indent=4)
        
        # Print the fetched correction mapping
        print("Fetched and saved correction mapping.")
        
        return corrections
    except requests.exceptions.RequestException as e:
        # Log error if fetching the file fails
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(f"Error fetching correction file: {e}\n")
        print(f"An error occurred while fetching the correction mapping: {e}")

        # If fetching failed, load the local file (if exists)
        if path.exists(local_correction_path):
            with open(local_correction_path, "r", encoding="utf-8") as local_file:
                return json.load(local_file)

        # If neither fetching nor loading from local file works, return empty
        return {}

def apply_corrections(selected_text, corrections):
    corrected_texts = []
    
    for text in selected_text:
        for original, corrected in corrections.items():
            # Apply the correction only to exact matches (using word boundaries)
            text = re.sub(rf"\b{re.escape(original)}\b", corrected, text)
        corrected_texts.append(text)
    
    return corrected_texts

def is_file_updated():
    # Check if the file has been updated by comparing commit hashes
    latest_commit_hash = get_latest_commit_hash()
    
    if latest_commit_hash is None:
        return False  # Could not fetch commit hash
    
    # Read the local stored commit hash
    commit_file_path = os.path.join(appdatapath, "last_commit_hash.txt")
    
    if path.exists(commit_file_path):
        with open(commit_file_path, "r", encoding="utf-8") as f:
            stored_commit_hash = f.read().strip()
        
        # Compare with the latest commit hash from GitHub
        if stored_commit_hash == latest_commit_hash:
            print("No updates detected.")
            return False  # No update if hashes are the same
    
    # If no local commit hash is found or hashes differ, fetch new data
    with open(commit_file_path, "w", encoding="utf-8") as f:
        f.write(latest_commit_hash)  # Store the latest commit hash
    
    print("File has been updated.")
    return True  # File has been updated

if __name__ == "__main__":
    try:
        if is_file_updated():
            # Fetch the word correction mapping from GitHub or local file
            corrections = fetch_corrections()

            if not corrections:
                raise ValueError("No corrections available to apply.")

            # Read the input JSON file
            with open(input_path, "r", encoding="utf-8") as file:
                data = json.load(file)

            selected_text = data["selected_text"]

            # Apply corrections
            corrected_texts = apply_corrections(selected_text, corrections)

            # Write the corrected output to a file
            with open(output_path, "w", encoding="utf-8") as file:
                json.dump(corrected_texts, file, ensure_ascii=False, indent=4)
        
        else:
            print("No update required.")
    
    except Exception as e:
        # Log any errors
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(str(e) + "\n")
        print(f"An error occurred: {e}")