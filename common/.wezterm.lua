local wezterm = require 'wezterm';

return {
  -- https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete%20Mono.otf
  font = wezterm.font 'DroidSansMono Nerd Font Mono',
  font_size = 12,
  color_scheme = "Monokai Soda",
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
    font = wezterm.font {
      family = 'DroidSansMono Nerd Font Mono',
    },
    font_size = 10,
  },
}
