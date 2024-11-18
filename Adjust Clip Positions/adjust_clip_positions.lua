script_name = "Adjust Clip Positions"
script_description = "Adjust clip positions for RTL or LTR, supporting \\clip and \\iclip."
script_author = "Rise-KuN"
script_version = "1.1.0"

-- Parse clip coordinates into a table
function parse_clip_coordinates(clip_tag)
    local coords = {}
    for num in clip_tag:gmatch("[%-]?%d+%.?%d*") do
        table.insert(coords, tonumber(num))
    end
    return coords
end

-- RTL adjustment function
function calculate_rtl_clip(first_clip_coords, second_clip_coords)
    local first_clip_width = first_clip_coords[3] - first_clip_coords[1]
    local new_first_clip = {
        second_clip_coords[3] - first_clip_width,
        first_clip_coords[2],
        second_clip_coords[3],
        first_clip_coords[4]
    }
    local new_second_clip = {
        second_clip_coords[1] - first_clip_width,
        second_clip_coords[2],
        second_clip_coords[3],
        second_clip_coords[4]
    }
    return new_first_clip, new_second_clip
end

-- LTR adjustment function
function calculate_ltr_clip(first_clip_coords, second_clip_coords)
    local first_clip_width = first_clip_coords[3] - first_clip_coords[1]
    local new_first_clip = {
        second_clip_coords[1],
        first_clip_coords[2],
        second_clip_coords[1] + first_clip_width,
        first_clip_coords[4]
    }
    local new_second_clip = {
        second_clip_coords[1] + first_clip_width,
        second_clip_coords[2],
        second_clip_coords[3],
        second_clip_coords[4]
    }
    return new_first_clip, new_second_clip
end

-- Create clip tag string from coordinates
function create_clip_tag(coords, is_iclip)
    local tag_type = is_iclip and "\\iclip" or "\\clip"
    return tag_type .. "(" .. table.concat(coords, ",") .. ")"
end

-- Adjust clip positions in the line
function adjust_clip_positions(subtitles, line_index, direction)
    local line = subtitles[line_index]
    -- Find the first and second clip tags (clip or iclip)
    local first_clip_start, first_clip_end = line.text:find("\\[i]?clip%b()")
    local second_clip_start, second_clip_end = line.text:find("\\[i]?clip%b()", first_clip_end + 1)

    if first_clip_start and second_clip_start then
        -- Determine if it's an iclip
        local is_iclip = line.text:sub(first_clip_start, first_clip_start + 5) == "\\iclip"

        local first_clip = line.text:sub(first_clip_start, first_clip_end)
        local second_clip = line.text:sub(second_clip_start, second_clip_end)
        local first_clip_coords = parse_clip_coordinates(first_clip)
        local second_clip_coords = parse_clip_coordinates(second_clip)

        local new_first_clip_coords, new_second_clip_coords
        if direction == "RTL" then
            new_first_clip_coords, new_second_clip_coords = calculate_rtl_clip(first_clip_coords, second_clip_coords)
        elseif direction == "LTR" then
            new_first_clip_coords, new_second_clip_coords = calculate_ltr_clip(first_clip_coords, second_clip_coords)
        end

        local new_first_clip = create_clip_tag(new_first_clip_coords, is_iclip)
        local new_second_clip = create_clip_tag(new_second_clip_coords, is_iclip)

        line.text = line.text:sub(1, first_clip_start - 1) ..
                    new_first_clip ..
                    line.text:sub(first_clip_end + 1, second_clip_start - 1) ..
                    new_second_clip ..
                    line.text:sub(second_clip_end + 1)
        subtitles[line_index] = line

        -- aegisub.debug.out("Adjusted clips (" .. direction .. "):\n" .. new_first_clip .. "\n" .. new_second_clip .. "\n")
    else
        aegisub.debug.out("Couldn't find the required clip tags.\n")
    end
end

-- Process selected lines
function adjust_clips(subtitles, selected_lines, active_line)
    -- Dropdown dialog
    local clip_choices = {"RTL", "LTR"}
    local dialog = {
        {class="label", label=":اتجاه الكليب", x=1, y=0, width=2, height=1},
        {class="dropdown", name="clip", items=clip_choices, value=clip_choices[1], x=0, y=0, width=1, height=1}
    }
    local button, result = aegisub.dialog.display(dialog, {"اختيار", "إلغاء"})
    if button ~= "اختيار" then return end

    local selected_direction = result.clip

    for _, i in ipairs(selected_lines) do
        adjust_clip_positions(subtitles, i, selected_direction)
    end

    -- aegisub.set_undo_point("Adjust Clip Positions (" .. selected_direction .. ")")
end

aegisub.register_macro(script_name, script_description, adjust_clips)