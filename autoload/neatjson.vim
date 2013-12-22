let s:save_cpo = &cpo
set cpo&vim

function! s:LoadPythonModulePath()
    for l:i in split(globpath(&runtimepath, "neatjson_lib"), '\n')
        let s:python_module_path = fnamemodify(l:i, ":p")
    endfor
    python << EOF
import vim
import site

site.addsitedir(vim.eval('s:python_module_path'))
EOF
endfunction

function! neatjson#NeatJson(arg)

    call s:LoadPythonModulePath()

python << EOF
import vim
import json
import re
import __builtin__
import chardet

DEBUG = False

def main(arg):

    mode = arg

    cb = vim.current.buffer

    # Convert encoding to utf-8 at first
    enc = chardet.detect(''.join(cb))['encoding']

    # Decode to unicode for the following processes.
    buf_str = map(lambda s: s.decode(enc), cb)

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
    json_str = json_str.decode('utf_8')
    
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
            line = re.sub(r'\\\\u', r'\\u', line)
            if mode == 'MODE_NORMAL':
                line = re.sub(r'\\u[0-9(a-f|A-F)]{4}', lambda x: chr(int(u'0x' + x.group(0)[2:], 16)), line)
            line = line.encode('utf_8')
        cb.append(line) 
    
    # delete unexpected empty line on the top of the buffer
    cb[0] = None

main(vim.eval('a:arg'))

EOF
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

