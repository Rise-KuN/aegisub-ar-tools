script_name = "أدوات"
script_description = "أدوات متعددة الاستخدام"
script_author = "Rise-KuN"
script_version = "1.5.5"

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

function fix_punctuation_unicode(subtitles, selected_lines, active_line)
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

-- تصحيح موضع العلامات والنقاط
function fix_punctuation(subtitles, selected_lines, active_line)
    -- Punctuation marks List
    local punctuation = {
        "!", ":", "؛", "،", "%.", "%.%.%.", "%-", "%_", "%$", "%@", "«", "»", '"', "%[", "%]"
    }

    local pattern = "([%p]+)(%s*)$"

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local original_text = line.text
        local text = original_text
        local punctuation_count = 0

        -- Create a list to store parts of the line (text and tags)
        local parts = {}
        local tag_parts = {}

        -- Split the line into text and tags preserving the structure
        local function split_text_and_tags(text)
            local i = 1
            while i <= #text do
                local char = text:sub(i, i)
                if char == "{" then
                    local tag = text:match("{[^}]*}", i)
                    if tag then
                        table.insert(parts, tag)
                        i = i + #tag
                    end
                else
                    local non_tag = text:match("([^{]*)", i)
                    table.insert(parts, non_tag)
                    i = i + #non_tag
                end
            end
        end
        split_text_and_tags(text)

        -- Remove spaces between \N
        local function clean_up_n_space(parts)
            for i, part in ipairs(parts) do
                -- Remove leading and trailing spaces around \N
                parts[i] = part:gsub("%s*\\N%s*", "\\N")
            end
        end
        clean_up_n_space(parts)

        -- Handle the text parts
        local function process_with_punctuation(parts)
            -- Split the text to parts based on \N
            local segments = {}
            for _, part in ipairs(parts) do
                -- Only process the part if its not a tag
                if not part:match("^{.*}$") then
                    -- Split by \N to handle each segment separately
                    local sub_parts = {}
                    for sub_part in part:gmatch("[^\\N]+") do
                        table.insert(sub_parts, sub_part)
                    end

                    -- Process each sub_part and move punctuations from the end to the start
                    for i, sub_part in ipairs(sub_parts) do
                        local punc_at_end = sub_part:match(pattern)
                        if punc_at_end then
                            punctuation_count = punctuation_count + 1
                            sub_part = sub_part:gsub(pattern, "")
                            sub_part = punc_at_end .. sub_part
                            sub_parts[i] = sub_part
                        end
                    end

                    -- Rejoin the sub_parts and add the processed segment
                    local new_segment = table.concat(sub_parts, "\\N")
                    table.insert(segments, new_segment)
                else
                    -- If it's a tag add it without modification
                    table.insert(segments, part)
                end
            end
            return segments
        end

        -- Process punctuation handling
        parts = process_with_punctuation(parts)

        -- Rebuild the text from the processed parts
        text = table.concat(parts)

        -- Debugging
        --aegisub.debug.out("Line: " .. line_index .. "\n")
        --aegisub.debug.out("Original Text: " .. original_text .. "\n")
        --aegisub.debug.out("Modified Text: " .. text .. "\n")
        --aegisub.debug.out("Punctuation Detected: " .. punctuation_count .. "\n\n")

        -- Update the line text
        line.text = text
        subtitles[line_index] = line
    end

    aegisub.set_undo_point(script_name)
end

-- أداة المُشكل
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

