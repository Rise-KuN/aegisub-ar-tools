script_name = "أدوات"
script_description = "أدوات متعددة الاستخدام"
script_author = "Rise-KuN"
script_version = "1.3.8"

include("unicode.lua")
local json = require 'json'
local lfs = require 'lfs'
local clipboard = require "clipboard"

lookup = {
 ['.'] = '‏.‏',
 [';'] = '؛‏' ,
 ['!'] = '‏!‏', 
 [']'] = ']‏', 
 ['['] = '‏]‏‏',
 [':'] = '‏:‏',
 ["«"] = '‏»‏',
 ['('] = '‏)‏‏‏', 
 [')'] = ')‏',
 ['»'] = '‏«‏',
 ['-'] = '‏-‏',
 ['"'] = '‏"‏', 
 ['،'] = '‏،‏', 
}

-- تصحيح النقاط آخر السطر
function fix_punctuation(subtitles, selected_lines, active_line)
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		
		aegisub.debug.out(string.format('Processing line %d: "%s"\n', i, l.text))
		aegisub.debug.out("Chars: \n")
		
		local in_tags = false
		local newtext = ""
		for c in unicode.chars(l.text) do
			aegisub.debug.out(c .. ' -> ')
			if c == "{" then
				in_tags = true
			end
			if in_tags then
				aegisub.debug.out(c .. " (ignored, in tags)\n")
				newtext = newtext .. c
			else
				if lookup[c] then
					aegisub.debug.out(lookup[c] .. " (converted)\n")
					newtext = newtext .. lookup[c]
				else
					aegisub.debug.out(c .. " (not found in lookup)\n")
					newtext = newtext .. c
				end
			end
			if c == "}" then
				in_tags = false
			end
		end
		
		l.text = newtext
		subtitles[i] = l
	end
	aegisub.set_undo_point("Punctuation fix")
end

-- أداة المُشكل
-- Directory for configuration
function get_cr_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\CR"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Get word correction mapping file
function get_word_correction_mapping_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\CR"
    lfs.mkdir(config_dir)
    return config_dir .. "\\word-correction-mapping.json"
end

-- Get commit hash
function get_commit_hash_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\CR"
    lfs.mkdir(config_dir)
    return config_dir .. "\\commit_hash.json"
end

-- Temporary file for input data
function get_correction_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\CR"
    lfs.mkdir(config_dir)
    return config_dir .. "\\cr_input.json"
end

