-- KINFX IME lua entry. install-linux.sh copies this to the RIME user directory.
-- Requires librime-plugin-lua (Debian: librime-plugin-lua).
local win_quick = require("win_quick")
local phrase_mix = require("phrase_mix")

win_quick_keys = win_quick.processor
win_quick_menu = win_quick.filter

-- Globals named by the schema components.
phrase_mix_keys = phrase_mix.processor
phrase_mix_tr = phrase_mix.translator
melt_eng_tr = require("melt_eng")
