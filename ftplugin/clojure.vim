"=============================================================================
" README.
" 1. What is this plugin?
"   This plugin add simple REPL support for clojure.
"
"   Like slime for emacs or slimv for vim except that this is much simpler and
"   comunicate via slimux instead of swank connection.
"
" 2. Default Key bindings.
"   Note: This leader is Slimux_clojure specific, the same to g:mapleader by
"   default.
"
"   <Leader>d -- evaluate the top block which the cursor is in.
"   <Leader>b -- evaluate the whole buffer
"
"   If you have enabled xrepl, we have the following addtional key bindings:
"
"   <leader>t -- Goto `user` namespace
"   <leader>s -- Goto current namespace
"
" 3. Configurations.
"   a) To disable this plugin
"       add `let g:slimux_clojure_loaded=1` to your vimrc
"
"   b) To enable default keybindings (recommended)
"       let g:slimux_clojure_keybindings=1
"
"   c) To change the default leader, want to change it to ';' for example.
"       let g:slimux_clojure_leader=';'
"=============================================================================

" Settings {{{1
" Whether to load this plugin or not.
if exists("g:slimux_clojure_loaded")
    finish
endif
let g:slimux_clojure_loaded= 1

" set Custom <Leader> for the slimux_clojure plugin
if !exists('g:slimux_clojure_leader')
    if exists( 'mapleader' ) && mapleader != ' '
        let g:slimux_clojure_leader = mapleader
    else
        let g:slimux_clojure_leader = ','
    endif
endif

" slimux_clojure keybinding set (0 = no keybindings)
if !exists('g:slimux_clojure_keybindings')
    let g:slimux_clojure_keybindings = 0
endif

" Add clojure support for normal SlimuxSendSelection {{{1

function! SlimuxEscape_clojure(text)
    " if text does not end with newline, add one
    if a:text !~ "\n$"
        let str_ret = a:text . '\n'
    else
        let str_ret = a:text
    endif

    return str_ret
endfunction


" Function Definitions {{{1

" Evaluate a clojure 'define' statement
function! Slimux_clojure_eval_defun()
    let pos = getpos(".")
    let regContent = @"
    let s:skip_sc = 'synIDattr(synID(line("."), col("."), 0), "name") =~ "[Ss]tring\\|[Cc]omment"'
    let [lhead, chead] = searchpairpos( '(', '', ')', 'bW', s:skip_sc)
    call cursor(lhead, chead)
    silent! exec "normal! 99[(yab"
    if getline('.')[0] == '('
        call SlimuxSendCode(@" . "\n")
    else
        call SlimuxSendCode(getline('.') . "\n")
    endif
    " restore contents
    let @" = regContent
    call setpos('.', pos)
endfunction

function! Slimux_clojure_get_ns()
    let pos = getpos(".")
    let regContent = @"

    call cursor(1, 1)
    call search('(ns\s\+[^\s]\+')
    silent! exec "normal! wwyaW"
    let raw_ns = @"
    let @" = regContent
    call setpos('.', pos)

    let stripped_ns = substitute(raw_ns, " ", "", "")
    return empty(stripped_ns) ? "user" : stripped_ns
endfunction

" Evaluate the entire buffer
function! Slimux_clojure_eval_buffer()
    call SlimuxSendCode('(load-file "' . expand('%:p') . '")' . "\n")
endfunction

" Evaluate the entire buffer
function! Slimux_clojure_ns_top()
    call SlimuxSendCode("(in-ns 'user)" . "\n")
endfunction

" Evaluate the entire buffer
function! Slimux_clojure_ns_current()
    " search ns in current buffer
    let ns = Slimux_clojure_get_ns()
    call SlimuxSendCode("(in-ns '" . ns . ")\n")
endfunction


" Change functions to commands {{{1
command! SlimuxclojureEvalDefun call Slimux_clojure_eval_defun()
command! SlimuxclojureEvalBuffer call Slimux_clojure_eval_buffer()
command! SlimuxclojureNsTop call Slimux_clojure_ns_top()
command! SlimuxclojureNsCurrent call Slimux_clojure_ns_current()

" Set keybindings {{{1
if g:slimux_clojure_keybindings == 1
    execute 'noremap <buffer> <silent> ' . g:slimux_clojure_leader.'d :SlimuxclojureEvalDefun<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_clojure_leader.'b :SlimuxclojureEvalBuffer<CR>'
    execute 'inoremap <buffer> <silent> <C-c><C-c> <ESC>:SlimuxclojureEvalDefun<CR>a'
    execute 'nnoremap <buffer> <silent> <C-c><C-c> <ESC>:SlimuxclojureEvalDefun<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_clojure_leader.'t :SlimuxclojureNsTop<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_clojure_leader.'s :SlimuxclojureNsCurrent<CR>'
endif
