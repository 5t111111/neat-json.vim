if exists('g:loaded_neat_json')
  finish
endif
let g:loaded_neat_json = 1

let s:save_cpo = &cpo
set cpo&vim

" Path to the executed script file
"let g:path_to_this = expand("<sfile>:p:h")

"-------------------------------------------------------
function! s:NeatJson()
"-------------------------------------------------------
python << EOF
import vim
import json
import re
import __builtin__

DEBUG = True

class EncodingUtils(object):

    @classmethod
    def guess_encoding(cls, data):
        """
        Guess the encoding of the data sepecified 
        """
        codecs = ('ascii', 'shift_jis', 'euc_jp', 'utf_8')

        f = lambda data, enc: data.decode(enc) and enc
    
        for codec in codecs:
            try:
                f(data, codec)
                return codec
            except:
                pass;
    
        return None
    
    @classmethod
    def convert_encoding(cls, data, codec_from, codec_to='utf_8'):
        """
        Convert the encoding of the data to the specifed encoding
        """
        udata = data.decode(codec_from)
        if (isinstance(udata, unicode)):
            return udata.encode(codec_to, errors='ignore') 

def main():

    cb = vim.current.buffer

    # Convert encoding to utf-8 at first
    org_enc = EncodingUtils.guess_encoding(''.join(cb))
    json_enc = 'utf_8'

    # Decode to unicode for the following processes.
    buf_str = map(lambda s: EncodingUtils.convert_encoding(s, org_enc, json_enc), cb)
    buf_str = map(lambda s: s.decode(json_enc), buf_str)

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
            line = line.encode(json_enc)
            line = EncodingUtils.convert_encoding(line, json_enc, org_enc)
        cb.append(line) 
    
    # delete unexpected empty line on the top of the buffer
    cb[0] = None

main()

EOF
endfunction

command! NeatJson call s:NeatJson()

let &cpo = s:save_cpo
unlet s:save_cpo

