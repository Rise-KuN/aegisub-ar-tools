script_name = "Extract Tags"
script_description = "Extract style tags and inject them into selected lines based on their styles."
script_author = "Rise-KuN"
script_version = "1.0.0"

local clipboard = require "clipboard"

-- Function to convert color values to the format used in tags (e.g., &HBBGGRR&)
function color_to_tag_format(color_value)
    if type(color_value) == "string" and color_value ~= "" then
        -- Colors come in format &HAARRGGBB& where AA is alpha, RRGGBB is BGR
        -- Extract just the BGR part (last 6 hex digits)
        -- Remove the &H prefix and & suffix
        local clean = color_value:gsub("[&H]", ""):gsub("&$", "")
        
        if #clean >= 6 then
            -- Take the last 6 characters (BGR) to remove alpha
            local bgr = clean:sub(-6)
            return "&H" .. bgr .. "&"
        end
        return color_value
    elseif type(color_value) == "number" then
        -- If it's a number, convert to hex
        local hex_value = string.format("%08X", color_value)
        local bgr = hex_value:sub(-6)
        return "&H" .. bgr .. "&"
    end
    return "&H000000&"
end

-- Extract style properties and build override tags
function extract_style_tags(subtitles, style_name, extract_options)
    local style = nil
    
    -- Find the style in the subtitles
    for i = 1, #subtitles do
        if subtitles[i].class == "style" and subtitles[i].name == style_name then
            style = subtitles[i]
            break
        end
    end
    
    if not style then
        return ""
    end
    
    local tags = ""
    
    -- Extract font name
    if extract_options.font then
        tags = tags .. "\\fn" .. style.fontname
    end
    
    -- Extract font size
    if extract_options.size then
        tags = tags .. "\\fs" .. style.fontsize
    end
    
    -- Extract border
    if extract_options.bord then
        tags = tags .. "\\bord" .. style.outline
    end
    
    -- Extract shadow
    if extract_options.shad then
        tags = tags .. "\\shad" .. style.shadow
    end
    
    -- Extract color tags
    if extract_options.color then
        -- Handle color1 (primary color)
        local color_val = style.color1
        tags = tags .. "\\c" .. color_to_tag_format(color_val)
    end
    if extract_options.color2 then
        -- Handle color2 (secondary color)
        local color_val = style.color2
        tags = tags .. "\\2c" .. color_to_tag_format(color_val)
    end
    if extract_options.color3 then
        -- Handle color3 (outline color)
        local color_val = style.color3
        tags = tags .. "\\3c" .. color_to_tag_format(color_val)
    end
    if extract_options.color4 then
        -- Handle color4 (shadow color)
        local color_val = style.color4
        tags = tags .. "\\4c" .. color_to_tag_format(color_val)
    end
    
    return tags
end

-- Function to remove a tag by name from a tag string
function remove_tag(tag_string, tag_name)
    -- Handle special cases for color tags (c, 1c, 2c, 3c, 4c)
    if tag_name == "c" or tag_name == "1c" then
        -- Remove both \c and \1c (they're the same) - match \c&H...& or \1c&H...&
        tag_string = tag_string:gsub("\\1*c&H%x*&", "")
    elseif tag_name == "2c" or tag_name == "3c" or tag_name == "4c" then
        -- Remove color tag and its value
        tag_string = tag_string:gsub("\\" .. tag_name .. "&H%x*&", "")
    elseif tag_name == "pos" or tag_name == "move" or tag_name == "clip" or tag_name == "iclip" then
        -- Remove tags with parentheses content
        tag_string = tag_string:gsub("\\" .. tag_name .. "%([^)]*%)", "")
    else
        -- Remove regular tags (fn, fs, bord, shad)
        tag_string = tag_string:gsub("\\" .. tag_name .. "[^\\}]*", "")
    end
    return tag_string
end

-- Merge extracted tags with existing tags (new tags override old ones)
function merge_tags_into_block(existing_block_content, new_tags)
    local result = existing_block_content
    
    -- Remove old tags if they're being replaced
    if new_tags:match("\\c[^\\}]") then result = remove_tag(result, "c") end
    if new_tags:match("\\2c[^\\}]") then result = remove_tag(result, "2c") end
    if new_tags:match("\\3c[^\\}]") then result = remove_tag(result, "3c") end
    if new_tags:match("\\4c[^\\}]") then result = remove_tag(result, "4c") end
    if new_tags:match("\\bord[^\\}]") then result = remove_tag(result, "bord") end
    if new_tags:match("\\shad[^\\}]") then result = remove_tag(result, "shad") end
    if new_tags:match("\\fn[^\\}]") then result = remove_tag(result, "fn") end
    if new_tags:match("\\fs[^\\}]") then result = remove_tag(result, "fs") end
    
    -- Add new tags at the beginning
    return new_tags .. result
end

-- Function to inject tags into the first tag block of the text
function inject_tags_into_text(text, new_tags)
    -- Find the first tag block {...}
    local block_start, block_end = text:find("{[^}]*}")
    
    if block_start then
        -- Extract existing block content (without braces)
        local existing_content = text:sub(block_start + 1, block_end - 1)
        
        -- Merge new tags with existing content
        local merged = merge_tags_into_block(existing_content, new_tags)
        
        -- Replace the first block
        return text:sub(1, block_start - 1) .. "{" .. merged .. "}" .. text:sub(block_end + 1)
    else
        -- No existing tag block, create one at the beginning
        return "{" .. new_tags .. "}" .. text
    end
end

-- Build the GUI dialog
function show_extract_dialog()
    local dialog_items = {
        {class="label", label="Select tags to extract from styles:", x=0, y=0, width=40, height=1},
        {class="checkbox", name="color", label="\\c (Primary Color)", value=false, x=0, y=1, width=20, height=1},
        {class="checkbox", name="color2", label="\\2c (Secondary Color)", value=false, x=0, y=2, width=20, height=1},
        {class="checkbox", name="color3", label="\\3c (Outline Color)", value=false, x=0, y=3, width=20, height=1},
        {class="checkbox", name="color4", label="\\4c (Shadow Color)", value=false, x=0, y=4, width=20, height=1},
        {class="checkbox", name="bord", label="\\bord (Border)", value=false, x=20, y=1, width=20, height=1},
        {class="checkbox", name="shad", label="\\shad (Shadow)", value=false, x=20, y=2, width=20, height=1},
        {class="checkbox", name="font", label="\\fn (Font Name)", value=false, x=20, y=3, width=20, height=1},
        {class="checkbox", name="size", label="\\fs (Font Size)", value=false, x=20, y=4, width=20, height=1},
    }
    
    local buttons = {"Extract", "Cancel"}
    local button_pressed, options = aegisub.dialog.display(dialog_items, buttons)
    
    if button_pressed == "Extract" then
        return true, options
    end
    return false, nil
end

-- Main function
function extract_tags(subtitles, selected_lines)
    -- Show dialog to let user choose which tags to extract
    local should_extract, options = show_extract_dialog()
    
    if not should_extract then
        return
    end
    
    -- Process each selected line
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        
        -- Extract tags from this line's style
        local style_tags = extract_style_tags(subtitles, line.style, options)
        
        -- Inject tags into the text (merge with existing tags)
        if style_tags ~= "" then
            line.text = inject_tags_into_text(line.text, style_tags)
            subtitles[line_index] = line
        end
    end
    
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, extract_tags)