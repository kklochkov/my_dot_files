local wezterm = require 'wezterm';

package.path = package.path .. ';' .. os.getenv('HOME') .. '/develop/my_dot_files/common/wezterm_common.lua'
local wezterm_common = require 'wezterm_common';

wezterm_common.ssh_domains = {
  {
    name = 'nullptr-bbox-ssh',
    remote_address = '192.168.178.54',
    username = 'nullptr',
  },
}

wezterm_common.tls_clients = {
  {
    name = 'nullptr-bbox-tls',
    remote_address = 'nullptr-bbox:29290',
    bootstrap_via_ssh = 'nullptr@nullptr-bbox',
  },
}

return wezterm_common
