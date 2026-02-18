-- Gruvbox Samurai colorscheme for Neovim
-- Based on Gruvbox Samurai for Sublime Text by Michael Milstead
-- https://github.com/508LoopDetected/gruvbox-samurai
--
-- This colorscheme uses gruvbox.nvim as a base and applies the Samurai palette

vim.o.background = 'dark'

local gruvbox = require('gruvbox')

gruvbox.setup {
  contrast = 'hard',
  transparent_mode = true,
  italic = {
    strings = false,
    comments = true,
    operators = false,
    folds = true,
    emphasis = true,
  },
  -- Samurai palette overrides
  -- The main difference is a darker background (#161616 vs #1d2021)
  palette_overrides = {
    -- Samurai uses an even darker background than gruvbox hard
    dark0_hard = '#161616',
    dark0 = '#282828',
    dark0_soft = '#32302f',
    dark1 = '#3c3836',
    dark2 = '#504945',
    dark3 = '#665c54',
    dark4 = '#7c6f64',
    light0 = '#fbf1c7',
    light1 = '#ebdbb2',
    light2 = '#d5c4a1',
    light3 = '#bdae93',
    light4 = '#a89984',
    bright_red = '#fb4934',
    bright_green = '#b8bb26',
    bright_yellow = '#fabd2f',
    bright_blue = '#83a598',
    bright_purple = '#d3869b',
    bright_aqua = '#8ec07c',
    bright_orange = '#fe8019',
    neutral_red = '#cc241d',
    neutral_green = '#98971a',
    neutral_yellow = '#d79921',
    neutral_blue = '#458588',
    neutral_purple = '#b16286',
    neutral_aqua = '#689d6a',
    neutral_orange = '#d65d0e',
    gray = '#928374',
  },
  overrides = {
    -- Match Sublime Samurai's subtle line highlighting
    CursorLine = { bg = '#3c3836' },
    CursorLineNr = { fg = '#a89984', bold = true },
    LineNr = { fg = '#928374' },
    -- Visual selection matches Sublime's selection color
    Visual = { bg = '#3c3836' },
    -- Search highlighting matches Sublime's find_highlight
    Search = { fg = '#282828', bg = '#fabd2f' },
    IncSearch = { fg = '#282828', bg = '#fe8019' },

    -- Treesitter overrides to match Sublime Samurai syntax colors
    -- Keywords → red italic
    ['@keyword'] = { fg = '#fb4934', italic = true },
    ['@keyword.function'] = { fg = '#8ec07c', italic = true },
    ['@keyword.return'] = { fg = '#fb4934', italic = true },
    ['@keyword.conditional'] = { fg = '#fb4934', italic = true },
    ['@keyword.repeat'] = { fg = '#fb4934', italic = true },
    ['@keyword.operator'] = { fg = '#8ec07c' },
    ['@conditional'] = { fg = '#fb4934', italic = true },
    ['@repeat'] = { fg = '#fb4934', italic = true },
    ['@exception'] = { fg = '#fb4934', italic = true },
    ['@include'] = { fg = '#fb4934', italic = true },

    -- Function definitions → green
    ['@function'] = { fg = '#b8bb26' },
    ['@method'] = { fg = '#b8bb26' },

    -- Function/method calls → aqua
    ['@function.call'] = { fg = '#8ec07c' },
    ['@method.call'] = { fg = '#8ec07c' },

    -- Variables → blue
    ['@variable'] = { fg = '#83a598' },
    ['@variable.builtin'] = { fg = '#d3869b' },

    -- Parameters → default fg
    ['@parameter'] = { fg = '#ebdbb2' },

    -- Properties → default fg
    ['@property'] = { fg = '#ebdbb2' },
    ['@field'] = { fg = '#ebdbb2' },

    -- Strings → green
    ['@string'] = { fg = '#b8bb26' },
    ['@string.escape'] = { fg = '#fb4934' },

    -- Types → yellow
    ['@type'] = { fg = '#fabd2f' },
    ['@type.builtin'] = { fg = '#fabd2f' },
    ['@storageclass'] = { fg = '#fb4934', italic = true },

    -- Constants → blue (constant.builtin like true/false/null stays purple)
    ['@constant'] = { fg = '#83a598' },
    ['@constant.builtin'] = { fg = '#d3869b' },
    ['@boolean'] = { fg = '#d3869b' },
    ['@number'] = { fg = '#d3869b' },
    ['@float'] = { fg = '#d3869b' },

    -- Comments → gray italic
    ['@comment'] = { fg = '#928374', italic = true },

    -- Operators → aqua
    ['@operator'] = { fg = '#8ec07c' },

    -- Punctuation → default fg
    ['@punctuation'] = { fg = '#ebdbb2' },
    ['@punctuation.bracket'] = { fg = '#ebdbb2' },
    ['@punctuation.delimiter'] = { fg = '#ebdbb2' },

    -- Constructor/class names → yellow
    ['@constructor'] = { fg = '#fabd2f' },
  },
}

gruvbox.load()
