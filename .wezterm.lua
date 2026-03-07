local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Graphite 테마 정의 (Graphite-gtk-theme CSS에서 추출)
local themes = {
  ['Graphite-Light'] = {
    colors = {
      foreground = '#303030',
      background = '#FFFFFF',
      cursor_bg = '#333333',
      cursor_fg = '#FFFFFF',
      cursor_border = '#333333',
      selection_bg = '#333333',
      selection_fg = '#ffffff',
      ansi = {
        '#2C2C2C', -- black
        '#C62828', -- red (진한 빨강, 흰 배경에서 선명)
        '#2E7D32', -- green (진한 초록)
        '#F57F17', -- yellow (진한 노랑/오렌지, 흰 배경에서 가독성)
        '#1565C0', -- blue (진한 파랑)
        '#7B1FA2', -- magenta (진한 보라)
        '#00838F', -- cyan (진한 청록)
        '#757575', -- white (밝은 회색)
      },
      brights = {
        '#9E9E9E', -- bright black
        '#D93025', -- bright red
        '#0F9D58', -- bright green
        '#F4B400', -- bright yellow
        '#1976D2', -- bright blue
        '#8E24AA', -- bright magenta
        '#00ACC1', -- bright cyan
        '#FAFAFA', -- bright white
      },
      tab_bar = {
        background = '#F2F2F2',
        active_tab = { bg_color = '#FFFFFF', fg_color = '#303030' },
        inactive_tab = { bg_color = '#F2F2F2', fg_color = '#707070' },
        inactive_tab_hover = { bg_color = '#FAFAFA', fg_color = '#303030' },
        new_tab = { bg_color = '#F2F2F2', fg_color = '#707070' },
        new_tab_hover = { bg_color = '#FAFAFA', fg_color = '#303030' },
      },
    },
    frame = { active_titlebar_bg = '#F2F2F2', inactive_titlebar_bg = '#F2F2F2' },
  },
  ['Graphite-Dark'] = {
    colors = {
      foreground = '#E0E0E0',
      background = '#2C2C2C',
      cursor_bg = '#E0E0E0',
      cursor_fg = '#2C2C2C',
      cursor_border = '#E0E0E0',
      selection_bg = '#E0E0E0',
      selection_fg = '#2C2C2C',
      ansi = {
        '#2C2C2C', -- black
        '#F28B82', -- red
        '#81C995', -- green
        '#FDD633', -- yellow
        '#8AB4F8', -- blue
        '#C58AF9', -- magenta
        '#78D9EC', -- cyan
        '#E0E0E0', -- white
      },
      brights = {
        '#6e6e6e', -- bright black
        '#F28B82', -- bright red
        '#81C995', -- bright green
        '#FDD633', -- bright yellow
        '#AECBFA', -- bright blue
        '#D7AEFB', -- bright magenta
        '#A1E4F0', -- bright cyan
        '#F5F5F5', -- bright white
      },
      tab_bar = {
        background = '#212121',
        active_tab = { bg_color = '#2C2C2C', fg_color = '#E0E0E0' },
        inactive_tab = { bg_color = '#212121', fg_color = '#6b6b6b' },
        inactive_tab_hover = { bg_color = '#242424', fg_color = '#E0E0E0' },
        new_tab = { bg_color = '#212121', fg_color = '#6b6b6b' },
        new_tab_hover = { bg_color = '#242424', fg_color = '#E0E0E0' },
      },
    },
    frame = { active_titlebar_bg = '#212121', inactive_titlebar_bg = '#212121' },
  },
}

-- 테마 상태 파일 경로
local theme_state_file = wezterm.home_dir .. '/.wezterm-theme'

local function read_theme()
  local f = io.open(theme_state_file, 'r')
  if f then
    local name = f:read('*l')
    f:close()
    if themes[name] then return name end
  end
  return 'Graphite-Light'
end

local function write_theme(name)
  local f = io.open(theme_state_file, 'w')
  if f then f:write(name); f:close() end
end

local current_theme = read_theme()
local t = themes[current_theme]

config.colors = t.colors

-- 비활성 패널 색상 유지 (회색 처리 방지)
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 1.0,
}

config.font = wezterm.font('Ubuntu Sans Mono')
config.font_size = 13.0
config.window_background_opacity = 0.95
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_frame = {
  font = wezterm.font('Ubuntu Sans', { weight = 'Bold' }),
  font_size = 11.0,
  active_titlebar_bg = t.frame.active_titlebar_bg,
  inactive_titlebar_bg = t.frame.inactive_titlebar_bg,
}

local act = wezterm.action

