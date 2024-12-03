script_name = "Remove STR Tool"
script_description = "أداة حذف نقاط آخر السطر وتقسيم السطر وعلامة التعجب"
script_author = "Rise-KuN"
script_version = "1.0.2"

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

aegisub.register_macro(script_name, script_description, remove_tool)
