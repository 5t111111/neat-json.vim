"if exists('g:loaded_neat_json')
"  finish
"endif
"let g:loaded_neat_json = 1

let s:save_cpo = &cpo
set cpo&vim

" Path to the executed script file
"let g:path_to_this = expand("<sfile>:p:h")

"-------------------------------------------------------
" Python World
"-------------------------------------------------------
function! s:NeatJson()

python << EOF
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
        codecs = ('ascii', 'shift_jis', 'euc_jp', 'utf_8', 'utf_16')

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
    if DEBUG:
        print(org_enc)
    json_enc = 'utf_8'

    def convert_enc(s):
        s_conv = EncodingUtils.convert_encoding(s, org_enc, json_enc)
        return s_conv

    # Decode to unicode for the following processes.
    cb_converted = map(convert_enc, cb)
    u_cb = map(lambda x: x.decode(json_enc), cb_converted)

    # Clean up before decoding to json object
    ustr_json_src_cleaned = u''
    
    for line in u_cb:
        tokens = line.strip().split(u':')
        tokens_stripped = map(lambda x: x.strip(), tokens)
        line_stripped = u':'.join(tokens_stripped)
        ustr_json_src_cleaned = ''.join([ustr_json_src_cleaned, line_stripped])
        
    # Encode string to escaped unicode which json requires.
    ustr_json_src_escaped = ustr_json_src_cleaned.encode("unicode-escape")
    
    # Decode json string to object 
    obj_json = json.loads(ustr_json_src_escaped)
    
    # Encode json object to json string
    str_json_dest = json.dumps(obj_json, sort_keys=True, indent=4, separators=(',', ': '))
    
    # Manually encode json string to utf-8 encoding
    try:
        chr = __builtin__.__dict__.get("unichr")
        str_json_dest_subbed = re.sub(r"¥¥u[0-9a-f]{4}", lambda x: chr(int("0x" + x.group(0)[2:], 16)), str_json_dest)
    except KeyError:
        # do nothing if gettng unichr from the builtin dict failed    
        str_json_dest_subbed = str_json_dest
    
    # Convert back to the original encoding
    str_json_dest_encoded = str_json_dest_subbed.encode(json_enc)
    str_json_org_encoded = EncodingUtils.convert_encoding(str_json_dest_encoded, json_enc, org_enc)

    # Empty the current buffer
    cb[:] = None

    # Put neat json !
    for line in str_json_org_encoded.split('¥n'):
        cb.append(line) 

main()

EOF
endfunction

command! NeatJson call s:NeatJson()

let &cpo = s:save_cpo
unlet s:save_cpo

