script_name = "ترجمة متعددة"
script_description = "ترجمة سطر مختار من لغة إلى لغة أخرى"
script_author = "Rise-KuN"
script_version = "4.1.1"

-- ترجمة من لغة إلى لغة أخرى

local json = require 'json'
local lfs = require 'lfs'
local clipboard = require "clipboard"

-- Directory for configuration
function get_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Input file for translation
function get_translation_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    lfs.mkdir(config_dir)
    return config_dir .. "\\translation_input.json"
end

-- Output file for translation
function get_translation_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    return config_dir .. "\\translation_output.json"
end

-- Load saved config
function load_config()
    local config_path = get_config_path()
    local file = io.open(config_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return json.decode(content)
    else
        return {}
    end
end

-- Save config file path
function save_config(config)
    local config_path = get_config_path()
    local file = io.open(config_path, "w")
    file:write(json.encode(config))
    file:close()
end

-- Save selected text for translation
function save_translation_input(data)
    local input_path = get_translation_input_path()
    local file = io.open(input_path, "w")
    file:write(json.encode(data))
    file:close()
end

-- Select file for Python script
function select_file_path()
    local file_path = aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
    return file_path
end

function translate_with_external_script(subtitles, selected_lines, active_line)
    local config = load_config()
    local selected_text = {}

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end

    local model_map = {
        ["English"] = {["Arabic"] = "Helsinki-NLP/opus-mt-en-ar"},
        ["Japanese"] = {["Arabic"] = "Helsinki-NLP/opus-mt-ja-ar", ["English"] = "Helsinki-NLP/opus-mt-ja-en"}
    }

    local language_choices = {"English", "Japanese"}
    local language_dialog = {
        {class="label", label=":لغة النص", x=1, y=0, width=2, height=1},
        {class="dropdown", name="language", items=language_choices, value=language_choices[1], x=0, y=0, width=1, height=1}
    }
    
    local button, language_result = aegisub.dialog.display(language_dialog, {"التالي", "إلغاء", "مسار الأداة"})
    if button == "مسار الأداة" then
        config.file_path = select_file_path()
        if config.file_path then
            save_config(config)
            aegisub.debug.out("Python script path set to: " .. config.file_path)
        else
            aegisub.debug.out("No file selected. Please select a Python file.")
        end
        return
    elseif button == "التالي" then
        -- Check if the config file exists
        if not config.file_path or not io.open(config.file_path, "r") then
            aegisub.debug.out("Configuration file does not exist or the path is invalid.")
            return
        end
        -- Proceed with the next action if the config file exists
        aegisub.debug.out("Configuration file found, proceeding.")
    else
        return
    end

    local selected_language = language_result.language
    local model_choices = {}

    for model_name, _ in pairs(model_map[selected_language]) do
        table.insert(model_choices, model_name)
    end

    local model_dialog = {
        {class="label", label=":اختر اللغة", x=1, y=0, width=2, height=1},
        {class="dropdown", name="model", items=model_choices, value=model_choices[1], x=0, y=0, width=1, height=1}
    }

    local button, model_result = aegisub.dialog.display(model_dialog, {"اختيار", "إلغاء"})
    if button ~= "اختيار" then return end

    local selected_model = model_map[selected_language][model_result.model]
    local translation_data = {
        selected_text = selected_text,
        selected_model = selected_model
    }
    save_translation_input(translation_data)

     -- Execute the Python script
    if config.file_path then
        os.execute('python "' .. config.file_path .. '"')
    else
        aegisub.debug.out("Error: Python script path not set. Please select the correct file path.")
        return
    end

    -- Read the output from the Python script
    local output_path = get_translation_output_path()
    local result_file = io.open(output_path, "r")
    if result_file then
        local content = result_file:read("*all")
        local translations = json.decode(content)
        result_file:close()

        local dialog_items = {}
        for i, translation in ipairs(translations) do
            table.insert(dialog_items, {class="edit", name="translation_" .. i, text=translation, x=0, y=i, width=75, height=1})
        end

        local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
        local button_pressed, edited_translations = aegisub.dialog.display(dialog_items, buttons)

        if button_pressed == "تطبيق" then
            -- Apply the changes
            for i, line_index in ipairs(selected_lines) do
                local line = subtitles[line_index]
                line.text = edited_translations["translation_" .. i] or ""
                subtitles[line_index] = line
            end
            aegisub.set_undo_point(script_name)
            -- Clean up temporary files
            local translation_input_path = get_translation_input_path()
            local translation_output_path = get_translation_output_path()
            os.remove(translation_input_path)
            os.remove(translation_output_path)
        elseif button_pressed == "نسخ الكل" then
            local all_translations = {}
            for i = 1, #translations do
                table.insert(all_translations, edited_translations["translation_" .. i] or "")
            end
            clipboard.set(table.concat(all_translations, "\n"))
            -- Clean up temporary files
            local translation_input_path = get_translation_input_path()
            local translation_output_path = get_translation_output_path()
            os.remove(translation_input_path)
            os.remove(translation_output_path)
        elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            local translation_input_path = get_translation_input_path()
            local translation_output_path = get_translation_output_path()
            os.remove(translation_input_path)
            os.remove(translation_output_path)
        else
            -- Clean up temporary files
            local translation_input_path = get_translation_input_path()
            local translation_output_path = get_translation_output_path()
            os.remove(translation_input_path)
            os.remove(translation_output_path)
        end
    else
        aegisub.debug.out("Error: Could not open translation_output.json. Please check if the Python script ran correctly.")
    end
end

aegisub.register_macro(script_name, script_description, translate_with_external_script)
