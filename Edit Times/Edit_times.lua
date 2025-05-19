script_name = "Edit Times"
script_description = "Edit time of selected lines by Increase or Decrease the start/end times based on the input values."
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

-- Function to edit the start/end timing of selected lines
function edit_times(subtitles, selected_lines, active_line)
    local edit_times_config = {"للأمام", "للخلف"}
    
    local dialog = {
        -- Shift Times Direction (Increase/Decrease)
        {class="label", label=":اتجاه التعديل", x=50, y=1, width=2, height=1},
        {class="dropdown", name="edit_direction", items=edit_times_config, value=edit_times_config[1], x=0, y=1, width=50, height=1},
        
        -- Start Time Input
        {class="label", label=":وقت البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_time", text="0:00:00.000", x=0, y=3, width=50, height=1},
        
        -- End Time Input
        {class="label", label=":وقت النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_time", text="0:00:00.000", x=0, y=4, width=50, height=1},
    }

    -- Show the dialog
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    if pressed == "تطبيق" then
        -- Convert input times to milliseconds
        local start_ms = time_to_ms(res.start_time)
        local end_ms = time_to_ms(res.end_time)
        local direction = res.edit_direction

        -- Iterate over selected lines
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]
            
            -- Process START TIME
            if start_ms ~= 0 then
                if res.start_time:match("^0:00:00%.%d+$") then
                    -- Relative adjustment (NOW CORRECTED)
                    if direction == "للأمام" then
                        line.start_time = line.start_time + start_ms  -- Increase time
                    else
                        line.start_time = line.start_time - start_ms  -- Decrease time
                    end
                else
                    -- Absolute timing (set exact value)
                    line.start_time = start_ms
                end
            end
            
            -- Process END TIME
            if end_ms ~= 0 then
                if res.end_time:match("^0:00:00%.%d+$") then
                    -- Relative adjustment (NOW CORRECTED)
                    if direction == "للأمام" then
                        line.end_time = line.end_time + end_ms  -- Increase time
                    else
                        line.end_time = line.end_time - end_ms  -- Decrease time
                    end
                else
                    -- Absolute timing (set exact value)
                    line.end_time = end_ms
                end
            end
            
            subtitles[i] = line
        end

        aegisub.set_undo_point("تم تعديل توقيت الأسطر المحددة")
        aegisub.debug.out("تم التعديل بنجاح!\n")
    end
end

aegisub.register_macro(script_name, script_description, shift_times)