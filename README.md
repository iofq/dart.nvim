# dart.nvim - a minimalist tabline focused on pinning buffers
[![CI](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml/badge.svg)](https://github.com/iofq/dart.nvim/actions/workflows/main.yaml)

dart.nvim is a minimalist tabline focused on pinning buffers for fast switching between a group of files. Pick a file and throw a single-character dart to jump to it.

The philosophy is roughly:
- In a given project, there's a set of ~1-10 files that you're working on and frequently jump between.
- Using LSP or other code navigation, you open any number of other buffers that are short-lived.
  - These do not need to be tracked long-term, but jumping back to the n-th previous buffer can be helpful.
- The tabline is the best place to display these marked files; being constantly in-view means you can more quickly memorize mark -> file mappings to reduce mental overhead, instead of being hidden behind a picker, list, or keymap.

![large.png](https://github.com/user-attachments/assets/5ca4bb2f-ef67-4c75-8b2c-68904ede875c)


## Showcase

Buffers show in the tabline up to the length of `buflist` (default 3) as they are opened:

![3-buffers.png](https://github.com/user-attachments/assets/da0a595b-9779-4eea-8845-2af2a54092e2)


Opening a new buffer shifts buffers right, and pops the rightmost buffer off of the tabline:
![3-buffers-new.png](https://github.com/user-attachments/assets/92559642-d1a5-4e2a-96a9-141c3e592856)

A buffer can be pinned using `;;` to add it to the `marklist` and display it regardless of the `buflist`
![4-buffers.png](https://github.com/user-attachments/assets/ee58370a-1856-4c70-9ba1-b065baaf4a5f)


## Features

⦿  Minimal tabline inspired by `mini.tabline`

⦿  Mark open buffers to pin them to the tabline. _This is separate from Vim's marks/global marks._

⦿  Unmarked buffers will be listed in the `buflist` and sorted by most-recently-visited

⦿  Cycle through the tabline normally with `Dart.next` and `Dart.prev`, or jump to a specific buffer by character with `Dart.jump`

⦿  Simple `Dart.pick` 'picker' to jump to any marked buffer with a single keystroke

⦿  Basic session persistence integrates with plugins like `mini.sessions`

⦿  Single ~400 line lua file with no external dependencies

## Installation

### lazy.nvim
```lua
{
    'iofq/dart.nvim',
    opts = {}
}
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
  buflist = { 'z', 'x', 'c' },

  -- If true, Dart.next and Dart.prev will wrap around the tabline
  cycle_wraps_around = true,

  -- State persistence. Use Dart.read_session and Dart.write_session manually
  persist = {
    -- Path to persist session data in
    path = vim.fs.joinpath(vim.fn.stdpath('data'), 'dart'),
  },

  -- Force the tabline to always be shown, even if no files are currently marked
  -- May be useful if `buflist` is empty
  always_show_tabline = true,

  -- Default mappings
  -- Set an individual mapping to an empty string to disable,
  mappings = {
    mark = ';;', -- Mark current buffer
    jump = ';', -- Jump to buffer marked by next character i.e `;a`
    pick = ';p', -- Open Dart.pick
    next = '<S-l>', -- Cycle right through the tabline
    prev = '<S-h>', -- Cycle left through the tabline
  },
}
```

## Highlights
`dart.nvim` falls back on `mini.tabline` highlights since they are well-supported by many colorschemes. The following highlights are available to override:

- `DartCurrent` - the currently selected tabline item
- `DartCurrentLabel` - label (mark) for the currently selected item
- `DartCurrentModified` - the currently selected tabline item, if modified
- `DartCurrentLabelModified` - label (mark) for the currently selected item, if modified

- `DartCurrent` - visible but not selected tabline items
- `DartCurrentLabel` - label (mark) for the visible items
- `DartCurrentModified` - visible tabline items, if modified
- `DartCurrentLabelModified` - label (mark) for the visible items, if modified

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

## Available functions

### `Dart.mark(bufnr, char)`

Sets the buffer `bufnr` to the given single-character mark from `config.marklist` (e.g. `'a'`).

If `bufnr` is not specified, defaults to the current buffer.
If `char` is not specified, defaults to the next unused mark from `marklist`.

If the buffer is in the `buflist`, it will be promoted to the `marklist` using the next unused mark.

### `Dart.jump(char)`

Jumps to the buffer assigned to the given `char` mark.

### `Dart.pick()`

Opens a floating picker window that lists all active marks. Jump to one by pressing the corresponding key.

### `Dart.read_session(name)`

Manually load previously saved marks from disk by name.

### `Dart.write_session(name)`

Writes the current buffer marks to the named session file.

## Comparison with similar plugins

`dart.nvim` is quite similar to other Neovim plugins, and its main differentiators are the tabline-first workflow and small codebase.

- [harpoon](https://github.com/ThePrimeagen/harpoon/tree/harpoon2) - Harpoon with a custom tabline could approximate this plugin. However, Harpoon by default is limited to 4 buffers and requires separate keybinds for each.
- [arrow.nvim](https://github.com/otavioschwanck/arrow.nvim) - Arrow does not provide a tabline, instead opting for a pick-style UI.
- [grapple.nvim](https://github.com/cbochs/grapple.nvim) - Grapple works with tags and as such will return you to the marked location in a file, not your most recent location.
- Global vim marks can approximate this functionality, but returning to the marked location in a file is annoying - more commonly, you want to pick up where you left off in a buffer.
