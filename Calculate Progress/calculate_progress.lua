script_name = "حساب نسبة التقدم"
script_description = "حساب نسبة التقدم في الترجمة بناءً على عدد الأسطر"
script_author = "Rise-KuN"
script_version = "1.0"

-- Function to calculate progress
function calculate_progress(subtitles, selected_lines, active_line)
    -- Define the dialog box layout
    dialog_config = {
        {
            class = "label",
            label = ":رقم آخر سطر تمت ترجمته",
            x = 1, y = 0, width = 1, height = 1
        },
        {
            class = "intedit", name = "last_line", value = 0,
            x = 0, y = 0, width = 1, height = 1
        },
        {
            class = "label",
            label = ":العدد الإجمالي للأسطر",
            x = 1, y = 1, width = 1, height = 1
        },
        {
            class = "intedit", name = "total_lines", value = 0,
            x = 0, y = 1, width = 1, height = 1
        }
    }

    -- Show the dialog box
    buttons = {"احسب", "إلغاء"}
    pressed, results = aegisub.dialog.display(dialog_config, buttons)

    -- If "Cancel" is pressed, do nothing
    if pressed == "إلغاء" then
        aegisub.cancel()
        return
    end

    -- Get the input values
    local last_line = results.last_line
    local total_lines = results.total_lines

    -- Validate input
    if total_lines == 0 then
        aegisub.dialog.display({{class = "label", label = ".إجمالي عدد الأسطر يجب أن يكون أكبر من الصفر", x = 0, y = 0, width = 1, height = 1}}, {"موافق"})
        return
    end

    -- Calculate progress percentage
    local progress_percentage = (last_line / total_lines) * 100

    -- Show the result
    aegisub.dialog.display({{class = "label", label = "%" .. "نسبة التقدم: " .. string.format("%.2f", progress_percentage), x = 0, y = 0, width = 1, height = 1}}, {"موافق"})
end

-- Register the macro
aegisub.register_macro(script_name, script_description, calculate_progress)
