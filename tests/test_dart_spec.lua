-- init child neovim for tests
local child = MiniTest.new_child_neovim()

local sep = package.config:sub(1, 1)

-- helpers
local set = MiniTest.new_set
local eq = MiniTest.expect.equality
local load_module = function(config)
  child.lua('require("dart").setup(...)', { config })
end

local contains = function(haystack, needle)
  for _, n in ipairs(haystack) do
    if n == needle then
      return true
    end
  end
  return false
end

local edit_path = function(_path)
  child.cmd('edit tests/dir/' .. _path)
end

-- ripped this func from mini.tabline tests :)
local eval_tabline = function(show_hl, show_action)
  show_hl = show_hl or false
  show_action = show_action or false

  local res = child.lua_get('Dart.gen_tabline()'):gsub(sep, '/')

  if not show_hl then
    res = res:gsub('%%#[^#]+%w+#', '')
  end
  if not show_action then
    res = res:gsub('%%%d+@[^@]+@', ''):gsub('%%X', '')
  end
  return res
end

local do_dart_test = function(params, config)
  load_module(config)

  for i, p in ipairs(params.paths) do
    edit_path(p.src)

    if params.mark_after and contains(params.mark_after, i) then
      child.lua([[Dart.mark()]])
    end
    if params.type_keys and params.type_keys[i] then
      child.type_keys(params.type_keys[i])
    end
  end

  eq(eval_tabline(), params.wanted)
end

local T = set {
  hooks = {
    pre_case = function()
      child.restart { '-u', 'tests/minit.lua' }
      child.o.lines, child.o.columns, child.bo.readonly = 10, 60, false
    end,
    post_once = child.stop,
  },
}

T['gen_tabline() with buflist'] = set {
  parametrize = {
    {
      {
        paths = {},
        wanted = '',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/init.lua' },
        },
        wanted = ' z init.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
          { src = 'unix/dir1/4.lua' },
        },
        wanted = ' z 4.lua  x 1.lua  c 2.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir2/sub1/subdir/init.lua' },
          { src = 'unix/dir2/sub2/subdir/init.lua' },
        },
        wanted = ' z sub1/subdir/init.lua  x sub2/subdir/init.lua ',
      },
    },
  },
}

T['gen_tabline() with buflist']['works'] = function(params)
  do_dart_test(params)
end

T['gen_tabline() with marklist'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
          { src = 'unix/dir1/4.lua' },
        },
        mark_after = { 4 },
        wanted = ' x 1.lua  c 2.lua  a 4.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
          { src = 'unix/dir1/4.lua' },
          { src = 'unix/dir1/5.lua' },
        },
        mark_after = { 1, 2, 3, 4 },
        wanted = ' z 5.lua  a 1.lua  s 2.lua  d 3.lua  f 4.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir2/sub1/subdir/init.lua' },
          { src = 'unix/dir2/sub2/subdir/init.lua' },
        },
        mark_after = { 1 },
        wanted = ' z sub2/subdir/init.lua  a sub1/subdir/init.lua ',
      },
    },
  },
}

T['gen_tabline() with marklist']['works'] = function(params)
  do_dart_test(params)
end

T['gen_tabline() with config custom mark/buflist'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
          { src = 'unix/dir1/4.lua' },
          { src = 'unix/dir1/5.lua' },
        },
        mark_after = { 1, 2, 3, 4 },
        wanted = ' # 5.lua  1 1.lua  2 2.lua  + 4.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
        },
        mark_after = {},
        wanted = ' # 2.lua ',
      },
    },
  },
}

T['gen_tabline() with config custom mark/buflist']['works'] = function(params)
  do_dart_test(params, {
    marklist = { '1', '2' },
    buflist = { '#' },
  })
end

T['gen_tabline() with config no buflist'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        mark_after = {},
        wanted = '',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        mark_after = { 1 },
        wanted = ' a 1.lua ',
      },
    },
  },
}

T['gen_tabline() with config no buflist']['works'] = function(params)
  do_dart_test(params, { buflist = {} })
end

T['gen_tabline() with truncate_tabline'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/yeahthisisareallylongfilenamesowhat.lua' },
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
        },
        mark_after = { 1, 2, 3, 4 },
        type_keys = {
          [4] = ';f',
        },
        wanted = ' <  s 1.lua  d 2.lua  f 3.lua ',
      },
    },
  },
}

T['gen_tabline() with truncate_tabline']['works'] = function(params)
  do_dart_test(params)
end

T['gen_tabline() with close_all'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/yeahthisisareallylongfilenamesowhat.lua' },
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
          { src = 'unix/dir1/3.lua' },
        },
        mark_after = { 1, 2, 3, 4 },
        type_keys = {
          [3] = ';u',
          [4] = ';;',
        },
        wanted = ' z 2.lua  x 3.lua ',
      },
    },
  },
}

T['gen_tabline() with close_all']['works'] = function(params)
  do_dart_test(params)
end

T['gen_tabline() with bad path'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/init.lua' },
          { src = [[unix/bad\%.dir/init.lua]] },
        },
        -- %% here will get escaped correctly in tabline
        wanted = ' z 1.lua  x dir1/init.lua  c bad%%.dir/init.lua ',
      },
    },
  },
}

T['gen_tabline() with bad path']['works'] = function(params)
  do_dart_test(params)
end

return T
