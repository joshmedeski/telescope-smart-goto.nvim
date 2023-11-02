local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local harpoon = require("harpoon")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")
local utils = require("telescope.utils")

---@class SmartGoToEntry
---@field filename string
---@field row string
---@field col string
---@field index number
---@field type string "buffer" | "harpoon"

---@return SmartGoToEntry[]
local function get_harpoon_results()
	local harpoon_marks = harpoon.get_mark_config().marks
	local harpoon_entries = {}
	for idx = 1, #harpoon_marks do
		if harpoon_marks[idx].filename ~= "" then
			harpoon_marks[idx].index = idx
			table.insert(harpoon_entries, {
				type = "harpoon",
				filename = harpoon_marks[idx].filename,
				row = harpoon_marks[idx].row,
				col = harpoon_marks[idx].col,
				index = harpoon_marks[idx].index,
			})
		end
	end
	return harpoon_entries
end

---@return SmartGoToEntry[]|nil
local function get_buffer_results(opts)
	local bufnrs = vim.api.nvim_list_bufs()
	if not next(bufnrs) then
		return
	end

	if opts.sort_mru then
		table.sort(bufnrs, function(a, b)
			return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
		end)
	end

	local buffers = {}

	for _, bufnr in ipairs(bufnrs) do
		if vim.api.nvim_buf_is_loaded(bufnr) == false then
			goto continue
		end

		local buffer_info = vim.fn.getbufinfo(bufnr)[1]

		if vim.fn.filereadable(buffer_info.name) == 0 then
			goto continue
		end

		table.insert(buffers, {
			type = "buffer",
			filename = buffer_info.name,
			row = buffer_info.lnum,
			col = 0,
			index = bufnr,
		})

		::continue::
	end

	-- TODO: is this causing the bug?????? 🐛🖕
	-- if not opts.bufnr_width then
	-- 	local max_bufnr = math.max(unpack(bufnrs))
	-- 	opts.bufnr_width = #tostring(max_bufnr)
	-- end

	return buffers
end

local function smart_goto_finder(opts)
	opts = opts or {}
	local results = vim.tbl_deep_extend("force", get_buffer_results(opts), get_harpoon_results())
	return finders.new_table({
		---@return SmartGoToEntry[]
		results = results,
		entry_maker = function(entry)
			-- TODO: pass line into smart icon function?
			local displayer = entry_display.create({
				separator = " ",
				items = {
					{ width = 2 },
					{ width = 5 },
					{ remaining = true },
				},
			})
			local function get_icon(type)
				if type == "harpoon" then
					return "󰛢"
				elseif type == "buffer" then
					return "󰕸"
				end
			end

			local function get_pretty_file_path(entry)
				local hl_group, icon
				local display = utils.transform_path(opts, entry.filename)
				display, hl_group, icon = utils.transform_devicons(entry.filename, display, opts.disable_devicons)
				if hl_group then
					return display, { { { 0, #icon }, hl_group } }
				else
					return display
				end
			end

			local line = get_pretty_file_path(entry)

			local make_display = function()
				return displayer({
					get_icon(entry.type),
					tostring(entry.index),
					line,
				})
			end

			return {
				value = entry,
				ordinal = line,
				display = make_display,
				lnum = entry.row,
				col = entry.col,
				filename = entry.filename,
			}
		end,
	})
end

local function smart_goto_picker(opts)
	opts = opts or {}
	opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

	pickers
		.new(opts, {
			prompt_title = "Smart Goto",
			finder = smart_goto_finder(),
			sorter = conf.generic_sorter(opts),
			previewer = conf.grep_previewer(opts),
			-- attach_mappings = function()
			-- 	return true
			-- end,
		})
		:find()
end

-- NOTE: uncomment this out for debugging
-- Run `source %` in nvim to reload this file and automatically run the picker
-- smart_goto_picker()

return smart_goto_picker
