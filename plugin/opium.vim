if !has('reltime') || exists('*OpiumInit')
	finish
endif
let g:opiumhigh = get(g:, 'opiumhigh', ['identifier', 'constant', 'preproc', 'special', 'type'])
let g:opium_pairs = { '{': '}',
	\ '[': ']',
	\ '(': ')',
	\ 'if': '\<fi\>',
	\ 'for': '\<done\>',
	\ 'while': '\<done\>',
	\ 'case': '\<esac\>'
	\ }

function s:highpat()
	let s:synid_cache = {}
	" Prevent mem leaks in very large files
	if len(s:synid_cache) > 100
		unlet s:synid_cache
	endif
	let stoplinebottom = line('w$')
	let stoplinetop = line('w0')
	let s:opiumhigh = deepcopy(g:opiumhigh)
	let s:startingRe = '\m[[({]\|\<if\>\|\<while\>\|\<for\>\|\<case\>'
	let inc = get(g:,'opium_point_enable') && getline('.')[col('.')-1] =~ s:startingRe ? 'c' : ''
	call searchpair(s:startingRe, '','noop',inc.(len(g:opiumhigh) > 1 ? 'r' : '').'nbW', "getline('.')[col('.')-1] == 'n' ||"
			\ ."s:SynAt(line('.'),col('.')) =~? 'regex\\|comment\\|string' ||"
			\ .'s:endpart('.stoplinebottom.')',stoplinetop,30)
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
			let p = searchpairpos(s:search_opening, '', s:search_closing, 'W', "s:SynAt(line('.'),col('.')) =~? 'regex\\|comment\\|string'",
				\ a:last_line,300)
			if index(g:alreadyUsedCloses, line('.').':'.col('.')) == -1
				break
			endif
		endwhile

		if p[0] && (line2byte(p[0]) + p[1] > line2byte(s:pos[0]) + s:pos[1] || get(g:,'opium_point_enable') && p == s:pos)
			let s:opening_len = len(s:opening_word)
			let s:closing_len = len(substitute(g:opium_pairs[s:opening_word], '\\<\([a-z]\+\)\\>', '\1', 'g'))
			let opening_matchaddPosArgs = opening_pos
			call insert(opening_matchaddPosArgs, s:opening_len, 2)
			call insert(p, s:closing_len, 2)
			let w:opiums += [s:matchadd(remove(add(s:opiumhigh,s:opiumhigh[0]), 0), [opening_matchaddPosArgs, p])]
			let g:alreadyUsedCloses += [p[0].':'.p[1]]
		else
			return 1
		endif
	else
		return 2
	endif
endfunction

function OpiumInit()
	" Since for and while use the same closing word the already used done must be marked as such
	" if exists('g:alreadyUsedCloses')
	"   unlet g:alreadyUsedCloses
	" endif
	let g:alreadyUsedCloses = []
	let s:pos = getpos('.')[1:2] | let w:opiums = get(w:,'opiums',[])
		\ | silent! call filter(w:opiums, 'matchdelete(v:val) > 0') | call s:highpat()
endfunction
