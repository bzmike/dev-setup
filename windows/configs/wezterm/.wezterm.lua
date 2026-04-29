local wezterm = require "wezterm"

local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback {
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
  "Symbols Nerd Font",
}

config.font_size = 12.0
config.color_scheme = "Catppuccin Mocha"

config.term = "xterm-256color"

config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true

config.initial_cols = 120
config.initial_rows = 32

config.default_prog = {
  "wsl.exe",
  "-d",
  "archlinux",
  "--exec",
  "fish",
  "-l",
}

return config