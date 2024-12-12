local wezterm = require 'wezterm';
local mux = wezterm.mux

wezterm.on('gui-attached', function(domain)
  local workspace = mux.get_active_workspace()
  local active_screen = wezterm.gui.screens()['active']
  local screen_width = active_screen.width
  local screen_height = active_screen.height
  for _, window in ipairs(mux.all_windows()) do
    if window:get_workspace() == workspace then
      window:gui_window():set_position(screen_width * 0.25, 0)
      window:gui_window():set_inner_size(screen_width * 0.5, screen_height * 0.9)
      window:gui_window():focus()
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
 -- color_scheme = 'Gruvbox (Gogh)',
  color_scheme = 'Gruvbox Dark (Gogh)',
  unix_domains = {
    {
      name = 'unix',
    },
  },
  default_gui_startup_args = { 'connect', 'unix' },
  inactive_pane_hsb = {
    saturation = 1.0,
    brightness = 0.2,
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
    {
      key = 'h',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.SplitHorizontal{domain="CurrentPaneDomain"},
    },
    {
      key = 'v',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.SplitVertical{domain="CurrentPaneDomain"},
    },
    {
      key = 'UpArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.AdjustPaneSize{'Up', 1},
    },
    {
      key = 'DownArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.AdjustPaneSize{'Down', 1},
    },
    {
      key = 'LeftArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.AdjustPaneSize{'Left', 1},
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.AdjustPaneSize{'Right', 1},
    },
  },
  debug_key_events=true,
}

return default_config
