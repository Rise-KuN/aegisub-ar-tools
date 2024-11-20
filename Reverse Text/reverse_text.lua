script_name = "Reverse Text Direction"
script_description = "Reverses the direction of characters or words"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- Load the unicode library
local unicode = require("unicode")

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

aegisub.register_macro(script_name, script_description, reverse_text_direction)