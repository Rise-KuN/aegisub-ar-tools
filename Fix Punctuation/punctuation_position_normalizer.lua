script_name = "Punctuation Position Normalizer"
script_description = "Normalizes punctuation placement from line start to line end"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- Punctuation Position Normalizer
local normalizer_punctuation = {
    ["."] = true,
    ["،"] = true,
    ["؛"] = true,
    ["..."] = true,
    ["!"] = true,
    [":"] = true,
    [']'] = true,
    ['['] = true,
    ['('] = true,
    [')'] = true,
    ['«'] = true,
    ['»'] = true,
    ['-'] = true,
    ['"'] = true,
    ["—"] = true
}

-- UTF-8 safe character splitter
local function normalizer_utf8_chars(str)
    local chars = {}
    local i = 1

    while i <= #str do
        local c = str:byte(i)
        local len = 1

        if c >= 0xF0 then
            len = 4
        elseif c >= 0xE0 then
            len = 3
        elseif c >= 0xC0 then
            len = 2
        end

        table.insert(chars, str:sub(i, i + len - 1))
        i = i + len
    end

    return chars
end

-- Move punctuation from start to end
local function fix_line(text)
    local chars = normalizer_utf8_chars(text)

    local collected = {}
    local start_index = 1

    -- Collect punctuation from the beginning
    while start_index <= #chars and normalizer_punctuation[chars[start_index]] do
        table.insert(collected, chars[start_index])
        start_index = start_index + 1
    end

    -- Nothing to fix
    if #collected == 0 then
        return text
    end

    -- Remaining text
    local remaining = {}
    for i = start_index, #chars do
        table.insert(remaining, chars[i])
    end

    -- Build final line
    return table.concat(remaining) .. table.concat(collected)
end

function normalizer_punctuation_position(subtitles, selected_lines, active_line)

    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]

        -- Split by \N safely
        local parts = {}
        local start = 1

        while true do
            local s, e = line.text:find("\\N", start, true)

            if not s then
                table.insert(parts, line.text:sub(start))
                break
            end

            table.insert(parts, line.text:sub(start, s - 1))
            table.insert(parts, "\\N")
            start = e + 1
        end

        -- Process only text parts
        for j = 1, #parts do
            if parts[j] ~= "\\N" then
                parts[j] = fix_line(parts[j])
            end
        end

        line.text = table.concat(parts)
        subtitles[i] = line
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, normalizer_punctuation_position)