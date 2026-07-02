local wezterm = require 'wezterm'

-- This object will hold the configuration
local config = wezterm.config_builder()

-- Custom Earthy Bauhaus Color Palette (Low-saturation, warm natural earth tones)
config.colors = {
  foreground = '#E6DFD3',      -- Warm Sand/Birch Paper
  background = '#1E1B18',      -- Deep Earthy Charcoal/Clay
  cursor_bg = '#C05C46',       -- Muted Terracotta Red cursor
  cursor_fg = '#1E1B18',
  selection_bg = '#5C7285',    -- Slate/Muted Denim Blue selection
  selection_fg = '#E6DFD3',
  scrollbar_thumb = '#C05C46',

  -- Tab bar colors (Earthy tones)
  tab_bar = {
    background = '#1E1B18',
    active_tab = {
      bg_color = '#C05C46',
      fg_color = '#E6DFD3',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#1E1B18',
      fg_color = '#E6DFD3',
    },
    inactive_tab_hover = {
      bg_color = '#5C7285',
      fg_color = '#E6DFD3',
    },
    new_tab = {
      bg_color = '#1E1B18',
      fg_color = '#E6DFD3',
    },
    new_tab_hover = {
      bg_color = '#C29B38',
      fg_color = '#1E1B18',
    },
  },

  -- Custom ANSI Palette (Earthy & Low-Saturation)
  ansi = {
    '#1E1B18', -- black (warm dark clay)
    '#C05C46', -- red (terracotta)
    '#7A8B7B', -- green (sage/olive)
    '#C29B38', -- yellow (ochre)
    '#5C7285', -- blue (slate/denim)
    '#9B7E8C', -- magenta (dusty rose)
    '#6E8A8F', -- cyan (muted eucalyptus)
    '#E6DFD3', -- white (sand)
  },
  brights = {
    '#5C544E', -- bright black (warm grey)
    '#D77B66', -- bright terracotta
    '#9BB09C', -- bright sage
    '#DDB35A', -- bright ochre
    '#7D97AE', -- bright slate
    '#BC9EAC', -- bright dusty rose
    '#8FAEB4', -- bright eucalyptus
    '#F2ECE1', -- bright sand
  }
}

-- Font Settings
config.font_size = 13.0

-- Window Appearance (Opacity 73% with macOS Blur for warm, natural depth)
config.window_background_opacity = 0.73
config.macos_window_background_blur = 15

-- Bauhaus Layout Padding (geometric spacing)
config.window_padding = {
  left = 16,
  right = 16,
  top = 16,
  bottom = 16,
}

-- Tab Bar Customization
config.enable_tab_bar = true
config.use_fancy_tab_bar = false

-- Key Bindings (Command+Delete, Option+Delete, Option+Arrow keys)
config.keys = {
  -- Command + Delete: delete to beginning of line
  { key = 'Backspace', mods = 'CMD', action = wezterm.action.SendKey { key = 'u', mods = 'CTRL' } },
  -- Option + Delete: delete previous word
  { key = 'Backspace', mods = 'OPT', action = wezterm.action.SendKey { key = 'w', mods = 'CTRL' } },
  -- Option + Left Arrow: move cursor backward by one word
  { key = 'LeftArrow', mods = 'OPT', action = wezterm.action.SendString '\x1bb' },
  -- Option + Right Arrow: move cursor forward by one word
  { key = 'RightArrow', mods = 'OPT', action = wezterm.action.SendString '\x1bf' },
  -- Command + Left Arrow: move cursor to beginning of line
  { key = 'LeftArrow', mods = 'CMD', action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' } },
  -- Command + Right Arrow: move cursor to end of line
  { key = 'RightArrow', mods = 'CMD', action = wezterm.action.SendKey { key = 'e', mods = 'CTRL' } },
  -- Shift + Enter: send the CSI u sequence for Shift+Enter so Zsh can intercept it
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\x1b[13;2u' },
  -- CMD + Shift + H: Open TMUX + Wezterm cheatsheet in a new blurred window
  { key = 'h', mods = 'CMD|SHIFT', action = wezterm.action.SpawnCommandInNewWindow { args = { 'bash', '-c', 'bash ~/.config/cheatsheet.sh | less -R' } } },
  -- Ctrl + Shift + C: Open TMUX + Wezterm cheatsheet in a new blurred window
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnCommandInNewWindow { args = { 'bash', '-c', 'bash ~/.config/cheatsheet.sh | less -R' } } },
  -- Ctrl + Shift + P: Restore to default command palette
  { key = 'p', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCommandPalette },
  -- Command + Shift + R: Explicitly force WezTerm to reload configuration, overriding TMUX/CLI capture
  { key = 'r', mods = 'CMD|SHIFT', action = wezterm.action.ReloadConfiguration },
}

-- Bind Command+Click to open links and file paths
config.mouse_bindings = {
  -- Bind 'Up' event of Command-Click to open hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  -- Disable the default 'Down' event of Command-Click so that the cursor does not move
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = wezterm.action.Nop,
  },
}

