local M = {}

-- Resolve the absolute path to the plugin's bin/ directory.
local function plugin_root()
  local src = debug.getinfo(1, "S").source
  local lua_file = src:sub(2)                            -- strip leading "@"
  local lua_dir  = vim.fn.fnamemodify(lua_file, ":p:h")  -- .../lua/code-preview/backends
  return vim.fn.fnamemodify(lua_dir, ":h:h:h")
end

-- Path to Gemini CLI adapter scripts
local function scripts_dir()
  return plugin_root() .. "/backends/geminicli"
end

local HOOK_MARKER = "code-preview"

local function settings_path()
  return vim.fn.getcwd() .. "/.gemini/settings.json"
end

local function read_settings(path)
  local f = io.open(path, "r")
  if not f then return {} end
  local raw = f:read("*a")
  f:close()
  if raw == "" then return {} end
  local ok, data = pcall(vim.json.decode, raw)
  return ok and data or {}
end

local function write_settings(path, data)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = assert(io.open(path, "w"), "Cannot write to " .. path)
  f:write(vim.json.encode(data))
  f:close()
end

local function remove_ours(list)
  local filtered = {}
  if not list then return filtered end
  for _, entry in ipairs(list) do
    local is_ours = false
    if entry.hooks then
      for _, hook in ipairs(entry.hooks) do
        if hook.command and hook.command:find(HOOK_MARKER, 1, true) then
          is_ours = true
          break
        end
      end
    end
    if not is_ours then
      table.insert(filtered, entry)
    end
  end
  return filtered
end

function M.install()
  local dir = scripts_dir()
  local pre_hook  = dir .. "/gemini-pre-hook.sh"
  local post_hook = dir .. "/gemini-post-hook.sh"

  if vim.fn.filereadable(pre_hook) == 0 then
    vim.notify("[code-preview] Gemini pre-hook not found: " .. pre_hook, vim.log.levels.ERROR)
    return
  end

  local path = settings_path()
  local data = read_settings(path)

  data.hooks = data.hooks or {}
  data.hooks.BeforeTool = remove_ours(data.hooks.BeforeTool or {})
  data.hooks.AfterTool  = remove_ours(data.hooks.AfterTool or {})

  table.insert(data.hooks.BeforeTool, {
    matcher = "replace|write_file|run_shell_command",
    hooks   = { { type = "command", command = pre_hook, name = HOOK_MARKER } },
  })
  table.insert(data.hooks.AfterTool, {
    matcher = "replace|write_file|run_shell_command",
    hooks   = { { type = "command", command = post_hook, name = HOOK_MARKER } },
  })

  write_settings(path, data)
  vim.notify("[code-preview] Gemini CLI hooks installed -> " .. path, vim.log.levels.INFO)
end

function M.uninstall()
  local path = settings_path()
  local data = read_settings(path)

  if not data.hooks then
    vim.notify("[code-preview] No hooks found in " .. path, vim.log.levels.WARN)
    return
  end

  data.hooks.BeforeTool = remove_ours(data.hooks.BeforeTool or {})
  data.hooks.AfterTool  = remove_ours(data.hooks.AfterTool or {})

  write_settings(path, data)
  vim.notify("[code-preview] Gemini CLI hooks removed from " .. path, vim.log.levels.INFO)
end

return M
