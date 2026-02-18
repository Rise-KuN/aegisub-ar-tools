script_name = "تصحيح موضع العلامات والنقاط"
script_description = "Fix Punctuation For RTL languages"
script_author = "Rise-KuN"
script_version = "2.0.3"

-- تصحيح موضع العلامات والنقاط
function fix_punctuation(subtitles, selected_lines, active_line)
    -- Punctuation marks List
    local punctuation = {
        "!", ":", "؛", "،", "%.", "%.%.%.", "%-", "%_", "%$", "%@", "«", "»", '"', "%[", "%]"
    }

    local pattern = "([،؛:!%.%-%_%$%@%[%]\"«»]+)(%s*)$"

    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        local original_text = line.text
        local text = original_text
        local punctuation_count = 0

        -- Create a list to store parts of the line (text and tags)
        local parts = {}
        local tag_parts = {}

        -- Split the line into text and tags preserving the structure
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
                        local non_tag = text:sub(i, next_tag - 1)
                        table.insert(parts, non_tag)
                        i = next_tag
                    else
                        local non_tag = text:sub(i)
                        table.insert(parts, non_tag)
                        break
                    end
                end
            end
        end
        split_text_and_tags(text)

        -- Remove spaces between \N
        local function clean_up_n_space(parts)
            for i, part in ipairs(parts) do
                -- Remove leading and trailing spaces around \N
                parts[i] = part:gsub("%s*\\N%s*", "\\N")
            end
        end
        clean_up_n_space(parts)

        -- Handle the text parts
        local function process_with_punctuation(parts)
            -- Split the text to parts based on \N
            local segments = {}

            for _, part in ipairs(parts) do
                -- Only process the part if its not a tag
                if not part:match("^{.*}$") then

                    -- Split by literal \N safely (DO NOT USE gmatch "[^\\N]+")
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

                    -- Process each sub_part and move punctuations from the end to the start
                    for i = 1, #sub_parts do
                        local sub_part = sub_parts[i]

                        -- Skip the \N separator itself
                        if sub_part ~= "\\N" then
                            local punc_at_end = sub_part:match(pattern)
                            if punc_at_end then
                                punctuation_count = punctuation_count + 1

                                local cleaned = sub_part:gsub(pattern, "")
                                -- Safety: never allow full deletion
                                if cleaned ~= "" then
                                    sub_part = punc_at_end .. cleaned
                                end

                                sub_parts[i] = sub_part
                            end
                        end
                    end

                    -- Rejoin the sub_parts and add the processed segment
                    local new_segment = table.concat(sub_parts)
                    table.insert(segments, new_segment)
                else
                    -- If it's a tag add it without modification
                    table.insert(segments, part)
                end
            end

            return segments
        end

        -- Process punctuation handling
        parts = process_with_punctuation(parts)

        -- Rebuild the text from the processed parts
        text = table.concat(parts)

        -- Debugging
        --aegisub.debug.out("Line: " .. line_index .. "\n")
        --aegisub.debug.out("Original Text: " .. original_text .. "\n")
        --aegisub.debug.out("Modified Text: " .. text .. "\n")
        --aegisub.debug.out("Punctuation Detected: " .. punctuation_count .. "\n\n")

        -- Update the line text
        line.text = text
        subtitles[line_index] = line
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, fix_punctuation)
