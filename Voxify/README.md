# Voxify Extended

## Overview
An Aegisub macro that integrates with Voxify Discord bot for automated audio transcription.

## Features
- **Seamless Aegisub Integration**: Works directly within Aegisub as a macro
- **Automatic Audio Extraction**: Exports audio for selected subtitle lines based on their timing
- **Discord Webhook Support**: Sends audio to Voxify bot via Discord webhook
- **Configuration Management**: Stores settings persistently for repeated use
- **Error Logging**: Comprehensive error logging for troubleshooting
- **Temp File Cleanup**: Automatically cleans up temporary files

## Components
- **voxify_extended.lua**: Aegisub macro that handles audio extraction and file management
- **send_audio_to_voxify.py**: Python script that sends extracted audio to Voxify via Discord webhook

## Setup
1. Place `voxify_extended.lua` in your Aegisub automation scripts folder
2. Configure the Python script path when first running the macro
3. Set up your Discord webhook URL in `send_audio_to_voxify.py`

## Usage
1. Load an audio file in Aegisub
2. Select the line whose audio you want to transcribe
3. Run the "Voxify Extended" macro
4. Click "مسار الأداة" (Tool Path) to set the Python script location (first time only)
5. Click "التالي" (Next) to extract and send the audio to Voxify
6. The Voxify bot will process the audio and provide transcription results

## How It Works
- The macro extracts the audio segment based on the selected line's start and end times
- Saves the audio as a temporary WAV file
- Invokes the Python script, which sends the audio file to Discord webhook
- Voxify bot receives and processes the audio for transcription
- Results are returned through Discord

## Configuration
Configuration is stored in: `%APPDATA%\Aegisub\adawet\Voxify\config.json`

## Requirements
- Aegisub with Lua automation support
- Python 3.x installed and accessible
- Discord webhook URL with access to a server with Voxify bot
- Audio file loaded in Aegisub project
