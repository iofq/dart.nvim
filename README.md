# dart.nvim - a minimalist tabline focused on pinning buffers
[![CI](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml/badge.svg)](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml)

dart.nvim is a minimalist tabline focused on pinning buffers for fast switching between a group of files. Pick a file and throw a single-character dart to jump to it.

![large.png](https://github.com/user-attachments/assets/5ca4bb2f-ef67-4c75-8b2c-68904ede875c)

## Introduction

#### The philosophy of this plugin is roughly:
- In a given project, there's a set of ~1-10 files that you're working on and frequently jump between.
- Using LSP or other code navigation, you open any number of other buffers that are short-lived.
  - These do not need to be tracked long-term, but jumping back to the n-th previous buffer can be helpful.
- The tabline is the best place to display these marked files; being constantly in-view means you can more quickly memorize mark -> file mappings to reduce mental overhead, instead of being hidden behind a picker, list, or keymap.

#### You should try this plugin if:
- You've tried harpoon, arrow.nvim, grapple.nvim, etc. and are intrigued by the idea of pinning files, but couldn't get them to click
- You regularly spam `gt` or `:bnext` to get to the tab/file you want.
- You use a buffer picker like `Telescope`, `fzf-lua`, or `Snacks` to navigate files.

## Features

⦿  Minimal tabline inspired by `mini.tabline`, with customizable formatting.

⦿  Mark open buffers to pin them to the tabline. _This is separate from Vim's marks/global marks._

⦿  Unmarked buffers will be listed in the `buflist` and sorted by most-recently-visited

⦿  Cycle through the tabline with `Dart.next` and `Dart.prev` as a replacement for `gt`/`:bnext`, or jump to a specific buffer by character with `Dart.jump`

⦿  Simple `Dart.pick` 'picker' to jump to any marked buffer with a single keystroke

⦿  Basic session persistence integrates with plugins like `mini.sessions`

⦿  Single ~700 line lua file with no external dependencies, for those of you who enjoy golfing.

## Showcase

#### Buffers show in the tabline up to the length of `buflist` (default 3) as they are opened:

![3-buffers.png](https://github.com/user-attachments/assets/da0a595b-9779-4eea-8845-2af2a54092e2)

#### Opening a new buffer shifts buffers right, and pops the rightmost buffer off of the tabline:
![3-buffers-new.png](https://github.com/user-attachments/assets/92559642-d1a5-4e2a-96a9-141c3e592856)

#### A buffer can be pinned using `;;` to add it to the `marklist` and display it regardless of the `buflist`
![4-buffers.png](https://github.com/user-attachments/assets/ee58370a-1856-4c70-9ba1-b065baaf4a5f)


## Installation

### lazy.nvim
```lua
{
    'iofq/dart.nvim',
    opts = {}
}
````

### vim.pack (Neovim >= 0.12)
```lua
vim.pack.add({ "https://github.com/iofq/dart.nvim"})
require('dart').setup({})
````

## Configuration

`require('dart').setup({ ... })` accepts the following options:

```lua
{
  -- List of characters to use to mark 'pinned' buffers
  -- The characters will be chosen for new pins in order
  marklist = { 'a', 's', 'd', 'f', 'q', 'w', 'e', 'r' },

  -- List of characters to use to mark recent buffers, which are displayed first (left) in the tabline
  -- Buffers that are 'marked' are not included in this list
  -- The length of this list determines how many recent buffers are tracked
  -- Set to {} to disable recent buffers in the tabline
  buflist = { 'z', 'x', 'c' },

  tabline = {
    -- Force the tabline to always be shown, even if no files are currently marked
    always_show = true,

    -- If true, Dart.next and Dart.prev will wrap around the tabline
    cycle_wraps_around = true,

    -- Function to determine the order mark/buflist items will be shown on the tabline
    -- Should return a table with keys being the mark and values being integers,
    -- e.g. { "a": 1, "b", 2 } would sort the "a" mark to the left of "b" on your tabline
    order = function(config)
      local order = {}
      for i, key in ipairs(vim.list_extend(vim.deepcopy(config.buflist), config.marklist)) do
        order[key] = i
      end
      return order
    end,

    -- Function to format a tabline item after the path is built
    -- e.g. to add an icon
    format_item = function(item)
      local click = string.format('%%%s@SwitchBuffer@', item.bufnr)
      return string.format('%%#%s#%s %s%%#%s#%s %%X', item.hl_label, click, item.label, item.hl, item.content)
    end,
  },

  picker = {
    -- argument to pass to vim.fn.fnamemodify `mods`, before displaying the file path in the picker
    -- e.g. ":t" for the filename, ":p:." for relative path to cwd
    path_format = ':t',
    -- border style for the picker window
    -- See `:h winborder` for options
    border = 'rounded',
  },

  -- State persistence. Use Dart.read_session and Dart.write_session manually
  persist = {
    -- Path to persist session data in
    path = vim.fs.joinpath(vim.fn.stdpath('data'), 'dart'),
  },

  -- Default mappings
  -- Set an individual mapping to an empty string to disable,
  mappings = {
    mark = ';;', -- Mark current buffer
    jump = ';', -- Jump to buffer marked by next character i.e `;a`
    pick = ';p', -- Open Dart.pick
    next = '<S-l>', -- Cycle right through the tabline
    prev = '<S-h>', -- Cycle left through the tabline
    unmark_all = ';u', -- Close all marked and recent buffers
  },
}
```

## Highlights
`dart.nvim` falls back on `mini.tabline` highlights since they are well-supported by many colorschemes. The following highlights are available to override:

- `DartCurrent` - the currently selected tabline item
- `DartCurrentLabel` - label (mark) for the currently selected item
- `DartCurrentModified` - the currently selected tabline item, if modified
- `DartCurrentLabelModified` - label (mark) for the currently selected item, if modified

- `DartVisible` - visible but not selected tabline items
- `DartVisibleLabel` - label (mark) for the visible items
- `DartVisibleModified` - visible tabline items, if modified
- `DartVisibleLabelModified` - label (mark) for the visible items, if modified

- `DartFill` - Tabline fill between the buffer list and tabpage
- `DartPickLabel` - Label for marks in `Dart.pick`


## Persistence/sessions
`dart.nvim` supports basic session persistence and can be integrated with `mini.sessions` like so:

```lua
require('mini.sessions').setup {
  hooks = {
    pre = {
      read = function(session)
        Dart.read_session(session['name'])
      end,
      write = function(session)
        Dart.write_session(session['name'])
      end,
    },
  },
}
```

## Recipes

#### Icons in tabline, using `config.tabline.format_item` and `mini.icons`:
<img width="436" height="76" alt="scrot-2025-08-20T23:49:12" src="https://github.com/user-attachments/assets/4cd3e178-131b-4390-acd3-25ed8af03d1a" />

```lua
require('dart').setup({
  tabline = {
    format_item = function(item)
      local icon = _G.MiniIcons.get('file', item.content)
      local click = string.format('%%%s@SwitchBuffer@', item.bufnr)
      return string.format('%%#%s#%s %s%%#%s#%s %s %%X', item.hl_label, click, item.label, item.hl, icon, item.content)
    end
  }
})
```


#### Reverse tabline order, so marklist is to the left, and buflist to the right:
<img width="620" height="79" alt="scrot-2025-08-20T23:52:20" src="https://github.com/user-attachments/assets/05bdcbdd-ffe0-47ec-a643-05fb6ea939ea" />

```lua
require('dart').setup({
  tabline = {
    order = function()
      local order = {}
      for i, key in ipairs(vim.list_extend(vim.deepcopy(Dart.config.marklist), Dart.config.buflist)) do
        order[key] = i
      end
      return order
    end,
  }
})
```

#### `Snacks` picker for marked buffers

```lua
  local files = {}
  for _, item in ipairs(Dart.state()) do
    table.insert(files, {
      file = item.filename,
      text = item.mark .. " " .. item.filename,
      label = item.mark,
    })
  end
  Snacks.picker.pick {
    source = 'dart.nvim',
    items = files,
    format = 'file',
    title = 'dart.nvim buffers',
  }
```

## Available functions

### `Dart.mark(bufnr, char)`

Sets the buffer `bufnr` to the given single-character mark from `config.marklist` (e.g. `'a'`).

If `bufnr` is not specified, defaults to the current buffer.
If `char` is not specified, defaults to the next unused mark from `marklist`.

If the buffer is in the `buflist`, it will be promoted to the `marklist` using the next unused mark. If the buffer is already in the marklist, it will be unmarked and moved back to the `buflist`.

### `Dart.unmark({type = string, marks = {}})`

Unmarks buffers, with different behavior based on `type`.

`type = 'marks'` - Unmarks the buffers identified by the `marks` argument, i.e. `unmark({'a', 's'})`
`type = 'marklist'` - Unmarks all buffers in `config.marklist`
`type = 'buflist'` - Unmarks all buffers in `config.buflist`
`type = 'all'` - Unmarks all buffers in `Dart.state()`

### `Dart.jump(char)`

Jumps to the buffer assigned to the given `char` mark.

### `Dart.pick()`

Opens a floating picker window that lists all active marks. Jump to one by pressing the corresponding key.

### `Dart.read_session(name)`

Manually load previously saved marks from disk by name.

### `Dart.write_session(name)`

Writes the current buffer marks to the named session file.

### `Dart.prev/Dart.next()`

Replacements for `gt`/`:bnext`; jumps to the prev/next buffer in the tabline.

### `Dart.gen_tabline()`

Tabline generator. Use as `vim.opt.tabline = '%!v:lua.Dart.gen_tabline()'`

### `Dart.state()`

Returns Dart's state table, for extensibility.

## Comparison with similar plugins

`dart.nvim` is quite similar to other Neovim plugins, and its main differentiators are the tabline-first workflow and small codebase.

- [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) - Harpoon with a custom tabline could approximate this plugin. However, Harpoon by default is limited to 4 buffers and requires separate keybinds for each.
- [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim) - Arrow.nvim is great, but it does not provide a tabline, instead opting for a pick-style UI. Having the marklist always in view is at least _slightly_ faster
- [grapple.nvim](https://github.com/cbochs/grapple.nvim) - Grapple works with tags and as such will return you to the marked location in a file, not your most recent location.
- Global vim marks can approximate this functionality, but returning to the marked location in a file is annoying - more commonly, you want to pick up where you left off in a buffer.
