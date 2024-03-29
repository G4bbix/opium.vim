if !has('reltime') || exists('*OpiumInit')
	finish
endif

let g:opium_pairs_setup = 1
let g:opiumhigh = get(g:, 'opiumhigh', ['identifier', 'constant', 'preproc', 'special', 'type'])
let g:opium_pairs_lang_specific = {
	\ 'vim': {
		\ 'if': 'endif',
		\ 'function': 'endfunction',
		\ 'while': 'endwhile',
		\ 'for': 'endfor',
		\ 'try': 'endtry'
	\ },
	\ 'sh' : {
		\ 'if': '\<fi\>',
		\ 'for': '\<done\>',
		\ 'while': '\<done\>',
		\ 'case': '\<esac\>'
	\ },
	\ 'lua' : {
		\ 'function': 'end',
		\ 'if': 'end',
		\ 'for': 'end',
		\ 'while': 'end',
		\ 'repeat': 'until',
	\ }}
let g:opium_pairs = {
	\ '{': '}',
	\ '[': ']',
	\ '(': ')'
	\ }
let g:opening_re = '\m[[({]'

function s:highpat()
	let s:synid_cache = {}
	" Prevent mem leaks in very large files
	if len(s:synid_cache) > 100
		unlet s:synid_cache
	endif
	let stoplinebottom = line('w$')
	let stoplinetop = line('w0')
	let s:opiumhigh = deepcopy(g:opiumhigh)
	let inc = get(g:,'opium_point_enable') && getline('.')[col('.')-1] =~ g:opening_re ? 'c' : ''
	call searchpair(g:opening_re, '','noop',inc.(len(g:opiumhigh) > 1 ? 'r' : '').'nbW', "getline('.')[col('.')-1] == 'n' ||"
			\ .'s:ExcludeSyn() || s:endpart('.stoplinebottom.')',stoplinetop,30)
endfunction

function s:ExcludeSyn()
	if exists(':TSUpdate')
		let g:opium_symbol_row = line('.')
		let g:opium_symbol_col = col('.')
		lua OpiumCheckExcludeSymbol()
		return g:opium_symbol_res
	else
		let s:excludes = ['regex', 'comment', 'string', 'shDoubleQuote', 'shComment', 'shSingleQuote']
		return index(s:excludes, s:SynAt(line('.'),col('.'))) >= 0
	endif
endfunction

function s:SynAt(l, c)
	let pos = a:l.','.a:c
	if !has_key(s:synid_cache,pos)
		let s:synid_cache[pos] = synIDattr(synID(a:l, a:c,0), 'name')
	endif
	return s:synid_cache[pos]
endfunction

if exists('*matchaddpos')
	function s:matchadd(hi, pos)
		return matchaddpos(a:hi, a:pos)
	endfunction
else
	function s:matchadd(hi, pos)
		return matchadd(a:hi, '\%'.a:pos[0][0].'l\%'.a:pos[0][1].'c\|\%'.a:pos[1][0].'l\%'.a:pos[1][1].'c')
	endfunction
endif

function s:endpart(last_line)
	" if under the cursor is a opium pair of one char, set it as the opening word
	let s:char_under_cursor = strcharpart(strpart(getline('.'), col('.') - 1), 0, 1)
	if has_key(g:opium_pairs, s:char_under_cursor)
		let s:opening_word = s:char_under_cursor
	else
		let s:opening_word = expand('<cword>')
	endif
	" Prevent test alias for [ to not highlight
	if s:opening_word ==# 'test' && getline('.')[col('.')-1] ==# '['
		let s:opening_word = '['
	endif
	if has_key(g:opium_pairs, s:opening_word)
		let opening_pos = [line('.'), col('.')]
		if len(s:opening_word) ==# 1
			let s:search_opening = '\V' . s:opening_word
			let s:search_closing = '\V' . g:opium_pairs[s:opening_word]
		else
			let s:search_opening = s:opening_word
			let s:search_closing = g:opium_pairs[s:opening_word]
		endif

		while 1
			let p = searchpairpos(s:search_opening, '', s:search_closing, 'W', 's:ExcludeSyn()',
				\ a:last_line,300)
			if index(g:already_used_closes, line('.').':'.col('.')) == -1
				break
			endif
			" Break if end is reached
			if line('.') == line('w$')
				return
			endif
		endwhile

		if p[0] && (line2byte(p[0]) + p[1] > line2byte(s:pos[0]) + s:pos[1] || get(g:,'opium_point_enable') && p == s:pos)
			let s:opening_len = len(s:opening_word)
			let s:closing_len = len(substitute(g:opium_pairs[s:opening_word], '\\<\([a-z]\+\)\\>', '\1', 'g'))
			let opening_matchaddPosArgs = opening_pos
			call insert(opening_matchaddPosArgs, s:opening_len, 2)
			call insert(p, s:closing_len, 2)
			let w:opiums += [s:matchadd(remove(add(s:opiumhigh,s:opiumhigh[0]), 0), [opening_matchaddPosArgs, p])]
			let g:already_used_closes += [p[0].':'.p[1]]
		else
			return 1
		endif
	else
		return 2
	endif
endfunction

function OpiumInit()
	if g:opium_pairs_setup && has_key(g:opium_pairs_lang_specific, &filetype)
		let g:opium_pairs = extend(g:opium_pairs, g:opium_pairs_lang_specific[&filetype])
		let g:opium_pairs_setup = 0
		" Build opening word regex
		for opening_word in keys(g:opium_pairs_lang_specific[&filetype])
			let g:opening_re = g:opening_re . '\|' . opening_word
		endfor
	endif
	" Since for and while use the same closing word the already used done must be marked as such
	if exists('g:already_used_closes')
		unlet g:already_used_closes
	endif
	let g:already_used_closes = []
	let s:pos = getpos('.')[1:2] | let w:opiums = get(w:,'opiums',[])
		\ | silent! call filter(w:opiums, 'matchdelete(v:val) > 0') | call s:highpat()
endfunction
