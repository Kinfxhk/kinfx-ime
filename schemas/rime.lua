-- KINFX IME lua entry. Installers copy this to the Rime user directory.
-- Requires librime-lua (Weasel ships it; Debian: librime-plugin-lua).
local win_quick = require("win_quick")
local phrase_mix = require("phrase_mix")

win_quick_keys = win_quick.processor
win_quick_menu = win_quick.filter

phrase_mix_keys = phrase_mix.processor
phrase_mix_seg = phrase_mix.segmentor
