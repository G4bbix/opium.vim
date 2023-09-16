# vim-opium
Rewrite of https://github.com/bounceme/poppy.vim
Mostly to have highlighting for bash:

After developing this i hoped the poppy contained some opium....

## Install
```
Plug 'G4bbix/opium.vim'
```
Or which ever Plugin manager you use.

## Config
Enabled with autocmds (:h autocommand)

example:

`au! cursormoved * call OpiumInit()`

or:

`au! cursormoved *.lisp call OpiumInit()`

or even make a mapping:

```
augroup Opium
  au!
augroup END
nnoremap <silent> <leader>hp :call clearmatches() \| let g:opium = -get(g:,'opium',-1) \|
      \ exe 'au! Opium CursorMoved *' . (g:opium > 0 ? ' call OpiumInit()' : '') <cr>
```

modify coloring by changing `g:opiumhigh`, which is a list of highlight group names.

If you want only 1 paren level highlighted, let `g:opiumhigh` to a list with 1 group name.

If you want the highlighting to include matches which are under the cursor, like the matchparen plugin
included with vim, `let g:opium_point_enable = 1` 


## Language specific highlighting
### Bash
- if - fi
- for - done
- while - done
- case - esac

### vimscript
- if - endfi
- for - endfor
- while - endwhile
- function - endfunction

### Add your own:
Add this to your .vimrc:
```
let opium_pairs_lang_specific["lang_name"] : {
\ "pair1_start": "pair1_end",
\ "pair2_start": "pair2_end",
}
```
Not that lang_name must be the filetype that vim identifies (see :h filetype)
