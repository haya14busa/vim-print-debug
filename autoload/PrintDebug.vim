"=============================================================================
" FILE: autoload/PrintDebug.vim
" AUTHOR: haya14busa
" Last Change: 07-09-2014.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

" TODO: take `filetype` into account
"   Currently, only supporting language is `scala`
"   In other words, support other languages to print debug of function:)

let s:V = vital#of('PrintDebug')
let s:S = s:V.import('Data.String')

function! PrintDebug#PrintDebug(logger_func)
    let args_dict = PrintDebug#GetCursorFuncArgs()
    let lines = split(s:format_log_str(args_dict), "\n")
    let indented_str = join(['']
    \   + map(lines, "repeat(' ', strdisplaywidth(a:logger_func) + 4) . v:val")
    \   , "\n")
    return printf('%s(%s)', a:logger_func, indented_str)
endfunction

function! s:format_log_str(args_dict)
    return join(['s"""==DEBUG ARGUMENTS==']
    \  +   map(a:args_dict, "printf('|  %s: %s = ${%s}', v:val.arg, v:val.type, v:val.arg)")
    \  +   ['|""".stripMargin']
    \  , "\n")
endfunction

" @return [{'arg': '{arg_name}', 'type': '{arg_type}'}, ...]
function! PrintDebug#GetCursorFuncArgs()
    " before
    let w = winsaveview()
    let save_reg = getreg('"', 1)
    let save_type = getregtype('"')
    try
        " Go to def
        let pos =  searchpos('\vdef\s[^(]*\(\zs(\_.*)\)', 'bcW')
        if pos == [0, 0] | return [] | endif
        " Get arguments string
        silent! normal! ""yib
        let args_str = @"
        let args = s:format_split(args_str, ':')
        " Construct argument list with types:
        "   ['{arg1}', '{type1}', '{arg2}', '{type2}', ...]
        let args_and_types = []
        let head = s:remove_spaces(args[0])
        call add(args_and_types, head)
        let middle = map(args[1:-2], 's:remove_spaces(v:val)')
        for x in middle
            let separator_index = len(x) - match(s:S.reverse(x), ',') - 1
            call add(args_and_types, s:remove_spaces(x[:(separator_index - 1)]))
            call add(args_and_types, s:remove_spaces(x[(separator_index + 1):]))
        endfor
        let tail = s:remove_spaces(args[-1])
        call add(args_and_types, tail)
        " Construct dictionary
        let result = [] " [{'arg': 'hoge', 'type' : 'String'}]
        for i in range(len(args_and_types) / 2)
            let base_idx = i * 2
            call add(result, {
            \       'arg' : args_and_types[base_idx]
            \     , 'type': args_and_types[base_idx + 1]
            \   })
        endfor
        return result
    finally " after
        call setreg('"', save_reg, save_type)
        call winrestview(w)
    endtry
endfunction

" Helper:
function! s:remove_spaces(expr)
    return s:S.chomp(s:S.trim(a:expr))
endfunction

" see :h split()
function! s:format_split(expr, separator)
    return filter(map(split(a:expr, a:separator), 's:S.trim(v:val)'), '!empty(v:val)')
endfunction

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}
" __END__  {{{
" vim: expandtab softtabstop=4 shiftwidth=4
" vim: foldmethod=marker
" }}}
