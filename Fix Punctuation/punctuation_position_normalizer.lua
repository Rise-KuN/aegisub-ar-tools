script_name = "Punctuation Position Normalizer"
script_description = "Normalizes punctuation placement from line start to line end"
script_author = "Rise-KuN"
script_version = "1.0.2"

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

local normalizer_enclosing_pairs = {
    ["("] = ")",
    ["["] = "]",
    ["«"] = "»",
    ["\""] = "\""
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

    -- Dialogue dashes and enclosing punctuation are not misplaced punctuation.
    if chars[1] == "-" then
        return text
    end

    if #chars > 1 and normalizer_enclosing_pairs[chars[1]] == chars[#chars] then
        return text
    end

    local trailing_dash = false
    if chars[#chars] == "-" then
        trailing_dash = true
        table.remove(chars)
        while chars[#chars] == " " or chars[#chars] == "\t" do
            table.remove(chars)
        end
    end

    local collected = {}
    local start_index = 1

    -- Collect punctuation from the beginning
    while start_index <= #chars and normalizer_punctuation[chars[start_index]] do
        table.insert(collected, chars[start_index])
        start_index = start_index + 1
    end

    -- Nothing to fix
    if #collected == 0 and not trailing_dash then
        return text
    end

    -- Remaining text
    local remaining = {}
    for i = start_index, #chars do
        table.insert(remaining, chars[i])
    end

    -- Build final line
    return (trailing_dash and "- " or "") .. table.concat(remaining) .. table.concat(collected)
end

function normalizer_punctuation_position(subtitles, selected_lines, active_line)

    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        local text = line.text
        local line_chars = normalizer_utf8_chars(text)
        local opening = ""
        local closing = ""

        if #line_chars > 1 and normalizer_enclosing_pairs[line_chars[1]] == line_chars[#line_chars] then
            opening = table.remove(line_chars, 1)
            closing = table.remove(line_chars)
            text = table.concat(line_chars)
        end

        -- Split by \N safely
        local parts = {}
        local start = 1

        while true do
            local s, e = text:find("\\N", start, true)

            if not s then
                table.insert(parts, text:sub(start))
                break
            end

            table.insert(parts, text:sub(start, s - 1))
            table.insert(parts, "\\N")
            start = e + 1
        end

        -- Process only text parts
        for j = 1, #parts do
            if parts[j] ~= "\\N" then
                parts[j] = fix_line(parts[j])
            end
        end

        line.text = opening .. table.concat(parts) .. closing
        subtitles[i] = line
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, normalizer_punctuation_position)
