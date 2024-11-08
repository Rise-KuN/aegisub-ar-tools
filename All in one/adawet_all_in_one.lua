script_name = "أدوات الحذف"
script_description = "أدوات حذف نقاط آخر السطر وتقسم السطر"
script_author = "Rise-KuN"
script_version = "1.3.0"

include("unicode.lua")

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
    local file = io.open(input_path, "w")
    file:write(json.encode(data))
    file:close()
end

-- Select file for Python script
function select_cr_file_path()
    local file_path = aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
    return file_path
end

-- Correct words using the Python script
function correct_words(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made
    local selected_text = {}
    
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
    local language_dialog = {
        {class="label", label="", x=1, y=0, width=1, height=1},
    }
    local button, language_result = aegisub.dialog.display(language_dialog, {"التالي", "إلغاء", "مسار الأداة"})

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
    elseif button ~= "التالي" then
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

        -- Display the corrected text
        local dialog_items = {}
        for i, corrected_text in ipairs(corrections_result) do
            table.insert(dialog_items, {class="edit", name="correction_" .. i, text=corrected_text, x=0, y=i, width=75, height=1})
        end

        local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
        local button_pressed, edited_corrections = aegisub.dialog.display(dialog_items, buttons)

        if button_pressed == "تطبيق" then
            -- Apply the corrections
            for i, line_index in ipairs(selected_lines) do
                local line = subtitles[line_index]
                line.text = edited_corrections["correction_" .. i] or ""
                subtitles[line_index] = line
            end
            aegisub.set_undo_point(script_name)
        elseif button_pressed == "نسخ الكل" then
            -- Copy all corrections to clipboard
            local all_corrections = {}
            for i = 1, #corrections_result do
                table.insert(all_corrections, edited_corrections["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
        end
    else
        aegisub.debug.out("Error: Could not open cr_output.json. Check if the Python script ran correctly.")
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
function swap_clip(subtitles, line_index)
    local line = subtitles[line_index]
    local first_clip_start, first_clip_end = line.text:find("\\[i]?clip%b()")
    local second_clip_start, second_clip_end = line.text:find("\\[i]?clip%b()", first_clip_end + 1)
    
    if first_clip_start and second_clip_start then
        local first_clip = line.text:sub(first_clip_start, first_clip_end)
        local second_clip = line.text:sub(second_clip_start, second_clip_end)
        
        -- Print the contents of first and second clip tags
        aegisub.debug.out("First: " .. first_clip .. "\n")
        aegisub.debug.out("Second: " .. second_clip .. "\n")
        
        local new_text = line.text:sub(1, first_clip_start - 1) ..
                         second_clip ..
                         line.text:sub(first_clip_end + 1, second_clip_start - 1) ..
                         first_clip ..
                         line.text:sub(second_clip_end + 1)
        
        -- Print the new text for debugging
        aegisub.debug.out("New Text: " .. new_text .. "\n")
        
        -- Update the line in the selected line
        line.text = new_text
        subtitles[line_index] = line
        
        aegisub.debug.out("Swapped clip tags.\n")
    else
        aegisub.debug.out("Couldn't find any clip tags.\n")
    end
end

-- Function to process selected lines
function swap_clip_positions(subtitles, selected_lines, active_line)
    for _, i in ipairs(selected_lines) do
        swap_clip(subtitles, i)
    end
    aegisub.set_undo_point("Swap clip positions")
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
local json = require 'json'
local lfs = require 'lfs'

function get_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

function get_translation_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    lfs.mkdir(config_dir)
    return config_dir .. "\\translation_input.json"
end

function get_translation_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\JPTL"
    return config_dir .. "\\translation_output.json"
end

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

function save_config(config)
    local config_path = get_config_path()
    local file = io.open(config_path, "w")
    file:write(json.encode(config))
    file:close()
end

function save_translation_input(data)
    local input_path = get_translation_input_path()
    local file = io.open(input_path, "w")
    file:write(json.encode(data))
    file:close()
end

function select_file_path()
    local file_path = aegisub.dialog.open("اختر ملف", "", "", "*.py", false, true)
    return file_path
end

function translate_with_external_script(subtitles, selected_lines, active_line)
    local config = load_config()
    local clipboard = require "clipboard"
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
    elseif button ~= "التالي" then
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

    if config.file_path then
        os.execute('python "' .. config.file_path .. '"')
    else
        aegisub.debug.out("Error: Python script path not set. Please select the correct file path.")
        return
    end

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
            for i, line_index in ipairs(selected_lines) do
                local line = subtitles[line_index]
                line.text = edited_translations["translation_" .. i] or ""
                subtitles[line_index] = line
            end
            aegisub.set_undo_point(script_name)
        elseif button_pressed == "نسخ الكل" then
            local all_translations = {}
            for i = 1, #translations do
                table.insert(all_translations, edited_translations["translation_" .. i] or "")
            end
            clipboard.set(table.concat(all_translations, "\n"))
        end
    else
        aegisub.debug.out("Error: Could not open translation_output.json. Please check if the Python script ran correctly.")
    end
end

aegisub.register_macro("أدوات/تصحيح النقاط آخر السطر", "تصحيح النقاط آخر السطر", fix_punctuation)
aegisub.register_macro("أدوات/المُشكل", "المُشكل", correct_words)
aegisub.register_macro("أدوات/حذف نقاط آخر السطر", "حذف نقاط آخر السطر", remove_punctuation_1)
aegisub.register_macro("أدوات/حذف علامة التعجب", "حذف علامة التعجب", remove_punctuation_2)
aegisub.register_macro("أدوات/حذف تقسيم السطر", "حذف تقسيم السطر", remove_punctuation_3)
aegisub.register_macro("أدوات/تغيير موضع الكليب", "تغيير موضع الكليب", swap_clip_positions)
aegisub.register_macro("أدوات/حساب نسبة التقدم", "حساب نسبة التقدم", calculate_progress)
aegisub.register_macro("أدوات/ترجة متعددة", "ترجة متعددة", translate_with_external_script)