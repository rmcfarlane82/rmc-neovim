local M = {}

function M.setup()
	-- Register Razor file extensions before Roslyn loads
	vim.filetype.add({
		extension = {
			razor = "razor",
			cshtml = "razor",
		},
	})
end

return M
