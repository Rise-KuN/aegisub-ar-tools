script_name = "Remove STR Tool"
script_description = "أداة حذف نقاط آخر السطر وتقسيم السطر وعلامة التعجب"
script_author = "Rise-KuN"
script_version = "1.0.3"

-- 'أداة حذف 'نقاط آخر السطر' 'تقسيم السطر' علامة التعجب
-- Remove Periods for Arabic and English
function remove_periods(subtitles, selected_lines)
    local count = 0
    
    -- Helper function to extract leading and trailing tags
    local function extract_tags(segment)
        local leading_tags = ""
        local trailing_tags = ""
        
        -- Extract leading tags {.*}
        segment = segment:gsub("^({.-})", function(tag)
            leading_tags = tag
            return ""
        end)
        
        -- Extract trailing tags {.*}
        segment = segment:gsub("({.-})$", function(tag)
            trailing_tags = tag
            return ""
        end)
        
        return segment, leading_tags, trailing_tags
    end
    
    -- Helper function to remove periods from a segment
    local function remove_periods_from_segment(segment)
        -- Extract tags first
        local text, leading_tags, trailing_tags = extract_tags(segment)
        
        -- Temporarily replace "..." with a placeholder to preserve ellipsis
        text = text:gsub("%.%.%.", "___ELLIPSIS___")
        
        -- Remove only leading periods
        text = text:gsub("^%.", "")
        -- Remove only trailing periods
        text = text:gsub("%.$", "")
        
        -- Restore ellipsis
        text = text:gsub("___ELLIPSIS___", "...")
        
        return leading_tags .. text .. trailing_tags
    end
    
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
        
        -- Split by \N and process each segment
        local segments = {}
        local rest = text
        while rest ~= "" do
            local pos = rest:find("\\N")
            if pos then
                table.insert(segments, rest:sub(1, pos - 1))
                rest = rest:sub(pos + 2)
            else
                table.insert(segments, rest)
                rest = ""
            end
        end
        
        -- Process based on text type
        if text:match("[a-zA-Z]") then
            -- English text: remove all periods from each segment
            for i = 1, #segments do
                segments[i] = remove_periods_from_segment(segments[i])
            end
        elseif arabic_special_period > 0 then
            -- Special Arabic periods (with RTL markers)
            for i = 1, #segments do
                local segment = segments[i]
                local text, leading_tags, trailing_tags = extract_tags(segment)
                
                text = text:gsub("%.%.%.", "___ELLIPSIS___")
                text = text:gsub("^‏%.‏", "")
                text = text:gsub("‏%.‏$", "")
                text = text:gsub("‏%.‏", "")
                text = text:gsub("___ELLIPSIS___", "...")
                
                segments[i] = leading_tags .. text .. trailing_tags
            end
        else
            -- Standard Arabic periods
            for i = 1, #segments do
                segments[i] = remove_periods_from_segment(segments[i])
            end
        end
        
        -- Rejoin segments with \N
        local new_text = table.concat(segments, "\\N")
        
        -- Check if the text was modified
        if line.text ~= new_text then
            line.text = new_text
            subtitles[line_index] = line
            count = count + 1
        end
    end
    aegisub.debug.out("تمَّ تعديل " .. count .. " أسطر\n\n")
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
    aegisub.debug.out("تمَّ حذف " .. count .. " تقسيم السطر\n\n")
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
    aegisub.debug.out("تمَّ حذف " .. count .. " علامة التعجب\n\n")
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
