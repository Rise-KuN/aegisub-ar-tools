script_name = "Voxify Extended"
script_description = "Save audio file and pass it to Voxify bot"
script_author = "Rise-KuN"
script_version = "1.0.0"

local json = require 'json'
local lfs = require 'lfs'

-- Directory for configuration
function get_voxify_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\Voxify"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Model for Voxify
function get_voxify_model_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\Voxify"
    lfs.mkdir(config_dir)
    return config_dir .. "\\model.json"
end

-- Output audio file for Voxify
function get_voxify_audio_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\Voxify"
    lfs.mkdir(config_dir)
    return config_dir .. "\\audio.wav"
end

-- Load saved config
function load_voxify_config()
    local config_path = get_voxify_config_path()
    local file = io.open(config_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return json.decode(content) or {}
    end
    return {}
end

-- Save config file path
function save_voxify_config(config)
    local config_path = get_voxify_config_path()
    local file = io.open(config_path, "w")
    if file then
        file:write(json.encode(config))
        file:close()
    else
        aegisub.debug.out("Failed to save config file.\n")
    end
end

-- Select file for Python script
function select_voxify_py_file_path()
    return aegisub.dialog.open("اختر ملف Python", "", "", "*.py", false, true)
end

-- Clean Temp Files
local function cleanup_voxify_temp_files()
    local output_path = get_voxify_audio_path()
    os.remove(output_path)
end

-- Save audio and pass to Voxify Webhook
function save_audio_for_voxify(subtitles, selected_lines, active_line)
    local config = load_voxify_config()
    local selected_model = {"Whisper V3 Turbo", "Whisper V3", "Whisper V2"}

    local dialog_items = {
        {class="label", label=":اختر الموديل", x=1, y=0, width=2, height=1},
        {class="dropdown", name="model", items=selected_model, value=selected_model[1], x=0, y=0, width=1, height=1}
    }
    local button, _ = aegisub.dialog.display(dialog_items, {"التالي", "إلغاء", "مسار الأداة"})

    if button == "مسار الأداة" then
        config.file_path = select_voxify_py_file_path()
        if config.file_path then
            save_voxify_config(config)
            --aegisub.debug.out("Python script path set to: " .. config.file_path .. "\n")
        else
            aegisub.debug.out("No Python file selected.\n")
            return
        end
    elseif button == "التالي" then
        -- Save the selected model to json file
        local model_path = get_voxify_model_path()
        local selected_model = _ and _.model or "Whisper V3 Turbo"
        local model_file = io.open(model_path, "w")
        if model_file then
            model_file:write(json.encode({model = selected_model}))
            model_file:close()
        else
            aegisub.debug.out("Failed to save model file.\n")
            return
        end

        if not config.file_path or not io.open(config.file_path, "r") then
            aegisub.debug.out("Python script path is not set or invalid.\n")
            return
        end
    else
        cleanup_voxify_temp_files() -- Clean up temporary files
        return
    end

    if #selected_lines == 0 then
        aegisub.debug.out("Please select a line with audio.\n")
        return
    end

    local line = subtitles[selected_lines[1]]
    local start_time = line.start_time / 1000
    local end_time = line.end_time / 1000
    local audio_file = aegisub.project_properties().audio_file
    if not audio_file or audio_file == "" then
        aegisub.debug.out("No audio file loaded in Aegisub.\n")
        return
    end

    local output_path = get_voxify_audio_path()
    cleanup_voxify_temp_files() -- Remove Old Files if exists

    local ffmpeg_command = string.format('ffmpeg -i "%s" -ss %f -t %f -acodec pcm_s16le -ar 44100 "%s" -y',
        audio_file, start_time, end_time - start_time, output_path)
    local success = os.execute(ffmpeg_command)
    if success then
        --aegisub.debug.out("Audio extracted and saved to: " .. output_path .. "\n")
    else
        aegisub.debug.out("Failed to extract audio using FFmpeg.\n")
        return
    end

    if config.file_path then
        local command = string.format('python "%s"', config.file_path)
        os.execute(command)
        if success then
            --aegisub.debug.out("Python script executed successfully.\n")
        else
            aegisub.debug.out("Failed to execute Python script.\n")
        end
    else
        aegisub.debug.out("No Python script path configured.\n")
    end

    -- Final dialog with close button
    --local final_dialog_items = {
        --{class="label", label="Operation completed.", x=0, y=0, width=1, height=1},
    --}
    --local close_button, _ = aegisub.dialog.display(final_dialog_items, {"إغلاق"})
    
    --if close_button == "إغلاق" then
        --cleanup_voxify_temp_files() -- Clean up temporary files
    --end
end

aegisub.register_macro(script_name, script_description, save_audio_for_voxify)
