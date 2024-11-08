script_name = "Swap clip positions"
script_description = "Swap clip positions"
script_author = "Rise-KuN"
script_version = "1.0.2"

-- Function to swap the positions of \clip or \iclip tags
function swap_clip(subtitles, line_index)
    local line = subtitles[line_index]
    local first_clip_start, first_clip_end = line.text:find("\\[i]?clip%b()")
    local second_clip_start, second_clip_end = line.text:find("\\[i]?clip%b()", first_clip_end + 1)
    
    if first_clip_start and second_clip_start then
        local first_clip = line.text:sub(first_clip_start, first_clip_end)
        local second_clip = line.text:sub(second_clip_start, second_clip_end)
        
        -- Print the contents of first and second clip tags
        aegisub.debug.out("First: " .. first_clip .. "\n")
        aegisub.debug.out("Second: " .. second_clip .. "\n")
        
        local new_text = line.text:sub(1, first_clip_start - 1) ..
                         second_clip ..
                         line.text:sub(first_clip_end + 1, second_clip_start - 1) ..
                         first_clip ..
                         line.text:sub(second_clip_end + 1)
        
        -- Print the new text for debugging
        aegisub.debug.out("New Text: " .. new_text .. "\n")
        
        -- Update the line in the selected line
        line.text = new_text
        subtitles[line_index] = line
        
        aegisub.debug.out("Swapped clip tags.\n")
    else
        aegisub.debug.out("Couldn't find any clip tags.\n")
    end
end

-- Function to process selected lines
function swap_clip_positions(subtitles, selected_lines, active_line)
    for _, i in ipairs(selected_lines) do
        swap_clip(subtitles, i)
    end
    aegisub.set_undo_point("Swap clip positions")
end

-- Register the macro in Aegisub
aegisub.register_macro("Swap clip positions", "Swaps the positions of two \\clip or \\iclip tags", swap_clip_positions)