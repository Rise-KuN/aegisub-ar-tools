script_name = "Remove Text Between Characters"
script_description = "Remove text between two characters or words"
script_author = "Rise-KuN"
script_version = "1.1.0"

-- حذف ما بين الكلمات

-- Handle the main dialog and text removal
function remove_text_between_characters(subtitles, selected_lines, active_line)
    -- Configuration for delete_selected_char by choosing (True/False)
    local delete_config = {"True", "False"}
	
	-- Dialogs
    local dialog = {
        -- Delete Start and End Characters Option
        {class="label", label=":حذف الحرف/الكلمة", x=50, y=1, width=2, height=1},
        {class="dropdown", name="delete_selected_char", items=delete_config, value=delete_config[1], x=0, y=1, width=50, height=1},
        
        -- Start From Option
        {class="label", label=":البداية", x=50, y=3, width=1, height=1},
        {class="edit", name="start_char", text="", x=0, y=3, width=50, height=1},
        
        -- End From Option
        {class="label", label=":النهاية", x=50, y=4, width=1, height=1},
        {class="edit", name="end_char", text="", x=0, y=4, width=50, height=1},
    }

    -- Show the dialogs
    local pressed, res = aegisub.dialog.display(dialog, {"تطبيق", "إلغاء"})
    
    -- If "تطبيق" is pressed
    if pressed == "تطبيق" then
        -- Get the "start_char" and "end_char" setting from the dialog and convert to boolean
        local delete_selected_char = (res.delete_selected_char == "True")

        -- Get the start and end characters/words from the dialog
        local start_char = res.start_char
        local end_char = res.end_char

        -- Iterate over the selected lines
        for _, i in ipairs(selected_lines) do
            local line = subtitles[i]

            -- Print the start_char and end_char in debug output
            --aegisub.debug.out("Start: '" .. start_char .. "' | End: '" .. end_char .. "'\n\n")
            
            -- Print the original line in the debug output
            --aegisub.debug.out("Original Line: " .. line.text .. "\n\n")

            -- Remove the text between the start and end characters/words
            local new_text = remove_text(line.text, start_char, end_char, delete_selected_char)

            -- Print the updated line in the debug output
            --aegisub.debug.out("Updated Line: " .. new_text .. "\n")

            -- Update the subtitle line with the new text
            line.text = new_text
            subtitles[i] = line
        end
    end
end

-- Remove text between start and end
function remove_text(text, start_char, end_char, delete_selected_char)
    -- Escape special characters for Lua patterns
    start_char = escape_lua_pattern(start_char)
    end_char = escape_lua_pattern(end_char)

    -- Lua pattern to match text between the start and end
    local pattern = start_char .. "(.-)" .. end_char
    
    -- Check if we should to delete the start and end characters
    local new_text
    if delete_selected_char then
        -- If delete_selected_char is true, remove the start and end characters as well
        new_text = text:gsub(pattern, "")
    else
        -- If delete_selected_char is false, keep the start and end characters
        new_text = text:gsub(pattern, start_char .. end_char)
    end

    -- Return the updated text
    return new_text
end

-- Escape special characters in Lua patterns
function escape_lua_pattern(str)
    return str:gsub("([%.%^%$%(%)%[%]%%%+%-%?])", "%%%1")
end

aegisub.register_macro(script_name, script_description, remove_text_between_characters)
