script_name = "Copy & Paste Clip"
script_description = "Copy & Paste Clip Or iclip To The Selected Lines."
script_author = "Rise-KuN"
script_version = "1.0.0"

-- أداة نسخ ولصق الكليب
local clipboard_clips = {}

-- Extract the clip or iclip tag from a line
function extract_clip_tag(text)
    return text:match("\\i?clip%([^%)]+%)")
end

-- Remove the clip or iclip tag from a line
function remove_clip_tag(text)
    return text:gsub("\\i?clip%([^%)]+%)", "")
end

-- Copy the clip or iclip tag from selected lines
function copy_clip(subs, sel)
    -- Clear previous clipboard clips
    clipboard_clips = {}

    for _, i in ipairs(sel) do
        local line = subs[i]
        local clip_tag = extract_clip_tag(line.text)
        if clip_tag then
            table.insert(clipboard_clips, clip_tag)
        end
    end
    aegisub.debug.out(string.format("Copied %d clip tags\n", #clipboard_clips))
end

-- Paste the clip or iclip tag at the end of the formatting tag in the selected lines
function paste_clip(subs, sel)
    if #clipboard_clips == 0 then
        aegisub.debug.out("No clip tags copied!!!\n")
        return
    end

    local clip_index = 1
    for _, i in ipairs(sel) do
        local line = subs[i]
        local clip_tag = clipboard_clips[clip_index]
        line.text = remove_clip_tag(line.text)  -- Remove any existing clip or iclip tag
        
        -- Check if the line has a tag {} and if so append the clip tag inside the tag
        local start_idx, end_idx = line.text:find("{[^}]*}")
        if start_idx and end_idx then
            -- Insert the clip tag before the closing brace
            line.text = line.text:sub(1, end_idx - 1) .. clip_tag .. line.text:sub(end_idx)
        else
            -- If no tag exists, create one with the clip tag
            line.text = "{" .. clip_tag .. "}" .. line.text
        end
        
        subs[i] = line
        -- Loop through copied clips if fewer than selected lines
        clip_index = clip_index % #clipboard_clips + 1
    end
    aegisub.debug.out(string.format("Pasted clip tags to %d lines\n", #sel))
end

-- Copy & Paste Clip dialog pop-up
function copy_paste_clip(subs, sel)
    local buttons = {"نسخ", "لصق", "إلغاء"}
    local config = {
        {class="label", label="يمكنك نسخ الكليب من تترات متعددة ولصقها في تترات أخرى، لكن يجب أن يكون عدد التترات نفسه", x=0, y=0, width=2, height=1},
    }
    local pressed, _ = aegisub.dialog.display(config, buttons)
    
    if pressed == "نسخ" then
        copy_clip(subs, sel)
    elseif pressed == "لصق" then
        paste_clip(subs, sel)
    end
end

aegisub.register_macro(script_name, script_description, copy_paste_clip)