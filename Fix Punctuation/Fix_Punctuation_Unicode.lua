script_name = "تصحيح نقاط آخر السطر"
script_description = " Punctuation fix for RTL languages"
script_author = "Meysam based on Niels Martin Hansen's script.Thanks to DemonEyes and rezabrando  "
script_version = "1.2"

include("unicode.lua")

lookup = {
 ['.'] = '‏.‏',
 [';'] = '؛‏' ,
 ['!'] = '‏!‏', 
 [']'] = ']‏', 
 ['['] = '‏]‏‏',
 [':'] = '‏:‏',
 ["«"] = '‏»‏',
 ['('] = '‏)‏‏‏', 
 [')'] = ')‏',
 ['»'] = '‏«‏',
 ['-'] = '‏-‏',
 ['"'] = '‏"‏', 
 ['،'] = '‏،‏', 
}

function fix_punctuation_unicode(subtitles, selected_lines, active_line)
	for z, i in ipairs(selected_lines) do
		local l = subtitles[i]
		
		aegisub.debug.out(string.format('Processing line %d: "%s"\n', i, l.text))
		aegisub.debug.out("Chars: \n")
		
		local in_tags = false
		local newtext = ""
		for c in unicode.chars(l.text) do
			aegisub.debug.out(c .. ' -> ')
			if c == "{" then
				in_tags = true
			end
			if in_tags then
				aegisub.debug.out(c .. " (ignored, in tags)\n")
				newtext = newtext .. c
			else
				if lookup[c] then
					aegisub.debug.out(lookup[c] .. " (converted)\n")
					newtext = newtext .. lookup[c]
				else
					aegisub.debug.out(c .. " (not found in lookup)\n")
					newtext = newtext .. c
				end
			end
			if c == "}" then
				in_tags = false
			end
		end
		
		l.text = newtext
		subtitles[i] = l
	end
	aegisub.set_undo_point("Punctuation fix")
end

aegisub.register_macro("تصحيح نقاط آخر السطر", "تصحيح نقاط آخر السطر", fix_punctuation_unicode)
