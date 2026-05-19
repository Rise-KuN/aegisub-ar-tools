script_name = "Spell Checker V2"
script_description = "Spell Checker V2"
script_author = "Rise-KuN"
script_version = "2.0.1"

import os
import re
import json
import time
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()
HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY")
headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}

# API endpoint for Hugging Face models
ged_model_url = "https://api-inference.huggingface.co/models/CAMeL-Lab/camelbert-msa-zaebuc-ged-43"
gec_model_url = "https://api-inference.huggingface.co/models/CAMeL-Lab/arabart-zaebuc-gec-ged-13"

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\adawet\\SpellChecker"
input_path = os.path.join(appdatapath, "sp_input.json")
output_path = os.path.join(appdatapath, "sp_output.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# Hugging Face API Query 
def query_huggingface_api(url, data, retries=5, delay=10):
    for attempt in range(retries):
        try:
            response = requests.post(url, headers=headers, json=data)
            if response.status_code == 200:
                return response.json()  # Return the JSON response if successful
                log_error(f"API Response: {response}\n")
            elif response.status_code == 503:
                # If service is unavailable, retry after a delay
                print(f"API Attempt {attempt+1} failed with status code 503. Retrying...")
                #log_error(f"API Attempt {attempt+1} failed with status code 503. Retrying...\n")
                time.sleep(delay)
            else:
                # For other non-2xx status codes, raise an error
                response.raise_for_status()
                log_error(f"{response}")
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            #log_error(f"Request failed: {e}\n")
            time.sleep(delay)
    raise Exception(f"API request failed after {retries} attempts.")

# Log errors to a file
def log_error(message):
    with open(error_log_path, "a", encoding="utf-8") as error_file:
        error_file.write(message + "\n")

# Load the selected lines from input JSON file
def load_input_data():
    with open(input_path, "r", encoding="utf-8") as file:
        return json.load(file)

# Save the corrected lines to output JSON file
def save_output_data(data):
    with open(output_path, "w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
        
# Remove Punctuation Marks and Special Unicode Char
def clean_text(text, arabic_punctuation_marks):
    text = text.replace('‏‏', '') # Remove unicode character
    text = text.replace('‏', '') # Remove unicode character
    
    # Convert The Punifications Marks into a regular expression
    punctuation_pattern = "|".join([re.escape(mark) for mark in arabic_punctuation_marks])
    
    # Remove punctuation marks from the text
    cleaned_text = re.sub(punctuation_pattern, "", text)
    
    # Remove extra spaces
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text).strip()
    return cleaned_text

# Function to process and correct the text using GED and GEC models
def spellcheck_text(text):
    # GED generation: Use Hugging Face API for GED model
    ged_data = {
        "inputs": text
    }

    # Make API request for GED model
    ged_response = query_huggingface_api(ged_model_url, ged_data)
    
    # Debugging the Response format
    #print("GED Response:", ged_response)
    #log_error(f"GED Response: {ged_response}\n")
    
    # Check for any predicted entities from GED model
    if isinstance(ged_response, list) and len(ged_response) > 0:
        ged_predictions = ged_response
        corrected_text_ged = apply_ged_corrections(text, ged_predictions)
        #print("Corrected Text GED:", corrected_text_ged)
        #log_error(f"Corrected Text GED: {corrected_text_ged}\n")
    else:
        #print("Unexpected GED response structure.")
        #log_error(f"Unexpected GED response structure.\n")
        corrected_text_ged = text

    # Use GEC model on the corrected GED text
    gec_data = {
        "inputs": corrected_text_ged,
        "options": {
            "num_beams": 5,
            "max_length": 100,
            "num_return_sequences": 1,
            "no_repeat_ngram_size": 0,
            "early_stopping": False,
        }
    }

    # Make API request for GEC model
    gec_response = query_huggingface_api(gec_model_url, gec_data)
    
    # Debugging the Response format
    #print("GEC Response:", gec_response)
    #log_error(f"GEC Response: {gec_response}\n")

    # Extract corrected text from GEC response
    if isinstance(gec_response, list) and len(gec_response) > 0 and "generated_text" in gec_response[0]:
        generated_text = gec_response[0]['generated_text']
        #print("GEC response generated_text:", generated_text)
        #log_error(f"GEC Response: {generated_text}\n")
    else:
        #print("Unexpected GEC response structure.")
        #log_error(f"Unexpected GEC response structure.\n")
        generated_text = corrected_text_ged  # fall back to GED-corrected text
        
    # Punifications Marks List
    arabic_punctuation_marks = [".", "...", "،", "؛", ":", "!", "؟", "؟!", "!؟"]

    # Convert The Punifications Marks into a regular expression
    punctuation_pattern = "|".join([re.escape(mark) for mark in arabic_punctuation_marks])
    
    # Remove space before any Punifications Marks
    generated_text = re.sub(r"\s*(" + punctuation_pattern + ")", r"\1", generated_text)
    
    # Remove Space Before "..."
    generated_text = re.sub(r"\.\.\.(\s+)(?=[\u0600-\u06FF])", r"...", generated_text)
    
    # Remove the generated last commas by GEC
    if generated_text.endswith("."): generated_text = generated_text[:-1]
    
    # Remove Arabic punctuation marks and extra spaces from both texts for comparison
    cleaned_generated_text = clean_text(generated_text, arabic_punctuation_marks)
    cleaned_text = clean_text(text, arabic_punctuation_marks)
    
    #log_error(f"Cleaned Generated Text: '{cleaned_generated_text}'")
    #log_error(f"Cleaned Text: '{cleaned_text}'")

    # Needs Review Default
    needs_review = False
    
    # Check if the text is corrected
    if cleaned_generated_text != cleaned_text:
        needs_review = True

    # Return the final corrected text
    return generated_text, needs_review

# A helper function to apply GED corrections
def apply_ged_corrections(text, ged_predictions):
    for prediction in ged_predictions:
        if prediction.get('entity_group') == 'REPLACE_O':
            text = text.replace(prediction['word'], "<CORRECTED>")
    return text

if __name__ == "__main__":
    try:
        print(f"Starting Version 2.0.1\n")
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