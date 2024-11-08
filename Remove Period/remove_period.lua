script_name = "حذف النقاط"
script_description = "حذف النقاط"
script_author = "Rise-KuN"
script_version = "1.4.0"

function remove_punctuation(subtitles, selected_lines, active_line)
    local count = 0 -- Counter For Changed Words
    local hasChanges = false -- Check If Any Changes Were Made

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local text = line.text

        -- Check if the line is in English
        if text:match("[a-zA-Z]") then
            -- Check if the line has "." before "\N"
            local new_text, changes = text:gsub("%.%s*(\\N)", "%1")
            if changes > 0 then
                count = count + changes
                hasChanges = true
            end

            -- Check if the line ends with "." not "..."
            if new_text:sub(-1) == "." and new_text:sub(-3) ~= "..." then
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
            if text:find("%.$") and not text:find("%.%.+") then
                -- Remove "." only if it's at the end of the line
                text = text:gsub("%.$", "")
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

aegisub.register_macro(script_name, script_description, remove_punctuation)