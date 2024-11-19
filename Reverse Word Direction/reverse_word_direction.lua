script_name = "Reverse Words Direction"
script_description = "Reverses the direction of words"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- تغيير اتجاه الكلمات
-- Load the unicode library
local unicode = require("unicode")

function reverse_words(text)
    local words = {}
    local word_start = 1
    -- Iterate through the text, finding word boundaries
    for i = 1, #text + 1 do
        local char = text:sub(i, i)
        if char == " " or i > #text then
            table.insert(words, text:sub(word_start, i - 1)) -- Add the word to the table
            word_start = i + 1 -- Move to the next word
        end
    end
    -- Reverse the order of words
    local reversed_words = {}
    for i = #words, 1, -1 do
        table.insert(reversed_words, words[i])
    end
    return table.concat(reversed_words, " ") -- Join the words back with a space
end

function swap_words(subtitles, selected_lines)
    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        line.text = reverse_words(line.text) -- Reverse the words
        subtitles[i] = line
    end
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, swap_words)

