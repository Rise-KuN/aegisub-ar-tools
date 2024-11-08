script_name = "حذف تقسيم السطر"
script_description = "حذف تقسيم السطر"
script_author = "Rise-KuN"
script_version = "1.0.0"

function remove_punctuation(subtitles, selected_lines, active_line)
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

aegisub.register_macro(script_name, script_description, remove_punctuation)