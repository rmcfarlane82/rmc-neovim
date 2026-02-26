local M = {}

local function restart_roslyn()
	vim.cmd("LspRestart roslyn")
end

function M.setup()
	-- Restart Roslyn when solution/project files change
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("RoslynProjectRefresh", { clear = true }),
		pattern = { "*.csproj", "*.sln", "*.slnf", "*.slnx" },
		callback = restart_roslyn,
		desc = "Restart Roslyn when solution/project files change",
	})

	-- Restart Roslyn after saving a newly created C# file
	vim.api.nvim_create_autocmd("BufNewFile", {
		group = vim.api.nvim_create_augroup("RoslynNewFile", { clear = true }),
		pattern = { "*.cs" },
		callback = function(args)
			vim.b[args.buf].roslyn_new_file = true
		end,
		desc = "Mark new C# files for Roslyn restart on first save",
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("RoslynNewFile", { clear = false }),
		pattern = { "*.cs" },
		callback = function(args)
			if vim.b[args.buf].roslyn_new_file then
				vim.b[args.buf].roslyn_new_file = nil
				restart_roslyn()
			end
		end,
		desc = "Restart Roslyn after saving a newly created C# file",
	})
end

return M
