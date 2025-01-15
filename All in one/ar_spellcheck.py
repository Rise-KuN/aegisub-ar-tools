script_name = "Spell Checker"
script_description = "Spell Checker"
script_author = "Rise-KuN"
script_version = "1.0.0"

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

def load_input_data():
    """Load the selected lines for correction from the input JSON file."""
    with open(input_path, "r", encoding="utf-8") as file:
        return json.load(file)

def save_output_data(data):
    """Save the corrected data to the output JSON file."""
    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

def spellcheck_text(text):
    """Spellcheck the provided text and return the corrected version."""
    words = text.split()  # Split text into words
    misspelled = spell.unknown(words)  # Find misspelled words
    for word in misspelled:
        corrected = spell.correction(word)  # Get the correction for the misspelled word
        if corrected:  # Only replace if a valid correction is found
            text = text.replace(word, corrected)  # Replace the misspelled word with the corrected one
    return text, len(misspelled) > 0  # Return the corrected text and whether a correction was made

if __name__ == "__main__":
    try:
        # Load input data
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
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(str(e) + "\n")
        print(f"An error occurred: {e}")