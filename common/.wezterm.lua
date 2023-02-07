local wezterm = require 'wezterm';

wezterm.on("update-right-status", function(window, pane)
      local success, data, stderr = wezterm.run_child_process({
        "python3", "/Users/nullptr/develop/my_dot_files/common/my_i3_status.py",
        "-m", "shell",
        "-d", "/dev/disk3s1s1",
        "-d", "/dev/disk3s5"
      });
      window:set_right_status(data);
end);

return {
  font = wezterm.font 'DroidSansMono Nerd Font',
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
  status_update_interval = 10000, -- every 10 seconds
  window_frame = {
    font = wezterm.font {
      family = 'DroidSansMono Nerd Font',
    },
    font_size = 10,
  },
}
