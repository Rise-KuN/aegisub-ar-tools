script_name = "Editor"
script_description = "Text Editor Tool."
script_author = "Rise-KuN"
script_version = "1.0.0"

local clipboard = require "clipboard"

function edit_selected_text(subtitles, selected_lines)
    local selected_text = {}

    -- Collect selected text and combine into one string with line breaks
    for _, line_index in ipairs(selected_lines) do
        local line = subtitles[line_index]
        table.insert(selected_text, line.text)
    end
    local combined_text = table.concat(selected_text, "\n")

    -- Display the dialog with a single editable text box
    local dialog_items = {
        {class="label", label="التي على يمين الكيبورد لتحويل النص من اليمين لليسار ctrl + shift اضغط على", x=0, y=0, width=70, height=1},
        {class="textbox", name="edit_text", text=combined_text, x=0, y=1, width=70, height=25}
    }

    local buttons = {"تطبيق", "نسخ الكل", "إلغاء"}
    local button_pressed, edited_text = aegisub.dialog.display(dialog_items, buttons)

    if button_pressed == "تطبيق" then
        -- Apply edited text to the selected lines
        local new_lines = {}
        for line in edited_text["edit_text"]:gmatch("[^\n]+") do
            table.insert(new_lines, line)
        end
        for i, line_index in ipairs(selected_lines) do
            local line = subtitles[line_index]
            line.text = new_lines[i] or ""
            subtitles[line_index] = line
        end
        aegisub.set_undo_point(script_name)
    elseif button_pressed == "نسخ الكل" then
        -- Copy all edited text to clipboard
        clipboard.set(edited_text["edit_text"])
    end
end

aegisub.register_macro(script_name, script_description, edit_selected_text)