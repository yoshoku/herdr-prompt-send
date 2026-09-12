# herdr-prompt-send

A Neovim plugin to send the current buffer, a range of lines,
or the contents of a register to an AI coding agent running in a herdr pane.

- Agents are listed with `herdr agent list`. The pane running Neovim itself is excluded.
- If exactly one agent is found, the text is sent to it directly.
- If multiple agents are found, `vim.ui.select()` is used to choose one.

## Requirements

- Neovim 0.10 or later
- herder

## Installation

Install the plugin with your plugin manager and call `setup()`.
`setup()` must be called to define the `:HerdrPromptSend` command.

### lazy.nvim

```lua
{
  "yoshoku/herdr-prompt-send",
  cond = vim.env.HERDR_ENV == '1',
  lazy = false,
  keys = {
    { '<leader>hs', '<cmd>HerdrPromptSend<cr>', desc = 'Send prompt to Herdr agent' },
    { '<leader>hs', ":'<,'>HerdrPromptSend<cr>", mode = 'v', desc = 'Send selection to Herdr agent' },
    { '<leader>hsy', '<cmd>HerdrPromptSend "<cr>', desc = 'Send last yank to Herdr agent' },
    { '<leader>hs+', '<cmd>HerdrPromptSend +<cr>', desc = 'Send clipboard to Herdr agent' },
  },
  opts = {},
}
```

### vim.pack (Neovim 0.12 or later)

```lua
vim.pack.add({ "https://github.com/yoshoku/herdr-prompt-send" })
require("herdr-prompt-send").setup()
```

## Configuration

Default configuration:

```lua
require("herdr-prompt-send").setup({
  submit = false,
})
```

| Option   | Type      | Default | Description |
| -------- | --------- | ------- | ----------- |
| `submit` | `boolean` | `false` | If `false`, the text is typed into the agent's input with `herdr pane send-text` and is not submitted, so you can review or edit it before pressing Enter. If `true`, the text is submitted as a prompt with `herdr agent prompt` (including Enter). |

## Usage

```vim
" Send the whole buffer
:HerdrPromptSend

" Send the visually selected lines
:'<,'>HerdrPromptSend

" Send the contents of register a
:HerdrPromptSend a
```

If both a register and a range are given, the register takes precedence.
Nothing is sent if the text is empty or contains only whitespace.

No keymaps are defined by default.

## Health check

```vim
:checkhealth herdr-prompt-send
```

It checks that Neovim is 0.10 or later, the `herdr` executable is found,
the herdr server is running,
and `herdr agent list` returns at least one agent other than the pane running Neovim.

## Documentation

See `:help herdr-prompt-send` for details.

## License

[MIT](LICENSE.txt)
