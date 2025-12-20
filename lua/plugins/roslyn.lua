-- Roslyn / Razor tooling integration for .NET development
return {
	"seblyng/roslyn.nvim",
	---@module 'roslyn.config'
	---@type RoslynNvimConfig
	ft = { "cs", "razor" },
	opts = {
		-- your configuration comes here; leave empty for default settings
	},
	lazy = false,
	config = function()
		vim.lsp.config("roslyn", {
			settings = {
				-- ============================
				--     C# Inlay Hint Settings
				-- ============================
				["csharp|inlay_hints"] = {

					-- ❌ Disable non-parameter hints
					csharp_enable_inlay_hints_for_implicit_object_creation                = false,
					csharp_enable_inlay_hints_for_implicit_variable_types                 = false,
					csharp_enable_inlay_hints_for_lambda_parameter_types                  = false,
					csharp_enable_inlay_hints_for_types                                   = false,

					-- ✅ Enable parameter-only hints
					dotnet_enable_inlay_hints_for_parameters                              = true,
					dotnet_enable_inlay_hints_for_indexer_parameters                      = true,
					dotnet_enable_inlay_hints_for_literal_parameters                      = true,
					dotnet_enable_inlay_hints_for_object_creation_parameters              = true,
					dotnet_enable_inlay_hints_for_other_parameters                        = true,

					-- 🎯 Smart suppression (choose how minimal you want it)
					dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
					dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name   = true,
					dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent   = true,
				},

				-- ============================
				--     C# CodeLens Settings
				-- ============================
				["csharp|code_lens"] = {
					dotnet_enable_references_code_lens = true,
				},
			},
		})
		vim.lsp.enable("roslyn")
	end,
	init = function()
		-- We add the Razor file types before the plugin loads.
		vim.filetype.add({
			extension = {
				razor = "razor",
				cshtml = "razor",
			},
		})
	end,
}
