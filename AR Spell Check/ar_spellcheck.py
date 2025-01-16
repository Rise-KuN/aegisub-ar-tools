script_name = "Spell Checker"
script_description = "Spell Checker"
script_author = "Rise-KuN"
script_version = "1.0.1"

import os
import json
import re
from spellchecker import SpellChecker

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\adawet\\SpellChecker"
input_path = os.path.join(appdatapath, "sp_input.json")
output_path = os.path.join(appdatapath, "sp_output.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# SpellChecker Language
spell = SpellChecker(language='ar')

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
    """Save the corrected data to the output JSON file."""
    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)   

# Spellcheck the provided text and return with the corrected version
def spellcheck_text(text):
    words = text.split()  # Split text into words
    misspelled = spell.unknown(words)  # Find misspelled words
    for word in misspelled:
        corrected = spell.correction(word)  # Get the correction for misspelled words
        if corrected:  # Only replace if a valid correction is found
            text = text.replace(word, corrected)  # Replace the misspelled word with the corrected one
    return text, len(misspelled) > 0  # Return the corrected text and whether a correction was made

if __name__ == "__main__":
    try:
        # Load input lines data
        data = load_input_data()
        selected_text = data.get("selected_text", [])

        # Apply spellcheck to each line
        corrected_lines = []
        for text in selected_text:
            corrected_text, needs_review = spellcheck_text(text)
            corrected_lines.append({
                "original_text": text,             # Include the original text
                "corrected_text": corrected_text,  # Include the corrected text
                "needs_review": needs_review       # Indicate if the line needs review
            })

        # Save the output with the original and corrected lines
        save_output_data(corrected_lines)

    except Exception as e:
        log_error(f"Error: {e}")
