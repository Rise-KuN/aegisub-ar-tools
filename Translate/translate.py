script_name = "ترجمة متعددة"
script_description = "ترجمة سطر مختار من لغة إلى لغة أخرى"
script_author = "Rise-KuN"
script_version = "4.1.2"

import os
import json
from os import path
from dotenv import load_dotenv
from transformers import MarianTokenizer, MarianMTModel

load_dotenv()

HUGGINGFACE_API_KEY = os.getenv("HUGGINGFACE_API_KEY")
headers = {"Authorization": f"Bearer {HUGGINGFACE_API_KEY}"}

appdatapath = '%APPDATA%\\Aegisub\\adawet\\translate'
if '%' in appdatapath:
    appdatapath = path.expandvars(appdatapath)

input_path = path.join(appdatapath, "translation_input.json")
output_path = path.join(appdatapath, "translation_output.json")
error_log_path = path.join(os.path.dirname(__file__), "error_log.txt")

def translate_text(text, model, tokenizer):
    try:
        inputs = tokenizer(text, return_tensors="pt")
        translated = model.generate(**inputs)
        translated_text = tokenizer.batch_decode(translated, skip_special_tokens=True)[0]
        return translated_text
    except Exception as e:
        print(f"An error occurred: {str(e)}")
        return None

if __name__ == "__main__":
    try:
        with open(input_path, "r", encoding="utf-8") as file:
            data = json.load(file)

        selected_text = data["selected_text"]
        selected_model = data["selected_model"]

        model = MarianMTModel.from_pretrained(selected_model)
        tokenizer = MarianTokenizer.from_pretrained(selected_model)

        translations = []
        for text in selected_text:
            translated_text = translate_text(text.strip(), model, tokenizer)
            translations.append(translated_text)

        with open(output_path, "w", encoding="utf-8") as file:
            json.dump(translations, file)

    except Exception as e:
        with open(error_log_path, "w", encoding="utf-8") as error_file:
            error_file.write(str(e))
        print(f"An error occurred: {e}")
