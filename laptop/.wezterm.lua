local wezterm = require 'wezterm';

package.path = package.path .. ';' .. os.getenv('HOME') .. '/develop/my_dot_files/common/wezterm_common.lua'
local wezterm_common = require 'wezterm_common';

wezterm_common.ssh_domains = {
  {
    name = 'kklochkov-bbox-ssh',
    remote_address = 'kklochkov-bbox',
    username = 'kklochkov',
  },
}

wezterm_common.tls_clients = {
  {
    name = 'kklochkov-bbox-tls',
    remote_address = 'tw-0023:29290',
    bootstrap_via_ssh = 'kklochkov@kklochkov-bbox',
  },
}

return wezterm_common
