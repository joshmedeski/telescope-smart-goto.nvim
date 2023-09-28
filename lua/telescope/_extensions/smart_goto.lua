local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
	error("telescope-smart-goto.nvim requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
	exports = { ["smart_goto"] = require("smart_goto.picker") },
})
