# Aegisub Tools
Aegisub Has many tools as we know but not for Arab Fansubbers, So we created these tools to make it easier for them.

## Tools
- Adawet - All in one tools.
- JPTL - Translate From `eng, jp` to `ar, eng`.
- CR - Add Tachkeel To the selected lines `Arabic only`.
- Calculate Progress - Based on the number of `current line, all lines`.
- Fix Punctuation - fix the `. ! ؟` and make them at the end of the line In `RTL`.
- Remove str - remove line break `\N` from the selected line.
- Remove symbol - remove `!`" from the selected line.
- Remove Period - remove `.` at the end of the selected line.
- Reshape AR Text - Reshape the text to make it support gardient and kareoke stuff.
- Reverse Characters Direction - Reverses the direction of characters.
- Reverse Words Direction - Reverses the direction of words.
- Adjust Clip Positions - Change the positions of the `clip` or `iclip` from `LTR` to `RLT` or the opposite.

> [!NOTE]
> Some tools `Adawet`, `CR`, `JPTL`, `Reshape AR Text`, Require Python 3.9 or above.

## Requirements

- Require Python 3.9 or above.

You can install them by using `requirements.txt` file:

Press `Win + R`, Then type `cmd`, And hit Enter
```
pip install -r requirements.txt
```
Or Do It Manual via command prompt `cmd`:

Press `Win + R`, Then type `cmd`, And hit Enter
```
pip install requests python-dotenv transformers torch torchvision torchaudio sacremoses sentencepiece arabic-reshaper python-bidi
```
