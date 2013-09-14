if exists('g:loaded_neat_json')
  finish
endif
let g:loaded_neat_json = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:LoadPythonModulePath()
    for l:i in split(globpath(&runtimepath, "plugin/neat_json_lib"), '\n')
        let s:python_module_path = fnamemodify(l:i, ":p")
    endfor
    python << EOF
import vim
import site

site.addsitedir(vim.eval('s:python_module_path'))
EOF
endfunction

function! s:NeatJson()

    call s:LoadPythonModulePath()

python << EOF
import vim
import json
import re
import __builtin__
import chardet

DEBUG = False

def main():

    cb = vim.current.buffer

    # Convert encoding to utf-8 at first
    org_enc = chardet.detect(''.join(cb))['encoding']
    json_enc = 'utf_8'

    # Decode to unicode for the following processes.
    buf_str = map(lambda s: s.decode(org_enc), cb)

    # Clean up before decoding to json object
    json_str = u''
    
    for line in buf_str:
        tokens = line.strip().split(u':')
        tokens = map(lambda x: x.strip(), tokens)
        line = u':'.join(tokens)
        json_str = ''.join([json_str, line])
        
    # Encode string to escaped unicode which json requires.
    json_str = json_str.encode('unicode-escape')
    
    # Decode json string to object 
    json_obj = json.loads(json_str)
    
    # Encode json object to json string
    json_str = json.dumps(json_obj, sort_keys=True, indent=4, separators=(',', ': '))
    json_str = json_str.decode(json_enc)
    
    # Empty the current buffer
    cb[:] = None

    try:
        chr = __builtin__.__dict__.get("unichr")
    except KeyError:
        chr = None

    # Put neat json !
    for line in json_str.split(u'\n'):
        # Convert back to the original encoding
        if not chr == None:
            line = re.sub(r'\\u[0-9a-f]{4}', lambda x: chr(int(u'0x' + x.group(0)[2:], 16)), line)
            line = line.encode(org_enc)
        cb.append(line) 
    
    # delete unexpected empty line on the top of the buffer
    cb[0] = None

main()

EOF
endfunction

command! NeatJson call s:NeatJson()

let &cpo = s:save_cpo
unlet s:save_cpo

