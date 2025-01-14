# Aegisub Tools
Aegisub Has many tools as we know but not for Arab Fansubbers, So we created these tools to make it easier for them.

## Tools
- Adawet - All in one tools.
- Text Editor - Edit the selected lines, also support `RLT` if you hit (right ctrl + right shift).
- Mochakel - Add Tachkeel To the selected lines `Arabic only`.
- Translate - Translate From `eng, jp` to `ar, eng`.
- Reshape AR Text - Reshape the text to make it support gardient characters.
- Fix Punctuation - fix the `. ! ؟` and make them at the end of the line In `RTL`.
- Fix Punctuation V2 - fix the `.` `!` `،` `:` `؛` `...` + more and makes them at the end of the line In `RTL`.
- Reverse Text - Reverses the direction of `Words` or `Characters` from the selected lines.
- Adjust Clip Positions - Change the positions of the `clip` or `iclip` from `LTR` to `RLT` or the opposite.
- Split Line To Frames - Split The line to frames based on `start_time`, `end_time`, and `fps`.
- Remove STR - Remove `.` `!` `\N` from the selected lines.
- Remove Text Between `Characters` or `Words`.
- Calculate Progress - Based on the number of `current line, all lines`.

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
