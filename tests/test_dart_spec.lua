-- init child neovim for tests
MiniTest = _G.MiniTest -- fixes linter
local child = MiniTest.new_child_neovim()

-- helpers
local set = MiniTest.new_set
local eq = MiniTest.expect.equality

-- ripped this func from mini.tabline tests :)
local eval_tabline = function(show_hl, show_action)
  show_hl = show_hl or false
  show_action = show_action or false

  local res = child.lua_get('Dart.gen_tabline()'):gsub(package.config:sub(1, 1), '/')

  if not show_hl then
    res = res:gsub('%%#[^#]+%w+#', '')
  end
  if not show_action then
    res = res:gsub('%%%d+@[^@]+@', ''):gsub('%%X', '')
  end
  return res
end

local contains = function(haystack, needle)
  for _, n in ipairs(haystack) do
    if n == needle then
      return true
    end
  end
  return false
end

local do_dart_test = function(params)
  child.lua('require("dart").setup(...)', { params.config })

  -- init
  for i, path in ipairs(params.paths) do
    local cmd = 'edit'
    if path.tab then
      cmd = 'tabedit'
    end
    child.cmd(cmd .. ' tests/dir/' .. path.src)

    if params.mark_after and contains(params.mark_after, i) then
      child.lua([[Dart.mark()]])
    end
    if params.type_keys and params.type_keys[i] then
      child.type_keys(params.type_keys[i])
    end
  end

  -- checks
  if params['vim.opt.showtabline'] then
    eq(params['vim.opt.showtabline'], child.api.nvim_get_option_value('showtabline', {}))
  end
  if params.wanted then
    eq(eval_tabline(), params.wanted)
  end
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

T['with buflist'] = set {
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
        wanted = ' z 4.lua  x 3.lua  c 2.lua ',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir2/sub1/subdir/init.lua' },
          { src = 'unix/dir2/sub2/subdir/init.lua' },
        },
        wanted = ' z sub2/subdir/init.lua  x sub1/subdir/init.lua ',
      },
    },
  },
}

T['with marklist'] = set {
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
        wanted = ' x 3.lua  c 2.lua  a 4.lua ',
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

T['with config custom mark/buflist'] = set {
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
        config = {
          marklist = { '1', '2' },
          buflist = { '#' },
        },
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
        config = {
          marklist = { '1', '2' },
          buflist = { '#' },
        },
        wanted = ' # 2.lua ',
      },
    },
  },
}

T['with config no buflist'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        config = { buflist = {} },
        wanted = '',
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        mark_after = { 1 },
        config = { buflist = {} },
        wanted = ' a 1.lua ',
      },
    },
  },
}

T['with truncate_tabline'] = set {
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

T['with close_all'] = set {
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
        wanted = ' z 3.lua  x 2.lua ',
      },
    },
  },
}

T['with bad path'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/init.lua' },
          { src = [[unix/bad\%.dir/init.lua]] },
        },
        -- %% here will get escaped correctly in tabline
        wanted = ' z bad%%.dir/init.lua  x dir1/init.lua  c 1.lua ',
      },
    },
  },
}

T['init with always_show'] = set {
  parametrize = {
    {
      {
        paths = {},
        ['vim.opt.showtabline'] = 2,
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        ['vim.opt.showtabline'] = 2,
      },
    },
  },
}

T['init with always_show=false'] = set {
  parametrize = {
    {
      {
        paths = {},
        config = { tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 1,
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        config = { tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 2,
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
        },
        type_keys = { [1] = ';u' },
        config = { tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 2,
      },
    },
  },
}

T['init with always_show=false and no buflist'] = set {
  parametrize = {
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua' },
        },
        type_keys = { [2] = ';u' },
        config = { buflist = {}, tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 1,
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua', tab = true },
        },
        type_keys = { [2] = ';u' },
        config = { buflist = {}, tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 1,
      },
    },
    {
      {
        paths = {
          { src = 'unix/dir1/1.lua' },
          { src = 'unix/dir1/2.lua', tab = true },
        },
        mark_after = { 1 },
        config = { buflist = {}, tabline = { always_show = false } },
        ['vim.opt.showtabline'] = 2,
      },
    },
  },
}

for _, test in pairs(T) do
  test['works'] = function(params)
    do_dart_test(params)
  end
end

return T
