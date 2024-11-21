script_name = "Split Line to Frames"
script_description = "Splits a line to individual frames"
script_author = "Rise-KuN"
script_version = "1.0"

-- تقسيم السطر إلى فريمات

-- Calculate the video frame rate
function calculate_fps()
    local start_ms = 0  -- Starting time in milliseconds
    local end_ms = 1000 -- End time in milliseconds (1 second)

    local start_frame = aegisub.frame_from_ms(start_ms)
    local end_frame = aegisub.frame_from_ms(end_ms)

    -- Number of frames in one second is the frame rate
    return end_frame - start_frame
end

function split_line_to_frames(subtitles, selected_lines)
    aegisub.progress.task("Splitting line to frames...")

    -- Default frame rate
    -- local frame_rate = 23.976
    local frame_rate = calculate_fps()
    -- aegisub.debug.out("frame rate: " .. frame_rate .. " fps\n")
	
	-- Frame duration in milliseconds
    local frame_duration = 1000 / frame_rate

    for _, i in ipairs(selected_lines) do
        local line = subtitles[i]
        local start_time = line.start_time
        local end_time = line.end_time
        local duration = end_time - start_time

        -- Calculate the number of frames
        local num_frames = math.floor(duration / frame_duration)

        for frame = 0, num_frames - 1 do
            local new_line = table.copy(line)
            new_line.start_time = start_time + frame * frame_duration
            new_line.end_time = math.min(new_line.start_time + frame_duration, end_time)
            subtitles.insert(i + frame, new_line)
        end

        -- Remove the original line
        subtitles.delete(i + num_frames)
    end

    aegisub.set_undo_point(script_name)
end

aegisub.register_macro(script_name, script_description, split_line_to_frames)
