script_name = "Shift Times"
script_description = "Shift time of selected lines based on first line time then shift forward based on the video player current time."
script_author = "Rise-KuN"
script_version = "1.0.1"

-- Function to convert time string (0:00:00.00) to milliseconds
function time_to_ms(time_str)
    local h, m, s, ms = time_str:match("(%d+):(%d+):(%d+).(%d+)")
    return (tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s)) * 1000 + tonumber(ms)
end

-- Function to convert milliseconds to time string (0:00:00.00)
function ms_to_time(ms)
    local h = math.floor(ms / 3600000)
    ms = ms % 3600000
    local m = math.floor(ms / 60000)
    ms = ms % 60000
    local s = math.floor(ms / 1000)
    ms = ms % 1000
    return string.format("%01d:%02d:%02d.%03d", h, m, s, ms)
end

-- Function to Shift Times based on the vplayer current time
function shift_times(subtitles, selected_lines, active_line)
    -- Get the player's current time
    local player_time = aegisub.ms_from_frame(aegisub.project_properties().video_position)

    -- Get the start time of the first selected line
    local first_line = subtitles[selected_lines[1]]
    local first_line_start = first_line.start_time

    -- Debug: Print the first line's start time and player time
    aegisub.debug.out(string.format("First Line Start Time: %s\n", ms_to_time(first_line_start)))
    aegisub.debug.out(string.format("Player Time: %s\n", ms_to_time(player_time)))

    -- Shift Times Config (default to False)
    local edit_times_config = {"True", "False"}
	
	-- Dialogs
    local dialog = {
        -- Shift Times Option
        {class="label", label=":تعديل التوقيت", x=50, y=1, width=2, height=1},
        {class="dropdown", name="edit_times", items=edit_times_config, value=edit_times_config[2], x=0, y=1, width=50, height=1},
        
        -- Add Time Option
        {class="label", label=":تقديم التوقيت للأمام", x=50, y=3, width=1, height=1},
        {class="edit", name="add_time", text="0:00:00.000", x=0, y=3, width=50, height=1},
        
        -- Subtract Time Option
        {class="label", label=":تأخير التوقيت للوراء", x=50, y=4, width=1, height=1},
        {class="edit", name="subtract_time", text="0:00:00.000", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Calculate the shift value
        local shift_value = player_time - first_line_start

        -- Debug: Print the calculated shift value
        aegisub.debug.out(string.format("Shift Value: %s\n", ms_to_time(shift_value)))

        -- Initialize add_time and subtract_time
        local add_time = 0
        local subtract_time = 0

        -- Check if additional time adjustments are needed
        if res.edit_times == "True" then
            add_time = time_to_ms(res.add_time)
            subtract_time = time_to_ms(res.subtract_time)

            -- Validate input: Only one of add_time or subtract_time can be non-zero
            if add_time ~= 0 and subtract_time ~= 0 then
                aegisub.debug.out("Error: Please use only one of the options (add_time or subtract_time), not both.\n")
                return
            end

            -- If both add_time and subtract_time are 0, skip additional adjustments
            if add_time == 0 and subtract_time == 0 then
                aegisub.debug.out("No additional time adjustments applied (both add_time and subtract_time are 0).\n")
            else
                -- Apply additional time adjustments directly to the start time
                if add_time > 0 then
                    aegisub.debug.out(string.format("Adding %s to the start time.\n", ms_to_time(add_time)))
                elseif subtract_time > 0 then
                    aegisub.debug.out(string.format("Subtracting %s from the start time.\n", ms_to_time(subtract_time)))
                end
            end
        end

        -- Iterate over the selected lines and adjust their times
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Apply additional time adjustments directly to the start time
            if res.edit_times == "True" then
                if add_time > 0 then
                    line.start_time = line.start_time + add_time
                elseif subtract_time > 0 then
                    line.start_time = line.start_time - subtract_time
                end
            end

            -- Apply the shift value
            line.start_time = line.start_time + shift_value
            line.end_time = line.end_time + shift_value

            subtitles[i] = line

            -- Print the edited time if additional adjustments were made
            if res.edit_times == "True" and (add_time > 0 or subtract_time > 0) then
                --aegisub.debug.out(string.format("Edited Start Time: %s\n", ms_to_time(line.start_time)))
            end
        end

        -- Print the shifted start time and edited start time for the first line
        local first_line_shifted_start = first_line_start + shift_value
        aegisub.debug.out(string.format("Shifted Start Time (First Line): %s\n", ms_to_time(first_line_shifted_start)))

        if res.edit_times == "True" and (add_time > 0 or subtract_time > 0) then
            local first_line_edited_start = first_line_shifted_start + (add_time > 0 and add_time or -subtract_time)
            aegisub.debug.out(string.format("Edited Start Time (First Line): %s\n", ms_to_time(first_line_edited_start)))
        end

        -- Print a confirmation message
        aegisub.debug.out("Retiming completed successfully.\n")
    end
end

aegisub.register_macro(script_name, script_description, shift_times)