local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

-- ============================================
-- プラットフォーム判定
-- ============================================

local is_macos = wezterm.target_triple:find('apple') ~= nil
local is_windows = wezterm.target_triple:find('windows') ~= nil

-- macOS: CMD / Windows: ALT をメインモディファイアとして使用
local mod = is_macos and 'CMD' or 'ALT'
local mod_shift = mod .. '|SHIFT'

-- ============================================
-- 基本設定
-- ============================================

config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  is_macos and 'Menlo' or 'Consolas',
})
config.font_size = 14.0
config.line_height = 1.2

config.color_scheme = 'Catppuccin Mocha'
config.scrollback_lines = 50000

config.use_ime = true
config.audible_bell = 'Disabled'

-- macOS固有設定
if is_macos then
  config.macos_forward_to_ime_modifier_mask = 'SHIFT|CTRL'
  config.macos_window_background_blur = 20
end

-- ============================================
-- ウィンドウ・外観
-- ============================================

config.initial_cols = 200
config.initial_rows = 60
config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.95
config.adjust_window_size_when_changing_font_size = false

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- 非アクティブペインを暗く表示
config.inactive_pane_hsb = {
  saturation = 0.9,
  brightness = 0.7,
}

-- ============================================
-- キーバインド（iTerm2風）
-- macOS: CMD / Windows: ALT
-- ============================================

config.keys = {
  -- ペイン分割
  { key = 'd', mods = mod, action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = 'd', mods = mod_shift, action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'w', mods = mod, action = act.CloseCurrentPane({ confirm = true }) },
  { key = 'Enter', mods = mod_shift, action = act.TogglePaneZoomState },

  -- ペイン移動
  { key = 'LeftArrow', mods = mod .. '|ALT', action = act.ActivatePaneDirection('Left') },
  { key = 'RightArrow', mods = mod .. '|ALT', action = act.ActivatePaneDirection('Right') },
  { key = 'UpArrow', mods = mod .. '|ALT', action = act.ActivatePaneDirection('Up') },
  { key = 'DownArrow', mods = mod .. '|ALT', action = act.ActivatePaneDirection('Down') },

  -- ペインサイズ調整
  { key = 'LeftArrow', mods = mod_shift, action = act.AdjustPaneSize({ 'Left', 5 }) },
  { key = 'RightArrow', mods = mod_shift, action = act.AdjustPaneSize({ 'Right', 5 }) },
  { key = 'UpArrow', mods = mod_shift, action = act.AdjustPaneSize({ 'Up', 5 }) },
  { key = 'DownArrow', mods = mod_shift, action = act.AdjustPaneSize({ 'Down', 5 }) },

  -- タブ管理
  { key = 't', mods = mod, action = act.SpawnTab('CurrentPaneDomain') },
  { key = ']', mods = mod_shift, action = act.ActivateTabRelative(1) },
  { key = '[', mods = mod_shift, action = act.ActivateTabRelative(-1) },

  -- クイックレイアウト: 2分割（左右）
  { key = '2', mods = 'CTRL|SHIFT', action = act.Multiple({
    act.SpawnTab('CurrentPaneDomain'),
    act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  }) },

  -- クイックレイアウト: 3分割（左中右）
  { key = '3', mods = 'CTRL|SHIFT', action = act.Multiple({
    act.SpawnTab('CurrentPaneDomain'),
    act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
    act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
  }) },

  -- クイックレイアウト: 4分割（2×2グリッド）
  { key = '4', mods = 'CTRL|SHIFT', action = act.Multiple({
    act.SpawnTab('CurrentPaneDomain'),
    act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
    act.SplitVertical({ domain = 'CurrentPaneDomain' }),
    act.ActivatePaneDirection('Left'),
    act.SplitVertical({ domain = 'CurrentPaneDomain' }),
  }) },
}

-- Windowsではペイン移動にCTRL+ALT+矢印を使用（ALT+ALTは不可のため）
if is_windows then
  for _, dir_key in ipairs({
    { 'LeftArrow', 'Left' },
    { 'RightArrow', 'Right' },
    { 'UpArrow', 'Up' },
    { 'DownArrow', 'Down' },
  }) do
    table.insert(config.keys, {
      key = dir_key[1], mods = 'CTRL|ALT', action = act.ActivatePaneDirection(dir_key[2]),
    })
  end
end

-- タブ番号で切替（macOS: CMD+1〜9 / Windows: ALT+1〜9）
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = mod,
    action = act.ActivateTab(i - 1),
  })
end

-- ============================================
-- ステータスバー（CWD + Gitブランチ）
-- ============================================

wezterm.on('update-right-status', function(window, pane)
  local cwd = ''
  local cwd_path = '.'
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local file_path = cwd_uri.file_path
    if file_path then
      cwd_path = file_path
      cwd = file_path:gsub('^' .. wezterm.home_dir, '~')
    end
  end

  -- Gitブランチ取得
  local git_branch = ''
  local success, stdout, _ = wezterm.run_child_process({
    'git', '-C', cwd_path, 'rev-parse', '--abbrev-ref', 'HEAD',
  })
  if success then
    git_branch = stdout:gsub('%s+$', '')
  end

  local status_parts = {}
  if git_branch ~= '' then
    table.insert(status_parts, wezterm.format({
      { Foreground = { Color = '#a6e3a1' } },
      { Text = ' ' .. git_branch },
    }))
  end
  if cwd ~= '' then
    table.insert(status_parts, wezterm.format({
      { Foreground = { Color = '#89b4fa' } },
      { Text = ' ' .. cwd .. ' ' },
    }))
  end

  window:set_right_status(table.concat(status_parts, '  '))
end)

-- ============================================
-- 起動時レイアウト（2ペイン分割）
-- ============================================

wezterm.on('gui-startup', function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
  pane:split({ direction = 'Right', size = 0.5 })
end)

return config
