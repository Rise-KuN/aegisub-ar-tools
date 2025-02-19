script_name = "Add Blur To Selected Lines"
script_description = "Add Blur To Selected Lines Based On Number"
script_author = "Rise-KuN"
script_version = "1.0.0"

-- إضافة بلر للتترات
function add_blur_to_selected_lines(subtitles, selected_lines, active_line)
    -- Blur Placment Config
    local blur_placement_config = {"Start", "End"}
	
	-- Dialogs
    local dialog = {
        -- Blur Placement Option
        {class="label", label=":مكان البلر", x=50, y=1, width=2, height=1},
        {class="dropdown", name="blur_placement", items=blur_placement_config, value=blur_placement_config[1], x=0, y=1, width=50, height=1},
        
        -- Start From Option
        {class="label", label=":البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_blur", text="0", x=0, y=3, width=50, height=1},
        
        -- End From Option
        {class="label", label=":النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_blur", text="0", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Get the blur placement setting from the dialog
        local blur_placement = res.blur_placement

        -- Get the start and end blur values from the dialog
        local start_blur = tonumber(res.start_blur)
        local end_blur = tonumber(res.end_blur)

        -- Calculate the number of lines and the blur step
        local num_lines = #selected_lines
        local blur_step = (start_blur - end_blur) / (num_lines - 1)

        -- Print Selected Lines
        --aegisub.debug.out("Selected Lines:\n")
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            --aegisub.debug.out(line.text .. "\n")
        end

        -- Iterate over the selected lines
        for idx, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Calculate the blur value for this line and round it to 2 decimal places
            local current_blur = start_blur - (blur_step * (idx - 1))
            current_blur = string.format("%.2f", current_blur) -- Round to 2 decimal places

            -- Add the blur to the line
            line.text = add_blur_to_line(line.text, current_blur, blur_placement)

            -- Update the subtitle line with the new text
            subtitles[i] = line
        end

        -- Print The Selected Lines After Adding blur
        --aegisub.debug.out("\nResult:\n")
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            --aegisub.debug.out(line.text .. "\n")
        end
    end
end

function add_blur_to_line(text, blur_value, blur_placement)
    -- Check if the line has a "{}" block
    local has_code_block = text:match("{[^}]*}")

    if has_code_block then
        -- If the line has a "{}" block add the blur to it
        local start_idx, end_idx = text:find("{[^}]*}")

        if start_idx and end_idx then
            local block = text:sub(start_idx, end_idx)

            -- Add the blur to the block based on the placement setting
            if blur_placement == "Start" then
                -- Insert \blur at the start of the block after the opening "{"
                block = block:gsub("{", "{\\blur" .. blur_value, 1)
            else
                -- Insert \blur at the end of the block before the closing "}"
                block = block:gsub("}", "\\blur" .. blur_value .. "}", 1)
            end

            -- Replace the original block with the updated block
            text = text:sub(1, start_idx - 1) .. block .. text:sub(end_idx + 1)
        end
    else
        -- If the line has no "{}" block add a new "{}" block with the blur
        text = "{\\blur" .. blur_value .. "}" .. text
    end

    -- Return the updated text
    return text
end

aegisub.register_macro(script_name, script_description, add_blur_to_selected_lines)