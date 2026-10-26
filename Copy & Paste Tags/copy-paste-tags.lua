script_name = "Copy and Paste Tags"
script_description = "Copy and paste override tags."
script_author = "Rise-KuN"
script_version = "1.0.0"

function copy_paste_tags(subs, sel)
    local macro_name = "Copy and Paste Tags"
    local clipboard = require "clipboard"

    local function show_dialog()
        local dialog = {
            {
                class="dropdown",
                name="mode",
                label="Action:",
                items={"Copy Tags", "Paste Tags"},
                value="Copy Tags"
            }
        }

        local btn, res = aegisub.dialog.display(dialog, {"OK", "Cancel"})

        if btn ~= "OK" then
            return nil
        end

        return res.mode
    end

    local function get_first_tag(text)
        return text:match("^%s*(%b{})")
    end

    local function replace_first_tag(text, new_tag)
        if text:match("^%s*%b{}") then
            return text:gsub("^(%s*)%b{}", "%1" .. new_tag, 1)
        else
            local spaces = text:match("^(%s*)") or ""
            return spaces .. new_tag .. text:sub(#spaces + 1)
        end
    end

    local function copy_tags()
        local data = {}

        for _, i in ipairs(sel) do
            local line = subs[i]
            local tag = get_first_tag(line.text)

            if tag then
                table.insert(data, tag)
            else
                table.insert(data, "{}")
            end
        end

        clipboard.set(table.concat(data, "\n"))
        aegisub.log("Copied tags from %d lines.\n", #data)
    end

    local function paste_tags()
        local raw = clipboard.get()

        if not raw or raw == "" then
            aegisub.cancel("Clipboard doesn't contain copied tags.")
        end

        local tags = {}

        for tag in raw:gmatch("[^\r\n]+") do
            table.insert(tags, tag)
        end

        if #tags ~= #sel then
            aegisub.cancel(string.format(
                "Copied %d lines but selected %d.",
                #tags, #sel
            ))
        end

        for n, i in ipairs(sel) do
            local line = subs[i]
            line.text = replace_first_tag(line.text, tags[n])
            subs[i] = line
        end

        aegisub.set_undo_point(macro_name)
    end

    local mode = show_dialog()

    if not mode then return end

    if mode == "Copy Tags" then
        copy_tags()
    else
        paste_tags()
    end

end

aegisub.register_macro(script_name, script_description, copy_paste_tags)