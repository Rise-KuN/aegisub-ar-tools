# All in one Tools

- Extract Tags - Extracts style properties from selected lines and injects them as override tags directly into the line.
- Reshape AR Text - Reshape the text to make it support gardient characters.
- Fix Punctuation Unicode - Adds `U+202B` unicode character to start of all selected lines to fix the `RTL` problem in Aegisub.
- Fix Punctuation V2 - Reverse the punctuation position to the end of the line In `RTL`.
- Punctuation Position Normalizer - Normalizes punctuation placement from line start to line end.
- Reverse Text - Reverses the direction of `Words` or `Characters` from the selected lines.
- Adjust Clip Positions - Change the positions of the `clip` or `iclip` from `LTR` to `RLT` or the opposite.
- Copy & Paste Clip - Copy the selected lines `clip` or `iclip` and paste it to another selected lines.
- Copy & Paste Tags - Copy the first override-tag block from selected lines and paste it onto another selection.
- Split Line To Frames - Split The line to frames based on `start_time`, `end_time`, and `fps`.
- Remove STR - Remove `.` `!` `\N` from the selected lines.
- Remove Text Between `Characters` or `Words`.
- Add Blur - Add blur to selected lines based on `start` and `end` values with calculation.
- Shift Times - Shift time of selected lines based on `first line time` then shift forward based on the `video player current time` with Shift Times Option.

> [!NOTE]
> Some tools `Reshape AR Text`, Require Python 3.9 or above.

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
pip install arabic-reshaper python-bidi
```
