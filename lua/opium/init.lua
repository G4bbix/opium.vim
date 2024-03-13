function OpiumCheckExcludeSymbol()
	local exclude_names = {"string", "comment"}
	local bufnr = vim.api.nvim_get_current_buf()
	local symbol_names = vim.treesitter.get_captures_at_pos(bufnr,
		vim.g.opium_symbol_row - 1,
		vim.g.opium_symbol_col - 1)
	for _, i in pairs(symbol_names) do
	 	for _, symbol_name in pairs(i) do
			for _, exclude_name in pairs(exclude_names) do
				if exclude_name == symbol_name then
					vim.g.opium_symbol_res = 1
					return
				end
			end
		end
	end
	vim.g.opium_symbol_res = 0
end
