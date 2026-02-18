script_name = "تصحيح موضع العلامات والنقاط"
script_description = "Fix Punctuation For RTL languages"
script_author = "Rise-KuN"
script_version = "2.0.4"

-- تصحيح موضع العلامات والنقاط
function fix_punctuation(subtitles, selected_lines, active_line)

    -- Punctuation characters allowed to move
    local punctuation_chars = {
        ["!"] = true,
        ["."] = true,
        [":"] = true,
        ["؛"] = true,
        ["،"] = true,
        ["-"] = true,
        ["_"] = true,
        ["$"] = true,
        ["@"] = true,
        ["«"] = true,
        ["»"] = true,
        ['"'] = true,
        ["["] = true,
        ["]"] = true,
    }

    -- UTF-8 safe function to split a string into characters
    local function utf8_chars(str)
        local chars = {}
        local i = 1
        local len = #str
        while i <= len do
            local c = str:byte(i)
            local char_len = 1
            if c >= 0xF0 then
                char_len = 4
            elseif c >= 0xE0 then
                char_len = 3
            elseif c >= 0xC0 then
                char_len = 2
            end
            table.insert(chars, str:sub(i, i+char_len-1))
            i = i + char_len
        end
        return chars
    end

    -- Move trailing punctuation safely (UTF-8 aware)
    local function move_punctuation_utf8(segment, punctuation_count_ref)
        if segment == "" then return segment end

        local chars = utf8_chars(segment)
        local collected = {}

        -- Walk backwards through real UTF-8 characters
        for i = #chars, 1, -1 do
            local ch = chars[i]

            if punctuation_chars[ch] then
                table.insert(collected, 1, ch)
                table.remove(chars, i)
                punctuation_count_ref.count = punctuation_count_ref.count + 1
            else
                break
            end
        end

        if #collected > 0 then
            return table.concat(collected) .. table.concat(chars)
        end

        return segment
    end

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local original_text = line.text
        local text = original_text

        local punctuation_count_ref = { count = 0 }
        local parts = {}

        -- Split text and tags while preserving structure
        local function split_text_and_tags(text)
            local i = 1
            while i <= #text do
                local char = text:sub(i, i)

                if char == "{" then
                    local tag = text:match("{[^}]*}", i)
                    if tag then
                        table.insert(parts, tag)
                        i = i + #tag
                    else
                        table.insert(parts, char)
                        i = i + 1
                    end
                else
                    local next_tag = text:find("{", i, true)
                    if next_tag then
                        table.insert(parts, text:sub(i, next_tag - 1))
                        i = next_tag
                    else
                        table.insert(parts, text:sub(i))
                        break
                    end
                end
            end
        end
        split_text_and_tags(text)

        -- Remove spaces around \N
        for i, part in ipairs(parts) do
            parts[i] = part:gsub("%s*\\N%s*", "\\N")
        end

        -- Process parts safely
        for i, part in ipairs(parts) do
            -- Skip tags
            if not part:match("^{.*}$") then

                -- Split safely by literal \N
                local sub_parts = {}
                local start = 1

                while true do
                    local s, e = part:find("\\N", start, true)
                    if not s then
                        table.insert(sub_parts, part:sub(start))
                        break
                    end
                    table.insert(sub_parts, part:sub(start, s - 1))
                    table.insert(sub_parts, "\\N")
                    start = e + 1
                end

                -- Process each text segment
                for j = 1, #sub_parts do
                    if sub_parts[j] ~= "\\N" then
                        sub_parts[j] = move_punctuation_utf8(sub_parts[j], punctuation_count_ref)
                    end
                end

                parts[i] = table.concat(sub_parts)
            end
        end

        text = table.concat(parts)

        -- Debugging output
        --aegisub.debug.out("Line: " .. line_index .. "\n")
        --aegisub.debug.out("Original Text: " .. original_text .. "\n")
        --aegisub.debug.out("Modified Text: " .. text .. "\n")
        --aegisub.debug.out("Punctuation Detected: " .. punctuation_count_ref.count .. "\n\n")

        line.text = text
        subtitles[line_index] = line
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, fix_punctuation)
