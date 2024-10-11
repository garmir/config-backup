-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "catppuccin",
	transparency = false,
	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.ui = {
statusline = {
	separator_style = "default",
	order = nil,
	modules = nil,
  },
  colorify = {
	enabled = true,
	mode = "virtual", -- fg, bg, virtual
	virt_text = "󱓻 ",
	highlight = { hex = true, lspvars = true },
  },
  
}

M.nvdash = {
    load_on_startup = true,
    header = {




		" ______     __   __     ______     ______   __  __     ______     __    __     ______    ",
		"/\\  __ \\   /\\ \"-.\\ \\   /\\  __ \\   /\\__  _\\ /\\ \\_\\ \\   /\\  ___\\   /\\ \"-./  \\   /\\  __ \\   ",
		"\\ \\  __ \\  \\ \\ \\-.  \\  \\ \\  __ \\  \\/_/\\ \\/ \\ \\  __ \\  \\ \\  __\\   \\ \\ \\-./\\ \\  \\ \\  __ \\  ",
		" \\ \\_\\ \\_\\  \\ \\_\\\\\"\\_\\  \\ \\_\\ \\_\\    \\ \\_\\  \\ \\_\\ \\_\\  \\ \\_____\\  \\ \\_\\ \\ \\_\\  \\ \\_\\ \\_\\ ",
		"  \\/_/\\/_/   \\/_/ \\/_/   \\/_/\\/_/     \\/_/   \\/_/\\/_/   \\/_____/   \\/_/  \\/_/   \\/_/\\/_/ ",
		"                                                                                         ",
  
	  },
}
return M
