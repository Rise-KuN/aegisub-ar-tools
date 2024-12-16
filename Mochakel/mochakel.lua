script_name = "المُشكل"
script_description = "تشكيل الكلمات العربية"
script_author = "Rise-KuN"
script_version = "2.1.5"

-- أداة المُشكل

local json = require 'json'
local lfs = require 'lfs'
local clipboard = require "clipboard"

-- Directory for configuration
function get_cr_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\mochakel"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Get word correction mapping file
function get_word_correction_mapping_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\mochakel"
    lfs.mkdir(config_dir)
    return config_dir .. "\\word-correction-mapping.json"
end

-- Get commit hash
function get_commit_hash_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\mochakel"
    lfs.mkdir(config_dir)
    return config_dir .. "\\commit_hash.json"
end

-- Temporary file for input data
function get_correction_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\mochakel"
    lfs.mkdir(config_dir)
    return config_dir .. "\\cr_input.json"
end

-- Output file for corrections
function get_correction_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\mochakel"
    return config_dir .. "\\cr_output.json"
end

-- Load saved config
function load_cr_config()
    local config_path = get_cr_config_path()
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
function save_cr_config(config)
    local config_path = get_cr_config_path()
    local file = io.open(config_path, "w")
    file:write(json.encode(config))
    file:close()
end

-- Save selected text for correction
function save_correction_input(data)
    local input_path = get_correction_input_path()

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
function select_cr_file_path()
    local file_path = aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
    return file_path
end

-- Function to count words in a string
function count_words(str)
    local _, count = str:gsub("%S+", "")  -- Count non-whitespace sequences
    return count
end

-- Clean Temp Files
local function cleanup_cr_temp_files()
    local output_path = get_correction_output_path()
    os.remove(output_path)
    local input_path = get_correction_input_path()
    os.remove(input_path)
    local word_correction_mapping_path = get_word_correction_mapping_path()
    os.remove(word_correction_mapping_path)
    local commit_hash_path = get_commit_hash_path()
    os.remove(commit_hash_path)
end

-- Correct words using the Python script
function correct_words(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made
    local selected_text = {}
    local corrections_map = {} -- To store your word correction mapping

    -- Load word correction mapping
    local word_correction_mapping_path = get_word_correction_mapping_path()
    local file = io.open(word_correction_mapping_path, "r")
    if file then
        local content = file:read("*all")
        file:close()
        corrections_map = json.decode(content)
    end

    -- Collect selected text
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end

    -- Save selected text to JSON
    local config = load_cr_config()
    local translation_data = {
        selected_text = selected_text
    }
    save_correction_input(translation_data)
    
    -- Open dialog to select Python file if not set
    local cr_first_dialog = {
        {class="label", label="", x=1, y=0, width=1, height=1},
    }
    local button, cr_result = aegisub.dialog.display(cr_first_dialog, {"التالي", "إلغاء", "مسار الأداة"})

    -- If "مسار الأداة" is clicked, let the user select the Python file
    if button == "مسار الأداة" then
        config.file_path = select_cr_file_path()
        if config.file_path then
            save_cr_config(config)
            aegisub.debug.out("Python script path set to: " .. config.file_path)
        else
            aegisub.debug.out("No Python file selected.")
            return
        end
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

    -- Execute the Python script to perform corrections
    if config.file_path then
        os.execute('python "' .. config.file_path .. '"')
    end

    -- Read the corrected output from the Python script
    local output_path = get_correction_output_path()
    local result_file = io.open(output_path, "r")
    if result_file then
        local content = result_file:read("*all")
        local corrections_result = json.decode(content)
        result_file:close()

        -- Count changed words
        local corrected_lines_count = 0
        for i, corrected_text in ipairs(corrections_result) do
            if corrected_text ~= selected_text[i] then  -- Only count changed lines
                corrected_lines_count = corrected_lines_count + 1
            end
        end

        -- Display the corrected text label and count
        local corrected_lines_count = 0
        local dialog_items = {
            {class="label", label="عدد الجُمل الّتي تمَّ تعديلها", x=1, y=0, width=2, height=1},
            {class="edit", name="changed_word_count", text=corrected_lines_count, x=0, y=0, width=1, height=1, readonly=true},
        }

        -- Display the corrected text with the label "تم تعديلها"
        for i, corrected_text in ipairs(corrections_result) do
            local label = ""
            -- Check if the corrected text is different from the original (to detect changes)
            if corrected_text ~= selected_text[i] then
                label = "تمَّ تعديلها"  -- Mark the line as corrected
                corrected_lines_count = corrected_lines_count + 1  -- Increment corrected line count
            end

            -- Add the corrected text and the label to the dialog items
            table.insert(dialog_items, {class="edit", name="correction_" .. i, text=corrected_text, x=0, y=i+1, width=70, height=1})
            table.insert(dialog_items, {class="label", label=label, x=70, y=i+1, width=1, height=1})
        end

        -- Update the displayed count
        dialog_items[2].text = tostring(corrected_lines_count)

        local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
        local button_pressed, edited_corrections = aegisub.dialog.display(dialog_items, buttons)

        if button_pressed == "تطبيق" then
			-- Apply the corrections to the subtitles
			for i, line_index in ipairs(selected_lines) do
				local line = subtitles[line_index]
				-- Use the user-edited correction from the dialog
				local edited_text = edited_corrections["correction_" .. i]
				if edited_text and edited_text ~= "" then
					line.text = edited_text  -- Apply the edited text
				else
					-- Fallback to original correction if no user edit was made
					line.text = corrections_result[i]
				end
				subtitles[line_index] = line
			end
			aegisub.set_undo_point(script_name)
			-- Clean up temporary files
            cleanup_cr_temp_files()
        elseif button_pressed == "نسخ الكل" then
            -- Copy all corrections to clipboard
            local all_corrections = {}
            for i = 1, #corrections_result do
                table.insert(all_corrections, edited_corrections["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
            -- Clean up temporary files
            cleanup_cr_temp_files()
        elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            cleanup_cr_temp_files()
        else
            -- Clean up temporary files
            cleanup_cr_temp_files()
        end
    end
end

aegisub.register_macro(script_name, script_description, correct_words)
