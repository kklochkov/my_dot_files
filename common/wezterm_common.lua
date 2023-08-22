local wezterm = require 'wezterm';
local mux = wezterm.mux

--wezterm.on("update-right-status", function(window, pane)
--  local success, status, stderr = wezterm.run_child_process{"python3", "-u", "/home/kklochkov/develop/my_dot_files/common/my_i3_status.py", "-m", "shell", "-d", "/dev/mapper/vgubuntu-root"}
--  window:set_right_status(status);
--end);

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

wezterm.on('gui-attached', function(domain)
  -- maximize all displayed windows on startup
  local workspace = mux.get_active_workspace()
  for _, window in ipairs(mux.all_windows()) do
    if window:get_workspace() == workspace then
      window:gui_window():maximize()
    end
  end
end)

local default_config = {
  -- https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/DroidSansMono
  font = wezterm.font_with_fallback {
    'DroidSansM Nerd Font Mono',
    'DejaVuSans',
  },
  font_size = 13,
  --color_scheme = 'Gruvbox (Gogh)',
  color_scheme = 'Gruvbox Dark (Gogh)',
  unix_domains = {
    {
      name = 'unix',
    },
  },
  default_gui_startup_args = { 'connect', 'unix' },
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.3,
  },
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },
  window_frame = {
    font = wezterm.font_with_fallback {
      'DroidSansM Nerd Font Mono',
      'DejaVuSans',
    },
    font_size = 12,
  },
  keys = {
    {
      key = 'h',
      mods = 'CTRL|SHIFT|ALT',
      action = wezterm.action.SplitHorizontal{domain="CurrentPaneDomain"},
    },
    {
      key = 'v',
      mods = 'CTRL|SHIFT|ALT',
      action = wezterm.action.SplitVertical{domain="CurrentPaneDomain"},
    },
  },
--  pane_focus_follows_mouse = true, -- if enabled, might lead to high CPU consumption (because of relayouting)
--  status_update_interval = 1000, -- is used with wezterm.on("update-right-status", ...)
  animation_fps = 1, -- save some CPU
}

return default_config
