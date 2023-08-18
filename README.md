# vim-opium
Rewrite of https://github.com/bounceme/opium.vim
Mostly to have highlighting for bash:
- if - fi
- for - done
- while - done
- case - esac

After developing this i hoped the opium contained some opium....

Enabled with autocmds ( :h autocommand )

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
included with vim, `let g:opium_point_enable = 1` .