-- Configure hyperlink rules to detect file paths and lines/columns
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- 1. Match: path/to/file:line:col
table.insert(config.hyperlink_rules, 1, {
  regex = [[(?:^|\s)((?:/|~/|\./|\.\./|[a-zA-Z0-9_.-]+/)[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*):(\d+):(\d+)\b]],
  format = 'file://$1#$2:$3',
})

-- 2. Match: path/to/file:line
table.insert(config.hyperlink_rules, 2, {
  regex = [[(?:^|\s)((?:/|~/|\./|\.\./|[a-zA-Z0-9_.-]+/)[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*):(\d+)\b]],
  format = 'file://$1#$2',
})

-- 3. Match: standard file path
table.insert(config.hyperlink_rules, 3, {
  regex = [[(?:^|\s)((?:/|~/|\./|\.\./|[a-zA-Z0-9_.-]+/)[a-zA-Z0-9_.-]+(?:/[a-zA-Z0-9_.-]+)*)\b]],
  format = 'file://$1',
})

-- Helper to check if file or directory exists
local function exists(p)
  local success, _, _ = wezterm.run_child_process { 'test', '-e', p }
  return success
end

-- Helper to check if a CLI command exists
local function is_command_available(cmd)
  local success, _, _ = wezterm.run_child_process { 'which', cmd }
  return success
end

-- Resolve a path extracted from URI to a full absolute path
local function resolve_path(pane, path)
  -- 1. Handle home directory path
  if path:sub(1, 3) == '/~/' then
    return wezterm.home_dir .. path:sub(3)
  elseif path:sub(1, 2) == '~/' then
    return wezterm.home_dir .. path:sub(2)
  end

  -- 2. If it is already a valid absolute path on the system, return it
  if path:sub(1, 1) == '/' and exists(path) then
    return path
  end

  -- 3. Otherwise, treat it as relative and resolve against pane's working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    local cwd_path
    if type(cwd) == 'userdata' or type(cwd) == 'table' then
      cwd_path = cwd.file_path
    else
      local cwd_str = tostring(cwd)
      if cwd_str:sub(1, 7) == 'file://' then
        local parsed = wezterm.url.parse(cwd_str)
        if parsed then
          cwd_path = parsed.file_path
        end
      else
        cwd_path = cwd_str
      end
    end

    if cwd_path then
      -- Ensure trailing slash
      if cwd_path:sub(-1) ~= '/' then
        cwd_path = cwd_path .. '/'
      end

      -- If path started with a slash (from file:///), strip it
      local rel_path = path
      if rel_path:sub(1, 1) == '/' then
        rel_path = rel_path:sub(2)
      end

      local resolved = cwd_path .. rel_path
      if exists(resolved) then
        return resolved
      end
      -- Return resolved even if it doesn't exist as a fallback
      return resolved
    end
  end

  return path
end

-- Custom open-uri event handler to resolve relative paths and open files in Cursor/VS Code
wezterm.on('open-uri', function(window, pane, uri)
  local url = wezterm.url.parse(uri)
  if url.scheme == 'file' then
    local path = resolve_path(pane, url.file_path)

    -- Parse line and column from fragment
    local line, col = nil, nil
    if url.fragment then
      line, col = url.fragment:match('^(%d+):?(%d*)$')
    end

    -- Skip editor opening for binary media files
    local ext = path:match('%.([^%.]+)$')
    local is_media_or_binary = false
    if ext then
      ext = ext:lower()
      local binary_exts = {
        png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true, svg = true,
        pdf = true, zip = true, tar = true, gz = true, dmg = true, mp3 = true, mp4 = true,
        wav = true, mov = true, avi = true, flac = true, pkg = true, app = true
      }
      if binary_exts[ext] then
        is_media_or_binary = true
      end
    end

    if is_media_or_binary then
      local img_exts = {
        png = true, jpg = true, jpeg = true, gif = true, bmp = true, webp = true
      }
      if img_exts[ext] and not pane:is_alt_screen_active() then
        -- Render the image directly inline in the terminal!
        local quoted_path = "'" .. path:gsub("'", "'\\''") .. "'"
        pane:send_text('wezterm imgcat ' .. quoted_path .. '\n')
        return false
      end
    end

    if not is_media_or_binary then
      local target = path
      if line then
        target = target .. ':' .. line
        if col and col ~= "" then
          target = target .. ':' .. col
        end
      end

      -- Try Cursor first, then VS Code
      if is_command_available('cursor') then
        if line then
          wezterm.run_child_process { 'cursor', '--goto', target }
        else
          wezterm.run_child_process { 'cursor', target }
        end
        return false
      elseif is_command_available('code') then
        if line then
          wezterm.run_child_process { 'code', '--goto', target }
        else
          wezterm.run_child_process { 'code', target }
        end
        return false
      end
    end

    -- Fallback to default system 'open' command
    wezterm.run_child_process { 'open', path }
    return false
  end
end)

-- Global variables to cache network info and prevent UI blocking
local last_ip_check = 0
local cached_local_ip = "Offline"
local cached_wan_ip = "Offline"
local ip_check_interval = 60    -- Refresh LAN IP every 60 seconds
local wan_check_interval = 300   -- Refresh WAN IP every 5 minutes

-- Helper function to safely read cached files
local function read_file_content(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content:gsub("%s+", "") -- strip whitespaces
end

-- WezTerm Right Status Bar (System Info: Hostname, Battery, Time)
wezterm.on('update-right-status', function(window, pane)
  local now = os.time()

  -- 1. Check Local IP (LAN)
  if now - last_ip_check >= ip_check_interval or cached_local_ip == "Offline" then
    -- Determine active default gateway interface dynamically
    local success, stdout, _ = wezterm.run_child_process { 'sh', '-c', 'route -n get default | awk \'/interface: / {print $2}\'' }
    if success and stdout then
      local interface = stdout:gsub("%s+", "")
      if interface ~= "" then
        local ip_success, ip_stdout, _ = wezterm.run_child_process { 'ipconfig', 'getifaddr', interface }
        if ip_success and ip_stdout then
          cached_local_ip = ip_stdout:gsub("%s+", "")
        else
          cached_local_ip = "No LAN"
        end
      end
    else
      cached_local_ip = "Offline"
    end
    last_ip_check = now
  end

  -- 2. Trigger Public IP (WAN) refresh asynchronously in background
  if now - last_ip_check >= wan_check_interval or cached_wan_ip == "Offline" then
    wezterm.run_child_process { 'sh', '-c', 'curl -s --max-time 2 https://icanhazip.com > /tmp/wezterm_wan_ip &' }
  end

  -- Read the background-fetched WAN IP from the temporary cache file
  local wan_from_file = read_file_content("/tmp/wezterm_wan_ip")
  if wan_from_file and wan_from_file ~= "" then
    cached_wan_ip = wan_from_file
  end

  local date = wezterm.strftime('%b %-d %H:%M')
  
  -- Battery Info
  local battery_info = ''
  local batteries = wezterm.battery_info()
  if #batteries > 0 then
    local b = batteries[1]
    local charge = b.state_of_charge * 100
    if b.state == 'Charging' then
      battery_info = string.format('⚡ %.0f%% ', charge)
    else
      battery_info = string.format('🔋 %.0f%% ', charge)
    end
  end

  window:set_right_status(wezterm.format({
    { Background = { Color = '#1E1B18' } },
    { Foreground = { Color = '#7A8B7B' } }, -- Sage green matching your Earthy Bauhaus palette
    { Text = ' 🌐 ' .. cached_local_ip .. ' | ' .. cached_wan_ip .. '  ' },
    { Foreground = { Color = '#5C7285' } },
    { Text = '  ' .. wezterm.hostname() .. '  ' },
    { Foreground = { Color = '#C05C46' } },
    { Text = '  ' .. battery_info .. '  ' },
    { Foreground = { Color = '#C29B38' } },
    { Text = '  ' .. date .. ' ' },
  }))
end)

return config
