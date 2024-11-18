script_name = "Reverse Characters Direction"
script_description = "Reverses the direction of characters while maintaining UTF-8 integrity"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- تغيير اتجاه الحروف
-- Load the unicode library
local unicode = require("unicode")

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

aegisub.register_macro(script_name, script_description, swap_characters)