-- Output file for corrections
function get_correction_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\CR"
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
			os.remove(output_path)
			local input_path = get_correction_input_path()
			os.remove(input_path)
			local word_correction_mapping_path = get_word_correction_mapping_path()
			os.remove(word_correction_mapping_path)
			local commit_hash_path = get_commit_hash_path()
			os.remove(commit_hash_path)
        elseif button_pressed == "نسخ الكل" then
            -- Copy all corrections to clipboard
            local all_corrections = {}
            for i = 1, #corrections_result do
                table.insert(all_corrections, edited_corrections["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
            -- Clean up temporary files
            os.remove(output_path)
            local input_path = get_correction_input_path()
            os.remove(input_path)
            local word_correction_mapping_path = get_word_correction_mapping_path()
            os.remove(word_correction_mapping_path)
            local commit_hash_path = get_commit_hash_path()
            os.remove(commit_hash_path)
        elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            os.remove(output_path)
            local input_path = get_correction_input_path()
            os.remove(input_path)
            local word_correction_mapping_path = get_word_correction_mapping_path()
            os.remove(word_correction_mapping_path)
            local commit_hash_path = get_commit_hash_path()
            os.remove(commit_hash_path) 
        else
            -- Clean up temporary files
            local output_path = get_correction_output_path()
            os.remove(output_path)
            local input_path = get_correction_input_path()
            os.remove(input_path)
            local word_correction_mapping_path = get_word_correction_mapping_path()
            os.remove(word_correction_mapping_path)
            local commit_hash_path = get_commit_hash_path()
            os.remove(commit_hash_path)
        end
    end
end

-- حذف نقاط آخر السطر
function remove_punctuation_1(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        -- Check if the line is in English
        if text:match("[a-zA-Z]") then
            -- Check if the line has before "\N"
            local new_text, changes = text:gsub("%.%s*(\\N)", "%1")
            if changes > 0 then
                count = count + changes
                hasChanges = true
            end

            -- Check if the line ends with a single "."
            if new_text:match("[^.]%.$") then
                -- Remove the last "."
                new_text = new_text:sub(1, -2)
                count = count + 1
                hasChanges = true
            end

            line.text = new_text
            subtitles[line_index] = line
            
        -- Check if the line is in Arabic
        else
            -- Check if the line contains more than one "."
            if text:find("%.+") and not text:find("%.%.+") then
                -- Remove "."
                text = text:gsub("[.]", "")
                count = count + 1
                line.text = text
                subtitles[line_index] = line
                hasChanges = true
            end
        end
    end

    if hasChanges then
        aegisub.debug.out("تمَّ حذف " .. count .. " نقاط")
    else
        aegisub.debug.out("لا توجد أي تغييرات")
    end

    aegisub.set_undo_point(script_name)
end

-- حذف علامة التعجب
function remove_punctuation_2(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        text = text:gsub("[%!]", "")
		
        -- Update The Count And Check If Any Changes Were Made
        if line.text ~= text then
            count = count + 1
            line.text = text
            subtitles[line_index] = line
            hasChanges = true
        end
    end

    if hasChanges then
        aegisub.debug.out("تمَّ حذف " .. count .. " علامة التعجب")
    else
        aegisub.debug.out("لا توجد أي تغييرات")
    end

    aegisub.set_undo_point(script_name)
end

-- حذف تقسيم السطر
function remove_punctuation_3(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        text = text:gsub("\\N", " ")
        text = text:gsub("  ", " ")
		
        -- Update The Count And Check If Any Changes Were Made
        if line.text ~= text then
            count = count + 1
            line.text = text
            subtitles[line_index] = line
            hasChanges = true
        end
    end

    if hasChanges then
        aegisub.debug.out("تمَّ حذف " .. count .. " تقسيم السطر")
    else
        aegisub.debug.out("لا توجد أي تغييرات")
    end

    aegisub.set_undo_point(script_name)
end

-- تغيير موضع الكليب
-- Parse clip coordinates into a table
function parse_clip_coordinates(clip_tag)
    local coords = {}
    for num in clip_tag:gmatch("[%-]?%d+%.?%d*") do
        table.insert(coords, tonumber(num))
    end
    return coords
end

-- RTL adjustment function
function calculate_rtl_clip(first_clip_coords, second_clip_coords)
    local first_clip_width = first_clip_coords[3] - first_clip_coords[1]
    local new_first_clip = {
        second_clip_coords[3] - first_clip_width,
        first_clip_coords[2],
        second_clip_coords[3],
        first_clip_coords[4]
    }
    local new_second_clip = {
        second_clip_coords[1] - first_clip_width,
        second_clip_coords[2],
        second_clip_coords[3],
        second_clip_coords[4]
    }
    return new_first_clip, new_second_clip
end

-- LTR adjustment function
function calculate_ltr_clip(first_clip_coords, second_clip_coords)
    local first_clip_width = first_clip_coords[3] - first_clip_coords[1]
    local new_first_clip = {
        second_clip_coords[1],
        first_clip_coords[2],
        second_clip_coords[1] + first_clip_width,
        first_clip_coords[4]
    }
    local new_second_clip = {
        second_clip_coords[1] + first_clip_width,
        second_clip_coords[2],
        second_clip_coords[3],
        second_clip_coords[4]
    }
    return new_first_clip, new_second_clip
end

-- Create clip tag string from coordinates
function create_clip_tag(coords, is_iclip)
    local tag_type = is_iclip and "\\iclip" or "\\clip"
    return tag_type .. "(" .. table.concat(coords, ",") .. ")"
end

-- Adjust clip positions in the line
function adjust_clip_positions(subtitles, line_index, direction)
    local line = subtitles[line_index]
    -- Find the first and second clip tags (clip or iclip)
    local first_clip_start, first_clip_end = line.text:find("\\[i]?clip%b()")
    local second_clip_start, second_clip_end = line.text:find("\\[i]?clip%b()", first_clip_end + 1)

    if first_clip_start and second_clip_start then
        -- Determine if it's an iclip
        local is_iclip = line.text:sub(first_clip_start, first_clip_start + 5) == "\\iclip"

        local first_clip = line.text:sub(first_clip_start, first_clip_end)
        local second_clip = line.text:sub(second_clip_start, second_clip_end)
        local first_clip_coords = parse_clip_coordinates(first_clip)
        local second_clip_coords = parse_clip_coordinates(second_clip)

        local new_first_clip_coords, new_second_clip_coords
        if direction == "RTL" then
            new_first_clip_coords, new_second_clip_coords = calculate_rtl_clip(first_clip_coords, second_clip_coords)
        elseif direction == "LTR" then
            new_first_clip_coords, new_second_clip_coords = calculate_ltr_clip(first_clip_coords, second_clip_coords)
        end

        local new_first_clip = create_clip_tag(new_first_clip_coords, is_iclip)
        local new_second_clip = create_clip_tag(new_second_clip_coords, is_iclip)

        line.text = line.text:sub(1, first_clip_start - 1) ..
                    new_first_clip ..
                    line.text:sub(first_clip_end + 1, second_clip_start - 1) ..
                    new_second_clip ..
                    line.text:sub(second_clip_end + 1)
        subtitles[line_index] = line

        -- aegisub.debug.out("Adjusted clips (" .. direction .. "):\n" .. new_first_clip .. "\n" .. new_second_clip .. "\n")
    else
        aegisub.debug.out("Couldn't find the required clip tags.\n")
    end
end

-- Process selected lines
function adjust_clips(subtitles, selected_lines, active_line)
    -- Dropdown dialog
    local clip_choices = {"RTL", "LTR"}
    local dialog = {
        {class="label", label=":اتجاه الكليب", x=1, y=0, width=2, height=1},
        {class="dropdown", name="clip", items=clip_choices, value=clip_choices[1], x=0, y=0, width=1, height=1}
    }
    local button, result = aegisub.dialog.display(dialog, {"اختيار", "إلغاء"})
    if button ~= "اختيار" then return end

    local selected_direction = result.clip

    for _, i in ipairs(selected_lines) do
        adjust_clip_positions(subtitles, i, selected_direction)
    end

    -- aegisub.set_undo_point("Adjust Clip Positions (" .. selected_direction .. ")")
end

-- حساب نسبة التقدم
function calculate_progress(subtitles, selected_lines, active_line)
    -- Define the dialog box layout
    dialog_config = {
        {
            class = "label",
            label = ":رقم آخر سطر تمت ترجمته",
            x = 1, y = 0, width = 1, height = 1
        },
        {
            class = "intedit", name = "last_line", value = 0,
            x = 0, y = 0, width = 1, height = 1
        },
        {
            class = "label",
            label = ":العدد الإجمالي للأسطر",
            x = 1, y = 1, width = 1, height = 1
        },
        {
            class = "intedit", name = "total_lines", value = 0,
            x = 0, y = 1, width = 1, height = 1
        }
    }

    -- Show the dialog box
    buttons = {"احسب", "إلغاء"}
    pressed, results = aegisub.dialog.display(dialog_config, buttons)

    -- If "Cancel" is pressed, do nothing
    if pressed == "إلغاء" then
        aegisub.cancel()
        return
    end

    -- Get the input values
    local last_line = results.last_line
    local total_lines = results.total_lines

    -- Validate input
    if total_lines == 0 then
        aegisub.dialog.display({{class = "label", label = ".إجمالي عدد الأسطر يجب أن يكون أكبر من الصفر", x = 0, y = 0, width = 1, height = 1}}, {"موافق"})
        return
    end

    -- Calculate progress percentage
    local progress_percentage = (last_line / total_lines) * 100

    -- Show the result
    aegisub.dialog.display({{class = "label", label = "%" .. "نسبة التقدم: " .. string.format("%.2f", progress_percentage), x = 0, y = 0, width = 1, height = 1}}, {"موافق"})
end

-- ترجمة من لغة إلى لغة أخرى
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

-- تعديل النصوص
function edit_selected_text(subtitles, selected_lines)
    local selected_text = {}

    -- Collect selected text and combine into one string with line breaks
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end
    local combined_text = table.concat(selected_text, "\n")

    -- Display the dialog with a single editable text box
    local dialog_items = {
        {class="label", label="التي على يمين الكيبورد لتحويل النص من اليمين لليسار ctrl + shift اضغط على", x=0, y=0, width=70, height=1},
        {class="textbox", name="edit_text", text=combined_text, x=0, y=1, width=70, height=25}
    }

    local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
    local button_pressed, edited_text = aegisub.dialog.display(dialog_items, buttons)

    if button_pressed == "تطبيق" then
        -- Apply edited text to the selected lines
        local new_lines = {}
        for line in edited_text["edit_text"]:gmatch("[^\n]+") do
            table.insert(new_lines, line)
        end
        for i, line_index in ipairs(selected_lines) do
            local line = subtitles[line_index]
            line.text = new_lines[i] or ""
            subtitles[line_index] = line
        end
        aegisub.set_undo_point(script_name)
    elseif button_pressed == "نسخ الكل" then
        -- Copy all edited text to clipboard
        clipboard.set(edited_text["edit_text"])
    end
end

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

-- تغيير اتجاه الحروف
function reverse_text(text)
    local reversed = {}
    -- Iterate through each character in the text using unicode.chars
    for char in unicode.chars(text) do
        -- Insert each character at the start of the table to reverse it
        table.insert(reversed, 1, char) 
    end
    return table.concat(reversed) -- Join the table back into a string
end

function swap_characters(subtitles, selected_lines)
    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        line.text = reverse_text(line.text) -- Reverse the text
        subtitles[i] = line
    end
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro("أدوات/تصحيح نقاط آخر السطر", "تصحيح نقاط آخر السطر", fix_punctuation)
aegisub.register_macro("أدوات/حذف نقاط آخر السطر", "حذف نقاط آخر السطر", remove_punctuation_1)
aegisub.register_macro("أدوات/حذف علامة التعجب", "حذف علامة التعجب", remove_punctuation_2)
aegisub.register_macro("أدوات/حذف تقسيم السطر", "حذف تقسيم السطر", remove_punctuation_3)
aegisub.register_macro("أدوات/تغيير موضع الكليب", "تغيير موضع الكليب", adjust_clips)
aegisub.register_macro("أدوات/تغيير شكل الكلمات العربية", "تغيير شكل الكلمات العربية", add_ar_reshape_to_words)
aegisub.register_macro("أدوات/تغيير اتجاه الحروف", "تغيير اتجاه الحروف", swap_characters)
aegisub.register_macro("أدوات/حساب نسبة التقدم", "حساب نسبة التقدم", calculate_progress)
aegisub.register_macro("أدوات/تعديل النصوص", "تعديل النصوص", edit_selected_text)
aegisub.register_macro("أدوات/ترجمة متعددة", "ترجمة متعددة", translate_with_external_script)
aegisub.register_macro("أدوات/المُشكل", "المُشكل", correct_words)
