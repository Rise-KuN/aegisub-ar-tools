script_name = "تغيير شكل الكلمات العربية"
script_description = "Reshape arabic text"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- تغيير شكل الكلمات العربية
local json = require 'json'
local lfs = require 'lfs'
local clipboard = require "clipboard"

-- Directory for configuration
function get_ar_reshape_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\AR-Reshape"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Temporary file for input data
function get_ar_reshape_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\AR-Reshape"
    lfs.mkdir(config_dir)
    return config_dir .. "\\ar_reshape_input.json"
end

-- Output file for ar_reshape
function get_ar_reshape_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\AR-Reshape"
    return config_dir .. "\\ar_reshape_output.json"
end

-- Load saved config
function load_ar_reshape_config()
    local config_path = get_ar_reshape_config_path()
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
function save_ar_reshape_config(config)
    local config_path = get_ar_reshape_config_path()
    local file = io.open(config_path, "w")
    file:write(json.encode(config))
    file:close()
end

-- Save selected text for reshape
function save_ar_reshape_input(data)
    local input_path = get_ar_reshape_input_path()

    -- Check if the input file exists, and if so, remove it
    local file = io.open(input_path, "r")
    if file then
        file:close()  -- Close the file if it's open
        -- Remove the old input file is exists
        os.remove(input_path)  
    end

    -- Now create and write the new input file
    file = io.open(input_path, "w")
    file:write(json.encode(data))
    file:close()
end

-- Select file for Python script
function select_ar_reshape_file_path()
    local file_path = aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
    return file_path
end

-- Add ar_reshape using the Python script
function add_ar_reshape_to_words(subtitles, selected_lines, active_line)
    local selected_text = {}
    
    -- Collect selected text
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end

    -- Save selected text to JSON
    local config = load_ar_reshape_config()
    local ar_reshape_data = {
        selected_text = selected_text
    }
    save_ar_reshape_input(ar_reshape_data)

    -- Open dialog to select Python file if not set
    local ar_reshape_first_dialog = {
        {class="label", label="", x=1, y=0, width=1, height=1},
    }
    local button, ar_reshape_result = aegisub.dialog.display(ar_reshape_first_dialog, {"التالي", "إلغاء", "مسار الأداة"})

    -- If "مسار الأداة" is clicked, let the user select the Python file
    if button == "مسار الأداة" then
        config.file_path = select_ar_reshape_file_path()
        if config.file_path then
            save_ar_reshape_config(config)
            aegisub.debug.out("Python script path set to: " .. config.file_path)
        else
            aegisub.debug.out("No Python file selected.\n")
            return
        end
    elseif button == "التالي" then
        -- Check if the config file exists
        if not config.file_path or not io.open(config.file_path, "r") then
            aegisub.debug.out("Configuration file does not exist or the path is invalid.\n")
            return
        end
        -- Proceed with the next action if the config file exists
        aegisub.debug.out("Configuration file found, proceeding.\n")
    else
        return
    end

    -- Execute the Python script to perform ar_reshape
    if config.file_path then
        os.execute('python "' .. config.file_path .. '"')
    end

    -- Read the output from the Python script
    local output_path = get_ar_reshape_output_path()
    local result_file = io.open(output_path, "r")
    if result_file then
        local content = result_file:read("*all")
        local updated_text_result = json.decode(content)
        result_file:close()

        -- Display the corrected text
        local dialog_items = {}
        for i, updated_text in ipairs(updated_text_result) do
            table.insert(dialog_items, {class="edit", name="correction_" .. i, text=updated_text, x=0, y=i, width=75, height=1})
        end

        local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
        local button_pressed, edited_updated_text = aegisub.dialog.display(dialog_items, buttons)

        if button_pressed == "تطبيق" then
            -- Apply the changes
            for i, line_index in ipairs(selected_lines) do
                local line = subtitles[line_index]
                line.text = edited_updated_text["correction_" .. i] or ""
                subtitles[line_index] = line
            end
            aegisub.set_undo_point(script_name)
            -- Clean up temporary files
            local output_path = get_ar_reshape_output_path()
            os.remove(output_path)
            local input_path = get_ar_reshape_input_path()
            os.remove(input_path)
        elseif button_pressed == "نسخ الكل" then
            -- Copy all text result to clipboard
            local all_corrections = {}
            for i = 1, #updated_text_result do
                table.insert(all_corrections, edited_updated_text["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
            -- Clean up temporary files
            local output_path = get_ar_reshape_output_path()
            os.remove(output_path)
            local input_path = get_ar_reshape_input_path()
            os.remove(input_path)
		elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            local output_path = get_ar_reshape_output_path()
            os.remove(output_path)
            local input_path = get_ar_reshape_input_path()
            os.remove(input_path)
        else
            -- Clean up temporary files
            local output_path = get_ar_reshape_output_path()
            os.remove(output_path)
            local input_path = get_ar_reshape_input_path()
            os.remove(input_path)
        end
    else
        aegisub.debug.out("Error: Could not open ar_reshape_output.json. Check if the Python script ran correctly.\n")
    end
end

aegisub.register_macro(script_name, script_description, add_ar_reshape_to_words)
