script_name = "عكس اتجاه الكلمات العربية"
script_description = "Reshape Arabic text."
script_author = "Rise-KuN"
script_version = "1.0.1"

import os
import json
import arabic_reshaper
from bidi.algorithm import get_display

# Paths
appdatapath = os.getenv('APPDATA') + "\\Aegisub\\AR-Reshape"
input_path = os.path.join(appdatapath, "ar_reshape_input.json")
output_path = os.path.join(appdatapath, "ar_reshape_output.json")
error_log_path = os.path.join(os.path.dirname(__file__), "error_log.txt")

# Ensure the app data path exists
os.makedirs(appdatapath, exist_ok=True)

# Configuration for Arabic Reshaper
configuration = {
    'delete_harakat': False,
    'support_ligatures': True,
    'RIAL SIGN': True,  # Replace ر ي ا ل with ﷼
}
reshaper = arabic_reshaper.ArabicReshaper(configuration=configuration)

# Function to reshape Arabic text for correct display
def reshape_arabic(text):
    reshaped_text = reshaper.reshape(text)  # Apply the custom configuration
    bidi_text = get_display(reshaped_text)
    return bidi_text

# Function to process the input, apply reshaping, and save the output
def process_input():
    if os.path.exists(input_path):
        with open(input_path, "r", encoding="utf-8") as file:
            input_data = json.load(file)

        selected_text = input_data.get("selected_text", [])

        # Apply reshaping to each selected text
        reshaped_texts = [reshape_arabic(text) for text in selected_text]

        # Save the reshaped texts to the output file
        with open(output_path, "w", encoding="utf-8") as file:
            json.dump(reshaped_texts, file, ensure_ascii=False, indent=4)

if __name__ == "__main__":
    try:
        process_input()
    except Exception as e:
        with open(error_log_path, "a", encoding="utf-8") as error_file:
            error_file.write(str(e) + "\n")
        print(f"An error occurred: {e}")
