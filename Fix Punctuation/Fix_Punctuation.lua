script_name = "تصحيح موضع العلامات والنقاط"
script_description = "Fix Punctuation For RTL languages"
script_author = "Rise-KuN"
script_version = "2.0.0"

-- تصحيح موضع العلامات والنقاط
function fix_punctuation(subtitles, selected_lines, active_line)
    -- Punctuation marks List
    local punctuation = {
        "!", ":", "؛", "،", "%.", "%.%.%.", "%-", "%_", "%$", "%@", "«", "»", '"', "%[", "%]"
    }
    
    local pattern = "([" .. table.concat(punctuation, "") .. "]+)(%s*)$"

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
                    end
                else
                    local non_tag = text:match("([^{]*)", i)
                    table.insert(parts, non_tag)
                    i = i + #non_tag
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
                    -- Split by \N to handle each segment separately
                    local sub_parts = {}
                    for sub_part in part:gmatch("[^\\N]+") do
                        table.insert(sub_parts, sub_part)
                    end

                    -- Process each sub_part and move punctuations from the end to the start
                    for i, sub_part in ipairs(sub_parts) do
                        local punc_at_end = sub_part:match(pattern)
                        if punc_at_end then
                            punctuation_count = punctuation_count + 1
                            sub_part = sub_part:gsub(pattern, "")
                            sub_part = punc_at_end .. sub_part
                            sub_parts[i] = sub_part
                        end
                    end

                    -- Rejoin the sub_parts and add the processed segment
                    local new_segment = table.concat(sub_parts, "\\N")
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
