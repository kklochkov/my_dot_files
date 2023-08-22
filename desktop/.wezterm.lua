local wezterm = require 'wezterm';

package.path = package.path .. ';' .. os.getenv('HOME') .. '/develop/my_dot_files/common/wezterm_common.lua'
local wezterm_common = require 'wezterm_common';

wezterm_common.tls_servers = {
  {
    bind_address = '172.16.103.172:29290',
  },
}

return wezterm_common