-- 'أداة حذف 'نقاط آخر السطر' 'تقسيم السطر' علامة التعجب
-- Remove Periods for Arabic and English
function remove_periods(subtitles, selected_lines)
    local count = 0
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        -- Check for the Arabic special character
        local function count_special_arabic_periods(text)
            local count = 0
            for _ in text:gmatch("‏%.‏") do
                count = count + 1
            end
            return count
        end

        -- Debugging: count periods
        local arabic_special_period = count_special_arabic_periods(text)
        --aegisub.debug.out("Text:" .. text .. "\n\n")
        --aegisub.debug.out("Number of RTL periods:" .. arabic_period_count .. "\n\n\n")

        -- Temporarily replace \N with a placeholder __&__
        text = text:gsub("\\N", "__&__")

        -- Handle English Text
        if text:match("[a-zA-Z]") then
            -- Remove end of line periods before and after line breaks \N except ellipses "..."
            text = text:gsub("%.%s*(__&__)", "%1")  -- Period before __&__
            text = text:gsub("(__&__)%.%s*", "%1")  -- Period after __&__
            -- Remove trailing period except ("...")
            if text:sub(-1) == "." and text:sub(-3) ~= "..." then
                text = text:sub(1, -2)
            end

        -- Handle Arabic text
        elseif arabic_special_period > 0 then
            -- Temporarily replace "..." with a placeholder
            text = text:gsub("%.%.%.", "___$___")
            -- Process Arabic special character periods
            text = text:gsub("‏%.‏%s*(__&__)", "%1")   -- Remove RTL period before \N
            text = text:gsub("(__&__)%s*‏%.‏", "%1")   -- Remove RTL period after \N
            text = text:gsub("‏%.‏$", "")              -- Remove trailing RTL period
            -- Restore the ellipsis
            text = text:gsub("___$___", "...")
        else
            -- Temporarily replace "..." with a placeholder
            text = text:gsub("%.%.%.", "___$___")
            -- Process Arabic standard periods
            text = text:gsub("%.%s*(?=__&__)", "")    -- Remove periods before \N
            text = text:gsub("__&__%s*%.", "__&__")   -- Remove periods after \N
            text = text:gsub("%.$", "")               -- Remove periods at the end of the line
            text = text:gsub("^%.", "")               -- Remove periods at the beginning of the line
            -- Restore the ellipsis
            text = text:gsub("___$___", "...")
        end

        -- Make the \N like it was by replacing __&__ to \N
        text = text:gsub("__&__", "\\N")

        -- Check if the text was modified
        if line.text ~= text then
            line.text = text
            subtitles[line_index] = line
            count = count + 1
        end
    end
    aegisub.debug.out("تمَّ تعديل " .. count .. " أسطر\n\n")
end

-- Function to remove line breaks
function remove_line_breaks(subtitles, selected_lines)
    local count = 0
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        -- Replace line breaks with spaces
        text = text:gsub("\\N", " "):gsub("  ", " ")

        if line.text ~= text then
            line.text = text
            subtitles[line_index] = line
            count = count + 1
        end
    end
    aegisub.debug.out("تمَّ حذف " .. count .. " تقسيم السطر\n\n")
end

-- Function to remove exclamation marks
function remove_exclamation_marks(subtitles, selected_lines)
    local count = 0
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        -- Remove exclamation marks
        text = text:gsub("!", "")

        if line.text ~= text then
            line.text = text
            subtitles[line_index] = line
            count = count + 1
        end
    end
    aegisub.debug.out("تمَّ حذف " .. count .. " علامة التعجب\n\n")
end

-- Remove Tool Pop-Up Dialogue
function remove_tool(subtitles, selected_lines, active_line)
    local remove_choices = {"نقاط آخر السطر", "تقسيم السطر", "علامة التعجب"}
    local dialog = {
        {class="label", label=":اختر نوع الحذف", x=1, y=0, width=2, height=1},
        {class="dropdown", name="remove", items=remove_choices, value=remove_choices[1], x=0, y=0, width=1, height=1}
    }
    local button, result = aegisub.dialog.display(dialog, {"اختيار", "إلغاء"})
    if button ~= "اختيار" then return end

    local remove_type = result.remove

    if remove_type == "نقاط آخر السطر" then
        remove_periods(subtitles, selected_lines)
    elseif remove_type == "تقسيم السطر" then
        remove_line_breaks(subtitles, selected_lines)
    elseif remove_type == "علامة التعجب" then
        remove_exclamation_marks(subtitles, selected_lines)
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

