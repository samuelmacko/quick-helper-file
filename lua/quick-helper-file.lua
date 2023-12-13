-- utility functions

local function write_to_file(file_name, lines)
  local f = io.open(file_name, "w")
  if f ~= nil then
    for _, l in pairs(lines) do
      f:write(l .. "\n")
    end
    f:close()
  end
end

local function file_exists(file_name)
  local f = io.open(file_name, "rb")
  if f then f:close() end
  return f ~= nil
end

local function create_file(file_name)
  local f = io.open(file_name, "w")
  if f ~= nil then
    f:close()
  end
end

-- -- returns full file path to the project root
-- local function full_path(file_name)
--   return io.popen"pwd":read'*l' .. "/" .. file_name
-- end

local M = {}

M.cfg = {}

function M.setup(opts)
  opts = opts or {}

  -- TODO: add settings for custom dir and name file
  -- if opts.file_name then
  --     M.cfg.file_path = full_path(opts.file_name)
  -- else
  --   -- default file path
  --   M.cfg.file_path = full_path(".helper_file")
  -- end

  M.cfg.file_path = vim.fn.stdpath("data") .. "/filters/" .. vim.fn.getcwd():gsub("/", "%%")
end

-- shows editable window to edit the content of the helper file
-- exit with ':q' - no need to save ':w'
function M._edit_helper_file()

  local Popup = require("nui.popup")
  local event = require("nui.utils.autocmd").event

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
    },
    position = "50%",
    size = {
      width = "40%",
      height = "20%",
    },
  })

  popup:mount()

  -- unmounts component when cursor leaves buffer
  popup:on(event.BufLeave, function()
    local l = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)

    -- writes the content of the buffer to the helper file
    write_to_file(M.cfg.file_path, l)

    popup:unmount()
  end)

  -- fill buffer with the loaded lines
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, M._lines)

end

-- loads lines from the helper file to M._lines
-- if helper file does not exist then loads an empty table - M._lines = {}
function M._load_lines()
  if not file_exists(M.cfg.file_path) then
    M._lines = {}
    return
  end

  local lines = {}
  for line in io.lines(M.cfg.file_path) do
    -- ignores commented out or empty lines
    -- comment is prefixed with '--'
    if line:sub(2, 2) ~= "--" and line ~= "" then
      lines[#lines + 1] = line
    end
  end

  M._lines = lines
end

-- sets M._lines to nil
function M._unload_files()
  M._lines = nil
end

-- lines loaded from the helper file
M._lines = nil

-- if M._lines is loaded with lines from the helper file, then return M._lines
-- if M._lines is not loaded, then load it first and then return M._lines
-- this is so the helper file does not need to be opened and read every time a user wants to get lines from it
function M.read_lines()
  if not M._lines then M._load_lines() end
  return M._lines
end

-- creates a helper file if it doesn't exist and opens an editing window
function M.helper_file_edit()

  -- load lines if needed
  if not M._lines then M._load_lines() end

  if not file_exists(M.cfg.file_path) then create_file(M.cfg.file_path) end
  M._edit_helper_file()

  -- M._lines is set to nil after the content of the helper file has been modified
  -- M._load_lines() will populate it again
  M._unload_files()
end

return M
