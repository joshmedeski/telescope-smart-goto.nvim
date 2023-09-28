local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local harpoon = require("harpoon")
local make_entry = require("telescope.make_entry")
local pickers = require("telescope.pickers")

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

local filter = vim.tbl_filter

---@return SmartGoToEntry[]
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
	local default_selection_idx = 1
	for _, bufnr in ipairs(bufnrs) do
		local flag = bufnr == vim.fn.bufnr("") and "%" or (bufnr == vim.fn.bufnr("#") and "#" or " ")

		if opts.sort_lastused and not opts.ignore_current_buffer and flag == "#" then
			default_selection_idx = 2
		end

		local buffer_info = vim.fn.getbufinfo(bufnr)[1]

		local buffer_entry = {
			type = "buffer",
			filename = buffer_info.name,
			row = buffer_info.lnum,
			col = 0,
			index = bufnr,
		}

		if buffer_entry.filename and buffer_entry.filename ~= "" then
			table.insert(buffers, buffer_entry)
		end
		-- 	local idx = ((buffers[1] ~= nil and buffers[1].flag == "%") and 2 or 1)
		-- if opts.sort_lastused and (flag == "#" or flag == "%") then
		-- 	table.insert(buffers, idx, buffer_entry)
		-- else
		-- table.insert(buffers, buffer_entry)
		-- end
	end

	if not opts.bufnr_width then
		local max_bufnr = math.max(unpack(bufnrs))
		opts.bufnr_width = #tostring(max_bufnr)
	end

	return buffers
end

local function smart_goto_finder(opts)
	opts = opts or {}
	return finders.new_table({
		-- TODO: normalize and merge
		---@return SmartGoToEntry[]
		results = vim.tbl_deep_extend("force", get_buffer_results(opts), get_harpoon_results()),
		entry_maker = function(entry)
			-- TODO: pass line into smart icon function?
			local line = entry.filename .. ":" .. entry.row .. ":" .. entry.col
			local displayer = entry_display.create({
				separator = " ",
				items = {
					{ width = 2 },
					{ width = 5 },
					{ width = 50 },
					{ remaining = true },
				},
			})
			local function get_icon(type)
				if type == "harpoon" then
					return "󰛢 "
				elseif type == "buffer" then
					return "󰕸 "
				end
			end

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

smart_goto_picker()
