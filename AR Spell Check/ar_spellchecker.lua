script_name = "SpellChecker"
script_description = "SpellChecker"
script_author = "Rise-KuN"
script_version = "1.0.1"

-- أداة فحص الأخطاء
local json = require 'json'
local lfs = require 'lfs'
local clipboard = require "clipboard"

-- Directory for configuration
function get_sp_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\SpellChecker"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Temporary file for input data
function get_sp_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\SpellChecker"
    lfs.mkdir(config_dir)
    return config_dir .. "\\sp_input.json"
end

-- Output file for corrections
function get_sp_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\SpellChecker"
    return config_dir .. "\\sp_output.json"
end

-- Load saved config
function load_sp_config()
    local config_path = get_sp_config_path()
    local file = io.open(config_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return json.decode(content)
    else
        return {version_1 = nil, version_2 = nil}
    end
end

-- Save config
function save_sp_config(config)
    local config_path = get_sp_config_path()
    local file = io.open(config_path, "w")
    file:write(json.encode(config))
    file:close()
end

-- Save selected text for correction
function save_sp_input(data)
    local input_path = get_sp_input_path()

    -- Check if the input file exists, and if so, remove it
    local file = io.open(input_path, "r")
    if file then
        file:close()  -- Close the file if it's open
        os.remove(input_path)  -- Remove the old input file
    end

    -- Now create and write the new input file
    file = io.open(input_path, "w")
    file:write(json.encode(data))
    file:close()
end

-- Select file for Python script
function select_sp_file_path()
    return aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
end

function select_sp_file_paths()
    local config = load_sp_config()
    if not config.version_1 or not config.version_2 then
        aegisub.debug.out("Select the paths for both versions of the script.")
        
        -- Prompt for version 1
        config.version_1 = select_sp_file_path()
        if not config.version_1 then
            aegisub.debug.out("Version 1 file selection canceled.")
            return nil
        end

        -- Prompt for version 2
        config.version_2 = select_sp_file_path()
        if not config.version_2 then
            aegisub.debug.out("Version 2 file selection canceled.")
            return nil
        end

        -- Save the config with both versions
        save_sp_config(config)
    end
    return config
end

-- Clean Temp Files
local function cleanup_sp_temp_files()
    local output_path = get_sp_output_path()
    os.remove(output_path)
    local input_path = get_sp_input_path()
    os.remove(input_path)
end

-- Correct words using the Python script
function spellchecker(subtitles, selected_lines, active_line)
    local count = 0          -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made
    local selected_text = {}

    -- Collect selected text
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end

    -- Load Config
    local config = select_sp_file_paths()
    if not config then return end
    
    -- Save selected text to JSON
    local translation_data = {
        selected_text = selected_text
    }
    save_sp_input(translation_data)
    
    -- Show first dialog to select version (based on saved config)
    local version = config.version_1 and "الأولى" or "الثانية"
    local sp_first_dialog = {
        {class="label", label=":اختر النسخة", x=1, y=0, width=2, height=1},
        {class="dropdown", name="version", items={"الأولى", "الثانية"}, value=version, x=0, y=0, width=1, height=1}
    }
    
    local button, sp_result = aegisub.dialog.display(sp_first_dialog, {"التالي", "إلغاء", "مسار الأداة"})

    -- If "مسار الأداة" is clicked, let the user select the Python file
    if button == "مسار الأداة" then
        -- Prompt for version 1
        aegisub.debug.out("Please select the first version of the Python script.\n")
        config.version_1 = select_sp_file_path()
        if not config.version_1 then
            aegisub.debug.out("Version 1 file selection canceled.\n")
            return
        end

        -- Prompt for version 2
        aegisub.debug.out("Please select the second version of the Python script.\n")
        config.version_2 = select_sp_file_path()
        if not config.version_2 then
            aegisub.debug.out("Version 2 file selection canceled.\n")
            return
        end

        -- Save the updated configuration
        save_sp_config(config)
        aegisub.debug.out("Python script paths saved:\nVersion 1: " .. config.version_1 .. "\nVersion 2: " .. config.version_2 .. "\n")
        return
    elseif button == "التالي" then
        -- Determine which script to execute
        local selected_version = sp_result["version"]
        local py_file = selected_version == "الأولى" and config.version_1 or config.version_2
        
        if py_file then
            os.execute('python "' .. py_file .. '"')
        else
            aegisub.debug.out("No valid script path selected.")
        end
        -- Proceed with the next action if the config file exists
        aegisub.debug.out("Configuration file found, proceeding.")
    else
        return
    end

    -- Execute the Python script to perform corrections
    if config.file_path then
        os.execute('python "' .. config.file_path .. '"')
    end

    -- Read the spellecheck output from the Python script
    local output_path = get_sp_output_path()
    local result_file = io.open(output_path, "r")
    if result_file then
        local content = result_file:read("*all")
        local corrections_result = json.decode(content)
        result_file:close()

        -- Count changed words
        local review_lines_count = 0
        for i, corrected_text in ipairs(corrections_result) do
            if corrected_text ~= selected_text[i] then  -- Only count changed lines
                review_lines_count = review_lines_count + 1
            end
        end

        -- Modify the label and dialog for review lines
        local review_lines_count = 0
        local dialog_items = {
            {class="label", label="عدد الجُمل التي تحتاج مراجعة", x=1, y=0, width=2, height=1},
            {class="edit", name="review_lines_count", text=review_lines_count, x=0, y=0, width=1, height=1, readonly=true},
        }

        -- Lines y position 
        local y_pos = 1

        -- Loop over each line and add tables
        for i, result in ipairs(corrections_result) do
            local label = ""
            local correction_result_label = ""

            if result.needs_review then
                label = "تحتاج مراجعة"  -- Mark the line as needs review
                correction_result_label = "نتيجة التصحيح"  -- Label for corrected text
                review_lines_count = review_lines_count + 1
            end

            -- Original text tables
            table.insert(dialog_items, {class="edit", name="original-text_" .. i, text=result.original_text, x=0, y=y_pos, width=70, height=1})
            table.insert(dialog_items, {class="label", label=label, x=70, y=y_pos, width=1, height=1})

            -- Correction text tables
            if not result.needs_review then
                y_pos = y_pos + 1
                table.insert(dialog_items, {class="label", label="", x=0, y=y_pos, width=70, height=1}) -- Separator
                y_pos = y_pos + 1
            else
                y_pos = y_pos + 1
                table.insert(dialog_items, {class="edit", name="correction_result_" .. i, text=result.corrected_text, x=0, y=y_pos, width=70, height=1})
                table.insert(dialog_items, {class="label", label=correction_result_label, x=70, y=y_pos, width=1, height=1})

                -- Add a separator after the corrected text 
                y_pos = y_pos + 1
                table.insert(dialog_items, {class="label", label="", x=0, y=y_pos, width=70, height=1})  -- Separator
                y_pos = y_pos + 1
            end
        end

        -- Update the displayed count of lines that needs review
        dialog_items[2].text = tostring(review_lines_count)

        local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
        local button_pressed, edited_corrections = aegisub.dialog.display(dialog_items, buttons)

        if button_pressed == "تطبيق" then
            -- Apply only the original text back to the subtitles
            for i, line_index in ipairs(selected_lines) do
                local line = subtitles[line_index]
                -- Use the user-edited correction from the dialog, or fallback to the original text
                local edited_text = edited_corrections["original-text_" .. i]
                if edited_text and edited_text ~= "" then
                    line.text = edited_text  -- Apply the user-edited text
                else
                    line.text = selected_text[i]  -- Default to original input text
                end
                subtitles[line_index] = line
            end
            aegisub.set_undo_point(script_name)
            -- Clean up temporary files
            cleanup_sp_temp_files()
        elseif button_pressed == "نسخ الكل" then
            -- Copy all corrections to clipboard
            local all_corrections = {}
            for i = 1, #corrections_result do
                table.insert(all_corrections, edited_corrections["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
            -- Clean up temporary files
            cleanup_sp_temp_files()
        elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            cleanup_sp_temp_files()
        else
            -- Clean up temporary files
            cleanup_sp_temp_files()
        end

    end
end

aegisub.register_macro(script_name, script_description, spellchecker)
