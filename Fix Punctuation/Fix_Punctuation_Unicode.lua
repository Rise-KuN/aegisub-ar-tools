script_name = "تصحيح نقاط آخر السطر"
script_description = "Adds U+202B unicode character to start of all selected lines, Thus fixing the RTL problem in Aegisub"
script_author = "Shinsekai_Yuri"
script_version = "1.0.0"

include("unicode.lua")

function fix_punctuation_unicode(subtitles, selected_lines, active_line)
    -- Local variables
    local u202b = "\226\128\171"
    local n = "\\n"
    local N = "\\N"
    local rbracket = "}"
    local lbracket = "{"
    
    -- Local helper function
    local function starts_with(str, start)
        return str:sub(1, #start) == start
    end

    for z, i in ipairs(selected_lines) do
        local l = subtitles[i]
        if string.match(l.text, u202b) then l.text = l.text:gsub(u202b, "") end
        l.text = u202b .. l.text
        if string.match(l.text, N) then l.text = l.text:gsub(N, N .. u202b) end
        if string.match(l.text, n) then l.text = l.text:gsub(n, n .. u202b) end
        if string.match(l.text, rbracket) then l.text = l.text:gsub(rbracket, rbracket .. u202b) end
        if string.match(l.text, u202b..lbracket) then l.text = l.text:gsub(u202b..lbracket, lbracket) end
        subtitles[i] = l
    end
    
    aegisub.set_undo_point(script_name)
end

aegisub.register_macro("تصحيح نقاط آخر السطر", "تصحيح نقاط آخر السطر", fix_punctuation_unicode)
