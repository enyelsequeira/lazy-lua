-- /nvim/plugins/conform.lua
local formatters = { "biome", "prettierd", "prettier" }

local function find_config(bufnr, config_files)
	return vim.fs.find(config_files, {
		upward = true,
		stop = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
		path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)),
	})[1]
end

local function biome_or_prettier(bufnr)
	local has_biome_config = find_config(bufnr, { "biome.json", "biome.jsonc" })
	if has_biome_config then
		return { "biome", stop_after_first = true }
	end
	local has_prettier_config = find_config(bufnr, {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.yml",
		".prettierrc.yaml",
		".prettierrc.json5",
		".prettierrc.js",
		".prettierrc.cjs",
		".prettierrc.toml",
		"prettier.config.js",
		"prettier.config.cjs",
	})
	if has_prettier_config then
		return { "prettier", stop_after_first = true }
	end
	-- Default to Prettier if no config is found
	return { "prettier", stop_after_first = true }
end

local filetypes_with_dynamic_formatter = {
	"javascript",
	"javascriptreact",
	"typescript",
	"typescriptreact",
	"vue",
	"css",
	"scss",
	"less",
	"html",
	"json",
	"jsonc",
	"yaml",
	"markdown",
	"markdown.mdx",
	"graphql",
	"handlebars",
}

return {
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local conform = require("conform")

			-- Build the formatters_by_ft table
			local formatters_by_ft = {
				-- Add static formatter configurations
				lua = { "stylua" },
				python = { "isort", "black" },
			}

			-- Add dynamic formatter configurations
			for _, ft in ipairs(filetypes_with_dynamic_formatter) do
				formatters_by_ft[ft] = biome_or_prettier
			end

			conform.setup({
				formatters_by_ft = formatters_by_ft,
				format_on_save = {
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				},
			})

			-- Add keymap for manual formatting
			vim.keymap.set({ "n", "v" }, "<leader>mp", function()
				conform.format({
					lsp_fallback = true,
					async = false,
					timeout_ms = 1000,
				})
			end, { desc = "Format file or range (in visual mode)" })
		end,
	},
}
