local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

-- ============================================
-- プラットフォーム判定
-- ============================================

local is_macos = wezterm.target_triple:find('apple') ~= nil
local is_windows = wezterm.target_triple:find('windows') ~= nil
local homebrew_bin = '/opt/homebrew/bin'

-- macOS: CMD / Windows: ALT をメインモディファイアとして使用
local mod = is_macos and 'CMD' or 'ALT'
local mod_shift = mod .. '|SHIFT'

-- ============================================
-- 開発リポジトリ一括切替
-- ============================================

local function shell_quote(value)
  return "'" .. value:gsub("'", [['"'"']]) .. "'"
end

local function basename(path)
  if not path or path == '' then
    return ''
  end

  return path:gsub('(.*[/\\])(.*)', '%2')
end

local function is_shell_process(process_name)
  if not process_name or process_name == '' then
    return true
  end

  local name = basename(process_name):lower()
  local shell_names = {
    ['sh'] = true,
    ['bash'] = true,
    ['zsh'] = true,
    ['fish'] = true,
    ['nu'] = true,
    ['pwsh'] = true,
    ['powershell'] = true,
    ['cmd.exe'] = true,
  }

  return shell_names[name] == true
end

local function get_repo_choices()
  local ghq_cmd = is_macos and homebrew_bin .. '/ghq' or 'ghq'
  local root_ok, root_stdout, root_stderr = wezterm.run_child_process({ ghq_cmd, 'root' })
  if not root_ok then
    local message = root_stderr ~= '' and root_stderr:gsub('%s+$', '') or 'ghq root の取得に失敗'
    return nil, message
  end

  local list_ok, list_stdout, list_stderr = wezterm.run_child_process({ ghq_cmd, 'list' })
  if not list_ok then
    local message = list_stderr ~= '' and list_stderr:gsub('%s+$', '') or 'ghq list の取得に失敗'
    return nil, message
  end

  local root = root_stdout:gsub('%s+$', '')
  local choices = {}
  for repo in list_stdout:gmatch('[^\r\n]+') do
    local trimmed = repo:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed ~= '' then
      table.insert(choices, {
        id = root .. '/' .. trimmed,
        label = trimmed,
      })
    end
  end

  if #choices == 0 then
    return nil, 'ghq 管理下のリポジトリが見つからない'
  end

  return choices, nil
end

local function show_repo_switch_result(window, label, changed, skipped)
  local message
  if changed == 0 then
    message = '切替対象のシェルペインなし'
  elseif skipped == 0 then
    message = '全シェルペインを ' .. label .. ' に切替'
  else
    message = string.format('%dペイン切替 / %dペインは送信対象外', changed, skipped)
  end

  window:toast_notification('WezTerm', message, nil, 2500)
end

local function broadcast_cd_to_active_tab(window, path)
  local mux_window = window:mux_window()
  if not mux_window then
    return 0, 0
  end

  local active_tab = mux_window:active_tab()
  if not active_tab then
    return 0, 0
  end

  local command = 'cd -- ' .. shell_quote(path) .. '\n'
  local changed = 0
  local skipped = 0
  for _, pane_info in ipairs(active_tab:panes_with_info()) do
    local process_name = pane_info.pane:get_foreground_process_name()
    if pane_info.is_alt_screen_active or not is_shell_process(process_name) then
      skipped = skipped + 1
    else
      window:perform_action(act.SendString(command), pane_info.pane)
      window:perform_action(act.SendKey({ key = 'l', mods = 'CTRL' }), pane_info.pane)
      changed = changed + 1
    end
  end

  return changed, skipped
end

local function relayout_current_tab(window, pane, layout)
  local tab = pane:tab()
  if not tab then
    return
  end

  local active_pane = pane
  local extra_panes = {}
  for _, pane_info in ipairs(tab:panes_with_info()) do
    if pane_info.pane:pane_id() ~= active_pane:pane_id() then
      table.insert(extra_panes, pane_info.pane)
    end
  end

  for _, extra_pane in ipairs(extra_panes) do
    extra_pane:activate()
    window:perform_action(act.CloseCurrentPane({ confirm = false }), extra_pane)
  end

  active_pane:activate()

  if layout == 2 then
    active_pane:split({ direction = 'Right', size = 0.5 })
    return
  end

  if layout == 3 then
    local second_pane = active_pane:split({ direction = 'Right', size = 0.5 })
    active_pane:split({ direction = 'Right', size = 0.5 })
    second_pane:activate()
    return
  end

  if layout == 4 then
    local right_pane = active_pane:split({ direction = 'Right', size = 0.5 })
    active_pane:split({ direction = 'Bottom', size = 0.5 })
    right_pane:split({ direction = 'Bottom', size = 0.5 })
  end
end

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

if is_macos then
  config.set_environment_variables = {
    PATH = homebrew_bin .. ':' .. (os.getenv('PATH') or ''),
  }
end

-- macOS固有設定
if is_macos then
  config.macos_forward_to_ime_modifier_mask = 'SHIFT'
  config.macos_window_background_blur = 20
end

-- ============================================
-- ウィンドウ・外観
-- ============================================

config.initial_cols = 200
config.initial_rows = 60
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.window_background_opacity = 0.95
config.adjust_window_size_when_changing_font_size = false

config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- タブバーを常に表示（ステータスバーはここに表示される）
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false

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
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.EmitEvent('choose-dev-repo-for-tab') },
  { key = 'w', mods = 'CTRL|ALT', action = act.EmitEvent('choose-dev-repo-for-tab') },

  -- クイックレイアウト: 2分割（左右）
  { key = '2', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 2)
  end) },
  { key = '2', mods = 'CTRL|ALT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 2)
  end) },

  -- クイックレイアウト: 3分割（左中右）
  { key = '3', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 3)
  end) },
  { key = '3', mods = 'CTRL|ALT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 3)
  end) },

  -- クイックレイアウト: 4分割（2×2グリッド）
  { key = '4', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 4)
  end) },
  { key = '4', mods = 'CTRL|ALT', action = wezterm.action_callback(function(window, pane)
    relayout_current_tab(window, pane, 4)
  end) },
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

wezterm.on('choose-dev-repo-for-tab', function(window, pane)
  local choices, err = get_repo_choices()
  if not choices then
    window:toast_notification('WezTerm', err, nil, 4000)
    return
  end

  window:perform_action(
    act.InputSelector({
      title = 'Switch Repos For All Panes',
      description = '現在のタブ内の全ペインを同じリポジトリへ移動',
      fuzzy = true,
      choices = choices,
      action = wezterm.action_callback(function(inner_window, _, id, label)
        if not id then
          return
        end

        local changed, skipped = broadcast_cd_to_active_tab(inner_window, id)
        show_repo_switch_result(inner_window, label, changed, skipped)
      end),
    }),
    pane
  )
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
