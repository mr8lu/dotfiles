local wezterm = require 'wezterm'

-- This object will hold the configuration
local config = wezterm.config_builder()

-- Use registered custom color scheme
config.color_scheme = 'earthy-bauhaus'

-- Font Settings
config.font_size = 13.0

-- Window Appearance (Opacity 73% with macOS Blur for warm, natural depth)
config.window_background_opacity = 0.73
config.macos_window_background_blur = 15
config.window_decorations = "RESIZE"

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
  -- Command + V: Smart paste that handles images natively for CLI tools like gemini-cli
  {
    key = 'v',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local success, stdout, stderr = wezterm.run_child_process({
        'osascript', '-e', 'clipboard info'
      })
      if success and stdout and (stdout:find('«class PNGf»') or stdout:find('JPEG picture') or stdout:find('TIFF picture') or stdout:find('«class JPEG»') or stdout:find('«class TIFF»')) then
        local timestamp = os.time()
        local temp_path = '/tmp/wezterm-paste-' .. timestamp .. '.png'
        local script = [[
          try
            set imageData to the clipboard as «class PNGf»
            set fileRef to open for access POSIX file "]] .. temp_path .. [[" with write permission
            write imageData to fileRef
            close access fileRef
            return "success"
          on error errMsg
            try
              close access POSIX file "]] .. temp_path .. [["
            end try
            return "error"
          end try
        ]]
        local save_success, save_stdout, save_stderr = wezterm.run_child_process({
          'osascript', '-e', script
        })
        if save_success and save_stdout and save_stdout:find('success') then
          window:perform_action(wezterm.action.SendString('@' .. temp_path), pane)
          return
        end
      end
      window:perform_action(wezterm.action.PasteFrom('Clipboard'), pane)
    end)
  },
}

-- Configure CMD as the bypass modifier so CMD+Click bypasses TMUX mouse reporting and opens links directly
config.bypass_mouse_reporting_modifiers = 'CMD'

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

-- Global variables to cache network & system info and prevent UI blocking
local last_ip_check = 0
local cached_local_ip = "Offline"
local cached_wan_ip = "Offline"
local ip_check_interval = 60    -- Refresh LAN IP every 60 seconds
local wan_check_interval = 300  -- Refresh WAN IP every 5 minutes

local last_stats_check = 0
local stats_check_interval = 5  -- Refresh Stats every 5 seconds
local cached_cpu = "--"
local cached_mem = "--"
local cached_disk = "--"

-- Helper function to safely read single-line cached files (strips whitespace)
local function read_file_content(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*all")
  file:close()
  return content:gsub("%s+", "")
end

-- Helper function to read multi-line stats file
local function read_stats_file(path)
  local file = io.open(path, "r")
  if not file then return nil, nil, nil end
  local line1 = file:read("*l")
  local disk = file:read("*l")
  file:close()
  
  local cpu = nil
  local mem = nil
  if line1 then
    cpu, mem = line1:match("^(%S+)%s+(.+)$")
  end
  
  return cpu, mem, disk
end

-- WezTerm Right Status Bar (System Info: CPU, Mem, Disk, Hostname, Battery, Time)
wezterm.on('update-right-status', function(window, pane)
  local now = os.time()

  -- 1. Check Local IP (LAN)
  if now - last_ip_check >= ip_check_interval or cached_local_ip == "Offline" then
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

  local wan_from_file = read_file_content("/tmp/wezterm_wan_ip")
  if wan_from_file and wan_from_file ~= "" then
    cached_wan_ip = wan_from_file
  end

  -- 3. Trigger CPU/Mem/Disk refresh asynchronously in background
  if now - last_stats_check >= stats_check_interval then
    local stats_cmd = [[top -l 1 | awk 'BEGIN { "sysctl -n hw.memsize" | getline bytes; total = sprintf("%.0fG", bytes/1024/1024/1024) } /CPU usage/ {cpu=$3} /PhysMem/ {mem=$2 "/" total " (" $(NF-1) " free)"} END {print cpu " " mem}' > /tmp/wezterm_stats; df -h / | awk 'NR==2 {print $5 " " $4}' >> /tmp/wezterm_stats &]]
    wezterm.run_child_process { 'sh', '-c', stats_cmd }
    last_stats_check = now
  end

  local cpu, mem, disk = read_stats_file("/tmp/wezterm_stats")
  if cpu then cached_cpu = cpu end
  if mem then cached_mem = mem end
  if disk then cached_disk = disk end

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
    { Foreground = { Color = '#C29B38' } }, -- Ochre
    { Text = ' 🖥️ CPU: ' .. cached_cpu .. ' | 🐏 ' .. cached_mem .. ' | 💾 ' .. cached_disk .. ' ' },
    { Foreground = { Color = '#7A8B7B' } }, -- Sage green
    { Text = ' 🌐 ' .. cached_local_ip .. ' | ' .. cached_wan_ip .. '  ' },
    { Foreground = { Color = '#5C7285' } }, -- Slate Blue
    { Text = '  ' .. wezterm.hostname() .. '  ' },
    { Foreground = { Color = '#C05C46' } }, -- Terracotta red
    { Text = '  ' .. battery_info .. '  ' },
    { Foreground = { Color = '#C29B38' } }, -- Ochre
    { Text = '  ' .. date .. ' ' },
  }))
end)

return config
