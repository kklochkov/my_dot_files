local wezterm = require 'wezterm';

--wezterm.on("update-right-status", function(window, pane)
--  local success, status, stderr = wezterm.run_child_process{"python3", "-u", "/home/kklochkov/develop/my_dot_files/common/my_i3_status.py", "-m", "shell", "-d", "/dev/mapper/vgubuntu-root"}
--  window:set_right_status(status);
--end);

return {
  -- https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/DroidSansMono
  font = wezterm.font_with_fallback {
    'DroidSansM Nerd Font Mono',
    'DejaVuSans',
  },
  font_size = 12,
  color_scheme = "Monokai Soda",
  unix_domains = {
    {
      name = 'unix',
    },
  },
  default_gui_startup_args = { 'connect', 'unix' },
  ssh_domains = {
    {
      name = 'kklochkov-bbox',
      remote_address = 'kklochkov-bbox',
      username = 'kklochkov',
    },
  },
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
    font_size = 10,
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
  pane_focus_follows_mouse = true,
}