-- تقسيم السطر إلى فريمات
-- Helper function to deep copy a table
function deep_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deep_copy(orig_key)] = deep_copy(orig_value)
        end
        setmetatable(copy, deep_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- Calculate the video frame rate
function calculate_fps()
    local start_ms = 0  -- Starting time in milliseconds
    local end_ms = 1000 -- End time in milliseconds (1 second)

    local start_frame = aegisub.frame_from_ms(start_ms)
    local end_frame = aegisub.frame_from_ms(end_ms)

    -- Number of frames in one second is the frame rate
    return end_frame - start_frame
end

function split_line_to_frames(subtitles, selected_lines)
    aegisub.progress.task("Splitting line to frames...")

    -- Default frame rate
    -- local frame_rate = 23.976
    local frame_rate = calculate_fps()
    --aegisub.debug.out("frame rate: " .. frame_rate .. " fps\n")

    -- Frame duration in milliseconds
    local frame_duration = 1000 / frame_rate

    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        local start_time = line.start_time
        local end_time = line.end_time
        local duration = end_time - start_time

        -- Calculate the number of frames
        local num_frames = math.floor(duration / frame_duration)

        for frame = 0, num_frames - 1 do
            local new_line = deep_copy(line)
            new_line.start_time = start_time + frame * frame_duration
            new_line.end_time = math.min(new_line.start_time + frame_duration, end_time)
            subtitles.insert(i + frame, new_line)
        end

        -- Remove the original line
        subtitles.delete(i + num_frames)
    end

    aegisub.set_undo_point(script_name)
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
    local config_dir = appdata .. "\\Aegisub\\adawet\\translate"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Input file for translation
function get_translation_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\translate"
    lfs.mkdir(config_dir)
    return config_dir .. "\\translation_input.json"
end

-- Output file for translation
function get_translation_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\translate"
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

-- Clean Temp Files
local function cleanup_jptl_temp_files()
    local translation_input_path = get_translation_input_path()
    local translation_output_path = get_translation_output_path()
    os.remove(translation_input_path)
    os.remove(translation_output_path)
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
            cleanup_jptl_temp_files()
        elseif button_pressed == "نسخ الكل" then
            local all_translations = {}
            for i = 1, #translations do
                table.insert(all_translations, edited_translations["translation_" .. i] or "")
            end
            clipboard.set(table.concat(all_translations, "\n"))
            -- Clean up temporary files
            cleanup_jptl_temp_files()
        elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            cleanup_jptl_temp_files()
        else
            -- Clean up temporary files
            cleanup_jptl_temp_files()
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
-- Directory for configuration
function get_ar_reshape_config_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\AR-Reshape"
    lfs.mkdir(config_dir)
    return config_dir .. "\\config.json"
end

-- Temporary file for input data
function get_ar_reshape_input_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\AR-Reshape"
    lfs.mkdir(config_dir)
    return config_dir .. "\\ar_reshape_input.json"
end

-- Output file for ar_reshape
function get_ar_reshape_output_path()
    local appdata = os.getenv("APPDATA")
    local config_dir = appdata .. "\\Aegisub\\adawet\\AR-Reshape"
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

-- Clean Temp Files
local function cleanup_reshape_temp_files()
    local output_path = get_ar_reshape_output_path()
    local input_path = get_ar_reshape_input_path()
    os.remove(output_path)
    os.remove(input_path)
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
        -- aegisub.debug.out("Configuration file found, proceeding.\n")
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
            cleanup_reshape_temp_files()
        elseif button_pressed == "نسخ الكل" then
            -- Copy all text result to clipboard
            local all_corrections = {}
            for i = 1, #updated_text_result do
                table.insert(all_corrections, edited_updated_text["correction_" .. i] or "")
            end
            clipboard.set(table.concat(all_corrections, "\n"))
            -- Clean up temporary files
            cleanup_reshape_temp_files()
		elseif button_pressed == "إلغاء" then
            -- Clean up temporary files
            cleanup_reshape_temp_files()
        else
            -- Clean up temporary files
            cleanup_reshape_temp_files()
        end
    else
        aegisub.debug.out("Error: Could not open ar_reshape_output.json. Check if the Python script ran correctly.\n")
    end
end


-- تغيير اتجاه النص
-- Reverse characters in a string
function reverse_characters(text)
    local reversed = {}
    for char in unicode.chars(text) do
        table.insert(reversed, 1, char)
    end
    return table.concat(reversed)
end

-- Reverse words in a string
function reverse_words(text)
    local words = {}
    local word_start = 1
    for i = 1, #text + 1 do
        local char = text:sub(i, i)
        if char == " " or i > #text then
            table.insert(words, text:sub(word_start, i - 1))
            word_start = i + 1
        end
    end
    local reversed_words = {}
    for i = #words, 1, -1 do
        table.insert(reversed_words, words[i])
    end
    return table.concat(reversed_words, " ")
end

-- Reverse characters while preserving tags and \N
function reverse_characters_preserving_tags(text)
    local placeholder = "__N__"
    text = text:gsub("\\N", placeholder)
    local segments = {}
    local last_pos = 1
    for literal, tag in text:gmatch("([^{}\\]*)([{\\][^{}]*})") do
        if literal and literal ~= "" then
            table.insert(segments, reverse_characters(literal))
        end
        if tag and tag ~= "" then
            table.insert(segments, tag)
        end
        last_pos = last_pos + #literal + #tag
    end
    if last_pos <= #text then
        local remaining = text:sub(last_pos)
        table.insert(segments, reverse_characters(remaining))
    end
    local reversed_text = table.concat(segments)
    return reversed_text:gsub(placeholder, "\\N")
end

-- Reverse words while preserving tags and \N
function reverse_words_preserving_tags(text)
    local placeholder = "__N__"
    text = text:gsub("\\N", placeholder)
    local tag_placeholders = {}
    local leading_tag = ""
    if text:match("^{[^}]*}") then
        leading_tag = text:match("^{[^}]*}")
        text = text:sub(#leading_tag + 1)
    end
    text = text:gsub("{[^}]*}", function(tag)
        local id = #tag_placeholders + 1
        tag_placeholders[id] = tag
        return "__TAG" .. id .. "__"
    end)
    text = reverse_words(text)
    for id, tag in ipairs(tag_placeholders) do
        text = text:gsub("__TAG" .. id .. "__", tag)
    end
    text = leading_tag .. text
    return text:gsub(placeholder, "\\N")
end

-- Reverse text based on selection
function reverse_text(subtitles, selected_lines, reverse_type)
    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        
        -- Print the selected line
        --aegisub.debug.out("Selected Line: " .. line.text .. "\n\n")
        
        if reverse_type == "الحروف" then
            line.text = reverse_characters_preserving_tags(line.text)
        elseif reverse_type == "الكلمات" then
            line.text = reverse_words_preserving_tags(line.text)
        end
        
        -- Print the reversed line
        --aegisub.debug.out("Reversed Line: " .. line.text .. "\n")
        
        subtitles[i] = line
    end
    aegisub.set_undo_point(script_name)
end

-- Reverse Text Dialog
function reverse_text_direction(subtitles, selected_lines)
    local reverse_choices = {"الحروف", "الكلمات"}
    local dialog = {
        {class="label", label=":عكس", x=1, y=0, width=2, height=1},
        {class="dropdown", name="reverse", items=reverse_choices, value=reverse_choices[1], x=0, y=0, width=1, height=1}
    }
    local button, result = aegisub.dialog.display(dialog, {"اختيار", "إلغاء"})
    if button ~= "اختيار" then return end
    reverse_text(subtitles, selected_lines, result.reverse)
end

-- حذف ما بين الكلمات
-- Handle the main dialog and text removal
function remove_text_between_characters(subtitles, selected_lines, active_line)
    -- Configuration for delete_selected_char by choosing (True/False)
    local delete_config = {"True", "False"}
	
	-- Dialogs
    local dialog = {
        -- Delete Start and End Characters Option
        {class="label", label=":حذف الحرف/الكلمة", x=50, y=1, width=2, height=1},
        {class="dropdown", name="delete_selected_char", items=delete_config, value=delete_config[1], x=0, y=1, width=50, height=1},
        
        -- Start From Option
        {class="label", label=":البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_char", text="", x=0, y=3, width=50, height=1},
        
        -- End From Option
        {class="label", label=":النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_char", text="", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Get the "start_char" and "end_char" setting from the dialog and convert to boolean
        local delete_selected_char = (res.delete_selected_char == "True")

        -- Get the start and end characters/words from the dialog
        local start_char = res.start_char
        local end_char = res.end_char

        -- Iterate over the selected lines
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Print the start_char and end_char in debug output
            --aegisub.debug.out("Start: '" .. start_char .. "' | End: '" .. end_char .. "'\n\n")
            
            -- Print the original line in the debug output
            --aegisub.debug.out("Original Line: " .. line.text .. "\n\n")

            -- Remove the text between the start and end characters/words
            local new_text = remove_text(line.text, start_char, end_char, delete_selected_char)

            -- Print the updated line in the debug output
            --aegisub.debug.out("Updated Line: " .. new_text .. "\n")

            -- Update the subtitle line with the new text
            line.text = new_text
            subtitles[i] = line
        end
    end
end

-- Remove text between start and end
function remove_text(text, start_char, end_char, delete_selected_char)
    -- Escape special characters for Lua patterns
    start_char = escape_lua_pattern(start_char)
    end_char = escape_lua_pattern(end_char)

    -- Lua pattern to match text between the start and end
    local pattern = start_char .. "(.-)" .. end_char
    
    -- Check if we should to delete the start and end characters
    local new_text
    if delete_selected_char then
        -- If delete_selected_char is true, remove the start and end characters as well
        new_text = text:gsub(pattern, "")
    else
        -- If delete_selected_char is false, keep the start and end characters
        new_text = text:gsub(pattern, start_char .. end_char)
    end

    -- Return the updated text
    return new_text
end

-- Escape special characters in Lua patterns
function escape_lua_pattern(str)
    return str:gsub("([%.%^%$%(%)%[%]%%%+%-%?])", "%%%1")
end

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
        --aegisub.debug.out("Configuration file found, proceeding.")
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

-- إضافة بلر للتترات
function add_blur_to_selected_lines(subtitles, selected_lines, active_line)
    -- Blur Placment Config
    local blur_placement_config = {"Start", "End"}
	
	-- Dialogs
    local dialog = {
        -- Blur Placement Option
        {class="label", label=":مكان البلر", x=50, y=1, width=2, height=1},
        {class="dropdown", name="blur_placement", items=blur_placement_config, value=blur_placement_config[1], x=0, y=1, width=50, height=1},
        
        -- Start From Option
        {class="label", label=":البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_blur", text="0", x=0, y=3, width=50, height=1},
        
        -- End From Option
        {class="label", label=":النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_blur", text="0", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Get the blur placement setting from the dialog
        local blur_placement = res.blur_placement

        -- Get the start and end blur values from the dialog
        local start_blur = tonumber(res.start_blur)
        local end_blur = tonumber(res.end_blur)

        -- Calculate the number of lines and the blur step
        local num_lines = #selected_lines
        local blur_step = (start_blur - end_blur) / (num_lines - 1)

        -- Print Selected Lines
        --aegisub.debug.out("Selected Lines:\n")
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            --aegisub.debug.out(line.text .. "\n")
        end

        -- Iterate over the selected lines
        for idx, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Calculate the blur value for this line and round it to 2 decimal places
            local current_blur = start_blur - (blur_step * (idx - 1))
            current_blur = string.format("%.2f", current_blur) -- Round to 2 decimal places

            -- Add the blur to the line
            line.text = add_blur_to_line(line.text, current_blur, blur_placement)

            -- Update the subtitle line with the new text
            subtitles[i] = line
        end

        -- Print The Selected Lines After Adding blur
        --aegisub.debug.out("\nResult:\n")
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            --aegisub.debug.out(line.text .. "\n")
        end
    end
end

function add_blur_to_line(text, blur_value, blur_placement)
    -- Check if the line has a "{}" block
    local has_code_block = text:match("{[^}]*}")

    if has_code_block then
        -- If the line has a "{}" block add the blur to it
        local start_idx, end_idx = text:find("{[^}]*}")

        if start_idx and end_idx then
            local block = text:sub(start_idx, end_idx)

            -- Add the blur to the block based on the placement setting
            if blur_placement == "Start" then
                -- Insert \blur at the start of the block after the opening "{"
                block = block:gsub("{", "{\\blur" .. blur_value, 1)
            else
                -- Insert \blur at the end of the block before the closing "}"
                block = block:gsub("}", "\\blur" .. blur_value .. "}", 1)
            end

            -- Replace the original block with the updated block
            text = text:sub(1, start_idx - 1) .. block .. text:sub(end_idx + 1)
        end
    else
        -- If the line has no "{}" block add a new "{}" block with the blur
        text = "{\\blur" .. blur_value .. "}" .. text
    end

    -- Return the updated text
    return text
end

-- Function to convert time string (0:00:00.00) to milliseconds
function time_to_ms(time_str)
    local h, m, s, ms = time_str:match("(%d+):(%d+):(%d+).(%d+)")
    return (tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)) * 1000 + tonumber(ms)
end

-- Function to convert milliseconds to time string (0:00:00.00)
function ms_to_time(ms)
    local h = math.floor(ms / 3600000)
    ms = ms % 3600000
    local m = math.floor(ms / 60000)
    ms = ms % 60000
    local s = math.floor(ms / 1000)
    ms = ms % 1000
    return string.format("%01d:%02d:%02d.%03d", h, m, s, ms)
end

-- Function to Shift Times based on the vplayer current time
function shift_times(subtitles, selected_lines, active_line)
    -- Get the player's current time
    local player_time = aegisub.ms_from_frame(aegisub.project_properties().video_position)

    -- Get the start time of the first selected line
    local first_line = subtitles[selected_lines[1]]
    local first_line_start = first_line.start_time

    -- Debug: Print the first line's start time and player time
    aegisub.debug.out(string.format("First Line Start Time: %s\n", ms_to_time(first_line_start)))
    aegisub.debug.out(string.format("Player Time: %s\n", ms_to_time(player_time)))

    -- Shift Times Config (default to False)
    local edit_times_config = {"True", "False"}
	
	-- Dialogs
    local dialog = {
        -- Shift Times Option
        {class="label", label=":تعديل التوقيت", x=50, y=1, width=2, height=1},
        {class="dropdown", name="edit_times", items=edit_times_config, value=edit_times_config[2], x=0, y=1, width=50, height=1},
        
        -- Add Time Option
        {class="label", label=":تقديم التوقيت للأمام", x=50, y=3, width=1, height=1},
        {class="edit", name="add_time", text="0:00:00.000", x=0, y=3, width=50, height=1},
        
        -- Subtract Time Option
        {class="label", label=":تأخير التوقيت للوراء", x=50, y=4, width=1, height=1},
        {class="edit", name="subtract_time", text="0:00:00.000", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Calculate the shift value
        local shift_value = player_time - first_line_start

        -- Debug: Print the calculated shift value
        aegisub.debug.out(string.format("Shift Value: %s\n", ms_to_time(shift_value)))

        -- Initialize add_time and subtract_time
        local add_time = 0
        local subtract_time = 0

        -- Check if additional time adjustments are needed
        if res.edit_times == "True" then
            add_time = time_to_ms(res.add_time)
            subtract_time = time_to_ms(res.subtract_time)

            -- Validate input: Only one of add_time or subtract_time can be non-zero
            if add_time ~= 0 and subtract_time ~= 0 then
                aegisub.debug.out("Error: Please use only one of the options (add_time or subtract_time), not both.\n")
                return
            end

            -- If both add_time and subtract_time are 0, skip additional adjustments
            if add_time == 0 and subtract_time == 0 then
                aegisub.debug.out("No additional time adjustments applied (both add_time and subtract_time are 0).\n")
            else
                -- Apply additional time adjustments directly to the start time
                if add_time > 0 then
                    aegisub.debug.out(string.format("Adding %s to the start time.\n", ms_to_time(add_time)))
                elseif subtract_time > 0 then
                    aegisub.debug.out(string.format("Subtracting %s from the start time.\n", ms_to_time(subtract_time)))
                end
            end
        end

        -- Iterate over the selected lines and adjust their times
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Apply additional time adjustments directly to the start time
            if res.edit_times == "True" then
                if add_time > 0 then
                    line.start_time = line.start_time + add_time
                elseif subtract_time > 0 then
                    line.start_time = line.start_time - subtract_time
                end
            end

            -- Apply the shift value
            line.start_time = line.start_time + shift_value
            line.end_time = line.end_time + shift_value

            subtitles[i] = line

            -- Print the edited time if additional adjustments were made
            if res.edit_times == "True" and (add_time > 0 or subtract_time > 0) then
                --aegisub.debug.out(string.format("Edited Start Time: %s\n", ms_to_time(line.start_time)))
            end
        end

        -- Print the shifted start time and edited start time for the first line
        local first_line_shifted_start = first_line_start + shift_value
        aegisub.debug.out(string.format("Shifted Start Time (First Line): %s\n", ms_to_time(first_line_shifted_start)))

        if res.edit_times == "True" and (add_time > 0 or subtract_time > 0) then
            local first_line_edited_start = first_line_shifted_start + (add_time > 0 and add_time or -subtract_time)
            aegisub.debug.out(string.format("Edited Start Time (First Line): %s\n", ms_to_time(first_line_edited_start)))
        end

        -- Print a confirmation message
        aegisub.debug.out("Retiming completed successfully.\n")
    end
end

-- Function to edit the start/end timing of selected lines
function edit_times(subtitles, selected_lines, active_line)
    local edit_times_config = {"للأمام", "للخلف"}
    
    local dialog = {
        -- Shift Times Direction (Increase/Decrease)
        {class="label", label=":اتجاه التعديل", x=50, y=1, width=2, height=1},
        {class="dropdown", name="edit_direction", items=edit_times_config, value=edit_times_config[1], x=0, y=1, width=50, height=1},
        
        -- Start Time Input
        {class="label", label=":وقت البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_time", text="0:00:00.000", x=0, y=3, width=50, height=1},
        
        -- End Time Input
        {class="label", label=":وقت النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_time", text="0:00:00.000", x=0, y=4, width=50, height=1},
    }

    -- Show the dialog
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    if pressed == "تطبيق" then
        -- Convert input times to milliseconds
        local start_ms = time_to_ms(res.start_time)
        local end_ms = time_to_ms(res.end_time)
        local direction = res.edit_direction

        -- Iterate over selected lines
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            
            -- Process START TIME
            if start_ms ~= 0 then
                if res.start_time:match("^0:00:00%.%d+$") then
                    -- Relative adjustment (NOW CORRECTED)
                    if direction == "للأمام" then
                        line.start_time = line.start_time + start_ms  -- Increase time
                    else
                        line.start_time = line.start_time - start_ms  -- Decrease time
                    end
                else
                    -- Absolute timing (set exact value)
                    line.start_time = start_ms
                end
            end
            
            -- Process END TIME
            if end_ms ~= 0 then
                if res.end_time:match("^0:00:00%.%d+$") then
                    -- Relative adjustment (NOW CORRECTED)
                    if direction == "للأمام" then
                        line.end_time = line.end_time + end_ms  -- Increase time
                    else
                        line.end_time = line.end_time - end_ms  -- Decrease time
                    end
                else
                    -- Absolute timing (set exact value)
                    line.end_time = end_ms
                end
            end
            
            subtitles[i] = line
        end

        aegisub.set_undo_point("تم تعديل توقيت الأسطر المحددة")
        aegisub.debug.out("تم التعديل بنجاح!\n")
    end
end

-- أداة نسخ ولصق الكليب
local clipboard_clips = {}

-- Extract the clip or iclip tag from a line
function extract_clip_tag(text)
    return text:match("\\i?clip%([^%)]+%)")
end

-- Remove the clip or iclip tag from a line
function remove_clip_tag(text)
    return text:gsub("\\i?clip%([^%)]+%)", "")
end

-- Copy the clip or iclip tag from selected lines
function copy_clip(subs, sel)
    -- Clear previous clipboard clips
    clipboard_clips = {}

    for _, i in ipairs(sel) do
        local line = subs[i]
        local clip_tag = extract_clip_tag(line.text)
        if clip_tag then
            table.insert(clipboard_clips, clip_tag)
        end
    end
    aegisub.debug.out(string.format("Copied %d clip tags\n", #clipboard_clips))
end

-- Paste the clip or iclip tag at the end of the formatting tag in the selected lines
function paste_clip(subs, sel)
    if #clipboard_clips == 0 then
        aegisub.debug.out("No clip tags copied!!!\n")
        return
    end

    local clip_index = 1
    for _, i in ipairs(sel) do
        local line = subs[i]
        local clip_tag = clipboard_clips[clip_index]
        line.text = remove_clip_tag(line.text)  -- Remove any existing clip or iclip tag
        
        -- Check if the line has a tag {} and if so append the clip tag inside the tag
        local start_idx, end_idx = line.text:find("{[^}]*}")
        if start_idx and end_idx then
            -- Insert the clip tag before the closing brace
            line.text = line.text:sub(1, end_idx - 1) .. clip_tag .. line.text:sub(end_idx)
        else
            -- If no tag exists, create one with the clip tag
            line.text = "{" .. clip_tag .. "}" .. line.text
        end
        
        subs[i] = line
        -- Loop through copied clips if fewer than selected lines
        clip_index = clip_index % #clipboard_clips + 1
    end
    aegisub.debug.out(string.format("Pasted clip tags to %d lines\n", #sel))
end

-- Copy & Paste Clip dialog pop-up
function copy_paste_clip(subs, sel)
    local buttons = {"نسخ", "لصق", "إلغاء"}
    local config = {
        {class="label", label="يمكنك نسخ الكليب من تترات متعددة ولصقها في تترات أخرى، لكن يجب أن يكون عدد التترات نفسه", x=0, y=0, width=2, height=1},
    }
    local pressed, _ = aegisub.dialog.display(config, buttons)
    
    if pressed == "نسخ" then
        copy_clip(subs, sel)
    elseif pressed == "لصق" then
        paste_clip(subs, sel)
    end
end

aegisub.register_macro(": أدوات :/17 - حساب نسبة التقدم", "حساب نسبة التقدم :", calculate_progress)
aegisub.register_macro(": أدوات :/16 - تعديل توقيت", "تعديل التوقيت :", edit_times)
aegisub.register_macro(": أدوات :/15 - تحريك التوقيت", "تحريك التوقيت :", shift_times)
aegisub.register_macro(": أدوات :/14 - إضافة بلر للتترات", "إضافة بلر للتترات :", add_blur_to_selected_lines)
aegisub.register_macro(": أدوات :/13 - حذف ما بين الكلمات", "حذف ما بين الكلمات :", remove_text_between_characters)
aegisub.register_macro(": أدوات :/12 - أداة الحذف", "أداة الحذف :", remove_tool)
aegisub.register_macro(": أدوات :/11 - تقسيم السطر إلى فريمات", "تقسيم السطر إلى فريمات :", split_line_to_frames)
aegisub.register_macro(": أدوات :/10 - نسخ ولصق الكليب", "نسخ ولصق الكليب :", copy_paste_clip)
aegisub.register_macro(": أدوات :/09 - تغيير موضع الكليب", "تغيير موضع الكليب :", adjust_clips)
aegisub.register_macro(": أدوات :/08 - تغيير اتجاه النص", "تغيير اتجاه النص :", reverse_text_direction)
aegisub.register_macro(": أدوات :/07 - تصحيح نقاط آخر السطر", "تصحيح نقاط آخر السطر :", fix_punctuation_unicode)
aegisub.register_macro(": أدوات :/06 - تصحيح موضع العلامات والنقاط", "تصحيح موضع العلامات والنقاط :", fix_punctuation)
aegisub.register_macro(": أدوات :/05 - أداة فحص الأخطاء", "أداة فحص الأخطاء :", spellchecker)
aegisub.register_macro(": أدوات :/04 - تغيير شكل الكلمات العربية", "تغيير شكل الكلمات العربية :", add_ar_reshape_to_words)
aegisub.register_macro(": أدوات :/03 - ترجمة متعددة", "ترجمة متعددة :", translate_with_external_script)
aegisub.register_macro(": أدوات :/02 - المُشكل", "المُشكل :", correct_words)
aegisub.register_macro(": أدوات :/01 - تعديل النصوص", "تعديل النصوص :", edit_selected_text)