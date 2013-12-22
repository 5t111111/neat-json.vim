if exists('g:loaded_neatjson')
  finish
endif
let g:loaded_neatjson = 1

command! NeatJson call neatjson#NeatJson('MODE_NORMAL')
command! NeatRawJson call neatjson#NeatJson('MODE_RAW')