-- Equalize panes (based on curbol's implementation)
local function build_tree(ps)
  if #ps == 1 then
    return { type = 'pane', pane = ps[1], width = ps[1].width, height = ps[1].height }
  end
  local xs = {}
  for _, p in ipairs(ps) do xs[p.left + p.width] = true end
  local xs_sorted = {}
  for x in pairs(xs) do table.insert(xs_sorted, x) end
  table.sort(xs_sorted)
  for _, x in ipairs(xs_sorted) do
    local lp, rp = {}, {}
    for _, p in ipairs(ps) do
      if p.left + p.width <= x then table.insert(lp, p)
      elseif p.left >= x then table.insert(rp, p) end
    end
    if #lp + #rp == #ps and #lp > 0 and #rp > 0 then
      local lc, rc = build_tree(lp), build_tree(rp)
      return { type = 'vsplit', left_child = lc, right_child = rc,
        width = lc.width + rc.width, height = lc.height }
    end
  end
  local ys = {}
  for _, p in ipairs(ps) do ys[p.top + p.height] = true end
  local ys_sorted = {}
  for y in pairs(ys) do table.insert(ys_sorted, y) end
  table.sort(ys_sorted)
  for _, y in ipairs(ys_sorted) do
    local tp, bp = {}, {}
    for _, p in ipairs(ps) do
      if p.top + p.height <= y then table.insert(tp, p)
      elseif p.top >= y then table.insert(bp, p) end
    end
    if #tp + #bp == #ps and #tp > 0 and #bp > 0 then
      local tc, bc = build_tree(tp), build_tree(bp)
      return { type = 'hsplit', top_child = tc, bot_child = bc,
        width = tc.width, height = tc.height + bc.height }
    end
  end
  return { type = 'pane', pane = ps[1], width = ps[1].width, height = ps[1].height }
end

local function collect_panes(node, out)
  out = out or {}
  if node.type == 'pane' then table.insert(out, node.pane)
  elseif node.type == 'vsplit' then collect_panes(node.left_child, out); collect_panes(node.right_child, out)
  elseif node.type == 'hsplit' then collect_panes(node.top_child, out); collect_panes(node.bot_child, out)
  end
  return out
end

local function far_pane(node)
  if node.type == 'pane' then return node.pane end
  if node.type == 'vsplit' then return far_pane(node.right_child) end
  return far_pane(node.bot_child)
end

local function count_cols(node)
  if node.type == 'vsplit' then return count_cols(node.left_child) + count_cols(node.right_child) end
  return 1
end

local function count_rows(node)
  if node.type == 'hsplit' then return count_rows(node.top_child) + count_rows(node.bot_child) end
  return 1
end

local function snapshot(tab)
  local s = {}
  for _, pi in ipairs(tab:panes_with_info()) do s[pi.index] = { width = pi.width, height = pi.height } end
  return s
end

local function probe(window, tab, cand_idx, pos_dir, neg_dir, prop, verify_idx)
  local before = snapshot(tab)
  window:perform_action(act.ActivatePaneByIndex(cand_idx), tab:active_pane())
  window:perform_action(act.AdjustPaneSize({ pos_dir, 1 }), tab:active_pane())
  local after = snapshot(tab)
  local cd = after[cand_idx][prop] - before[cand_idx][prop]
  local vd = after[verify_idx][prop] - before[verify_idx][prop]
  window:perform_action(act.AdjustPaneSize({ neg_dir, 1 }), tab:active_pane())
  if cd ~= 0 and vd ~= 0 and cd ~= vd then return cd > 0 and 'grow' or 'shrink' end
  return nil
end

local function try_adjust(window, tab, candidates, delta, pos_dir, neg_dir, prop)
  for _, c in ipairs(candidates) do
    local result = probe(window, tab, c.index, pos_dir, neg_dir, prop, c.verify)
    if result then
      window:perform_action(act.ActivatePaneByIndex(c.index), tab:active_pane())
      local grow = (c.side == 'left') == (result == 'grow')
      if grow then
        if delta > 0 then window:perform_action(act.AdjustPaneSize({ pos_dir, delta }), tab:active_pane())
        else window:perform_action(act.AdjustPaneSize({ neg_dir, -delta }), tab:active_pane()) end
      else
        if delta > 0 then window:perform_action(act.AdjustPaneSize({ neg_dir, delta }), tab:active_pane())
        else window:perform_action(act.AdjustPaneSize({ pos_dir, -delta }), tab:active_pane()) end
      end
      return true
    end
  end
  return false
end

local function equalize_tab(window)
  local tab = window:active_tab()
  local initial_panes = tab:panes_with_info()
  if #initial_panes <= 1 then return end
  local active_idx = 0
  for _, pi in ipairs(initial_panes) do
    if pi.is_active then active_idx = pi.index end
  end
  for _ = 1, #initial_panes - 1 do
    local ps = tab:panes_with_info()
    local tree = build_tree(ps)
    local queue = { tree }
    local adjusted = false
    while #queue > 0 and not adjusted do
      local node = table.remove(queue, 1)
      if node.type == 'vsplit' then
        local lc, rc = node.left_child, node.right_child
        local ln, rn = count_cols(lc), count_cols(rc)
        local target_l = math.floor((lc.width + rc.width) * ln / (ln + rn))
        local delta = target_l - lc.width
        if delta ~= 0 then
          local cands = {}
          local rv, lv = far_pane(rc), far_pane(lc)
          for _, p in ipairs(collect_panes(lc)) do table.insert(cands, { index = p.index, side = 'left', verify = rv.index }) end
          for _, p in ipairs(collect_panes(rc)) do table.insert(cands, { index = p.index, side = 'right', verify = lv.index }) end
          adjusted = try_adjust(window, tab, cands, delta, 'Right', 'Left', 'width')
        end
        if not adjusted then table.insert(queue, lc); table.insert(queue, rc) end
      elseif node.type == 'hsplit' then
        local tc, bc = node.top_child, node.bot_child
        local tn, bn = count_rows(tc), count_rows(bc)
        local target_t = math.floor((tc.height + bc.height) * tn / (tn + bn))
        local delta = target_t - tc.height
        if delta ~= 0 then
          local cands = {}
          local bv, tv = far_pane(bc), far_pane(tc)
          for _, p in ipairs(collect_panes(tc)) do table.insert(cands, { index = p.index, side = 'left', verify = bv.index }) end
          for _, p in ipairs(collect_panes(bc)) do table.insert(cands, { index = p.index, side = 'right', verify = tv.index }) end
          adjusted = try_adjust(window, tab, cands, delta, 'Down', 'Up', 'height')
        end
        if not adjusted then table.insert(queue, tc); table.insert(queue, bc) end
      end
    end
    if not adjusted then break end
  end
  window:perform_action(act.ActivatePaneByIndex(active_idx), tab:active_pane())
end

local function split_and_equalize(direction)
  return wezterm.action_callback(function(window, pane)
    window:perform_action(act.SplitPane { direction = direction }, pane)
    equalize_tab(window)
  end)
end

config.keys = {
  -- Shift+Enter -> CSI u 시퀀스 (Claude Code 줄바꿈용)
  { key = 'Enter', mods = 'SHIFT', action = act.SendString '\x1b[13;2u' },
  -- Ctrl+Shift+F5: Graphite Light/Dark 테마 전환
  { key = 'F5', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    local cur = read_theme()
    local next_theme = cur == 'Graphite-Light' and 'Graphite-Dark' or 'Graphite-Light'
    write_theme(next_theme)
    window:toast_notification('WezTerm', '테마 전환: ' .. next_theme .. ' (재시작 필요)', nil, 3000)
  end) },
  -- 패널 분할
  { key = '+', mods = 'ALT|SHIFT', action = split_and_equalize('Right') },
  { key = '_', mods = 'ALT|SHIFT', action = split_and_equalize('Down') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    window:perform_action(act.CloseCurrentPane { confirm = false }, pane)
    equalize_tab(window)
  end) },
  -- 탭
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentTab { confirm = false } },
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = '1', mods = 'CTRL', action = act.ActivateTab(0) },
  { key = '2', mods = 'CTRL', action = act.ActivateTab(1) },
  { key = '3', mods = 'CTRL', action = act.ActivateTab(2) },
  { key = '4', mods = 'CTRL', action = act.ActivateTab(3) },
  { key = '5', mods = 'CTRL', action = act.ActivateTab(4) },
  { key = '6', mods = 'CTRL', action = act.ActivateTab(5) },
  { key = '7', mods = 'CTRL', action = act.ActivateTab(6) },
  { key = '8', mods = 'CTRL', action = act.ActivateTab(7) },
  { key = '9', mods = 'CTRL', action = act.ActivateTab(-1) },
  -- 이름 변경
  { key = 'r', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
    description = 'Tab 이름 변경:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then window:active_tab():set_title(line) end
    end),
  }},
}

-- 우클릭 메뉴: 패널 닫기
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action_callback(function(window, pane)
      local tab = window:active_tab()
      local panes = tab:panes_with_info()
      if #panes > 1 then
        window:perform_action(act.InputSelector {
          title = '패널 메뉴',
          choices = {
            { label = '현재 패널 닫기' },
          },
          action = wezterm.action_callback(function(window2, pane2, id, label)
            if label == '현재 패널 닫기' then
              window2:perform_action(act.CloseCurrentPane { confirm = false }, pane2)
              equalize_tab(window2)
            end
          end),
        }, pane)
      end
    end),
  },
}

return config
