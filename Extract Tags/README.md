# Extract Tags

## Overview
Extracts style properties from selected lines and injects them as override tags directly into the line.

## Features
- **Smart Style Detection**: Automatically detects the style of each selected line
- **Selective Tag Extraction**: Choose which tags to extract via checkbox dialog
- **Supported Tags**:
  - `\c` - Primary Color (text color)
  - `\2c` - Secondary Color (outline color)
  - `\3c` - Back Color (shadow color)
  - `\4c` - Alpha (transparency)
  - `\bord` - Border Width (outline size)
  - `\shad` - Shadow Depth (shadow size)
  - `\fn` - Font Name
  - `\fs` - Font Size

## Usage
1. Select one or more lines in your subtitle file
2. Run the "Extract Tags" macro
3. In the dialog, check the tags you want to extract
4. Click "Extract" to inject the tags into each line based on its assigned style
5. Each line will receive tags specific to its own style

## How It Works
- The script reads the style properties of each selected line
- Converts style properties into Aegisub override tags
- Wraps the tags in braces `{...}` at the beginning of the line's text
- If you have 10 lines with different styles, each line gets tags from its own style

## Example
If you have:
- Line 1 with style "MyStyle1" (red color, thick border)
- Line 2 with style "MyStyle2" (blue color, thin border)

After extraction, it becomes:
- Line 1: `{\c&HXX0000&\bord3}[original text]`
- Line 2: `{\c&H0000XX&\bord1}[original text]`
