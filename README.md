# dart.nvim - a minimalist tabline focused on pinning buffers

[![CI](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml/badge.svg)](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml)

dart.nvim is a minimalist tabline focused on pinning buffers for fast switching between a group of files. Pick a file and throw a single-character dart to jump to it.

<img width="1052" height="1004" alt="scrot-2025-08-24T21:42:08" src="https://github.com/user-attachments/assets/d8123fcb-d1d5-4859-954e-e7cb7a5ad8c5" />

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

⦿ Minimal tabline inspired by `mini.tabline`, with customizable formatting.

⦿ Mark open buffers to pin them to the tabline. _This is separate from Vim's marks/global marks._

⦿ Unmarked buffers will be listed in the `buflist` and sorted by most-recently-visited

⦿ Cycle through the tabline with `Dart.next` and `Dart.prev` as a replacement for `gt`/`:bnext`, or jump to a specific buffer by character with `Dart.jump`

⦿ Simple `Dart.pick` 'picker' to jump to any marked buffer with a single keystroke, or navigate to one and jump with the `<CR>` key

⦿ Basic session persistence integrates with plugins like `mini.sessions`

⦿ Single ~700 line lua file with no external dependencies, for those of you who enjoy golfing.

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
    dependencies = {
        'echasnovski/mini.nvim', -- optional, icons provider
        'nvim-tree/nvim-web-devicons' -- optional, icons provider
    },
    opts = {} -- see Configuration section
}
```

### vim.pack (Neovim >= 0.12)

```lua
vim.pack.add({ "https://github.com/iofq/dart.nvim"})
require('dart').setup({})
```

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

    -- Override the default label foreground highlight
    -- You can also use the DartVisibleLabel/DartCurrentLabel/etc. highlights
    -- to override the label highlights entirely.
    label_fg = 'orange',

    -- Override the default marked label foreground highlight
    -- This applies specifically to marked buffer labels
    label_marked_fg = 'orange',

    -- Display icons in the tabline
    -- Supported icon providers are mini.icons and nvim-web-devicons
    icons = true,

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
    format_item = function(item)
      local icon = item.icon ~= nil and string.format('%s  ', item.icon) or ''
      return string.format(
        '%%#%s#%s %s%%#%s#%s%%#%s#%s %%X',
        item.hl,
        item.click,
        icon,
        item.hl_label,
        item.label,
        item.hl,
        item.content
      )
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

| Category    | Highlight Group                  | Description                                           |
| ----------- | -------------------------------- | ----------------------------------------------------- |
| **Current** | `DartCurrent`                    | Currently selected buffer                             |
|             | `DartCurrentLabel`               | Label for currently selected buffer                   |
|             | `DartCurrentModified`            | Currently selected buffer (modified)                  |
|             | `DartCurrentLabelModified`       | Label for currently selected buffer (modified)        |
| **Visible** | `DartVisible`                    | Visible but not selected buffers                      |
|             | `DartVisibleLabel`               | Label for visible but not selected buffers            |
|             | `DartVisibleModified`            | Visible buffers (modified)                            |
|             | `DartVisibleLabelModified`       | Label for visible buffers (modified)                  |
| **Marked**  | `DartMarked`                     | Marked buffers                                        |
|             | `DartMarkedLabel`                | Label for marked buffers                              |
|             | `DartMarkedModified`             | Marked buffers (modified)                             |
|             | `DartMarkedLabelModified`        | Label for marked buffers (modified)                   |
|             | `DartMarkedCurrent`              | Currently selected marked buffer                      |
|             | `DartMarkedCurrentLabel`         | Label for currently selected marked buffer            |
|             | `DartMarkedCurrentModified`      | Currently selected marked buffer (modified)           |
|             | `DartMarkedCurrentLabelModified` | Label for currently selected marked buffer (modified) |
| **Other**   | `DartFill`                       | Tabline fill                                          |
|             | `DartPickLabel`                  | Label for marks in picker                             |

You can also use the `config.tabline.label_fg` to only change the label foreground color for all buffers, or `config.tabline.label_marked_fg` to only change the label foreground color for marked buffers (which is easier than overriding all `*Label*` highlights).

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

#### Move tabline icons to the right of label

<img width="611" height="104" alt="scrot-2025-08-24T22:09:39" src="https://github.com/user-attachments/assets/17e85e12-44c6-4949-9b6f-62386c1f9f0a" />

```lua
  format_item = function(item)
    local content = item.icon ~= nil and string.format('%s %s', item.icon, item.content) or item.content
    return string.format(
      '%%#%s#%s %s%%#%s#%s %%X',
      item.hl_label,
      item.click,
      item.label,
      item.hl,
      content
    )
  end,
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

#### Styling marked buffers differently from recent buffers

```lua
-- Set up custom colors for marked buffers
vim.api.nvim_create_autocmd('ColorScheme', {
  callback = function()
    -- Marked buffers get green color
    vim.api.nvim_set_hl(0, 'DartMarked', { fg = '#a6e3a1' }) -- green
    vim.api.nvim_set_hl(0, 'DartMarkedLabel', { fg = '#a6e3a1', bold = true })

    -- Current marked buffer stays blue but with green label
    vim.api.nvim_set_hl(0, 'DartMarkedCurrentLabel', { fg = '#a6e3a1', bold = true })

    -- Recent buffers (buflist) keep default styling
    -- Modified buffers get yellow
    vim.api.nvim_set_hl(0, 'DartMarkedModified', { fg = '#f9e2af' }) -- yellow
  end
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

Opens a floating picker window that lists all active marks. Jump to one by pressing the corresponding key or navigate to one and jump with the `<CR>` key.

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

### `Dart.state_from_filename(filename)`

Search Dart's state table by filename. Returns nil if not found

### `Dart.state_from_mark(mark)`

Search Dart's state table by mark. Returns nil if not found

### `Dart.should_show(filename)`

Returns true if a file should be shown (is valid, buflisted, etc.), and false if not.

## Comparison with similar plugins

`dart.nvim` is quite similar to other Neovim plugins, and its main differentiators are the tabline-first workflow and small codebase.

- [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) - Harpoon with a custom tabline could approximate this plugin. However, Harpoon by default is limited to 4 buffers and requires separate keybinds for each.
- [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim) - Arrow.nvim is great, but it does not provide a tabline, instead opting for a pick-style UI. Having the marklist always in view is at least _slightly_ faster
- [grapple.nvim](https://github.com/cbochs/grapple.nvim) - Grapple works with tags and as such will return you to the marked location in a file, not your most recent location.
- Global vim marks can approximate this functionality, but returning to the marked location in a file is annoying - more commonly, you want to pick up where you left off in a buffer.
