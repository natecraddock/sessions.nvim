# sessions.nvim

a simple session manager plugin

Neovim (and Vim) support saving and loading of sessions (windows, tabs, buffers,
etc), but the interface isn't the easiest to use.

* `:mksession <file>` is required to save a session, and sessions are loaded with `nvim
  -S <file>` or `:source <file>`. If the file already exists, a bang is required
  `mksession! <file>`. This is a bit tedious and annoying when you do it wrong
  the first time.
* If the directories in the session filepath do not exist, `:mksession` will
  fail.
* It is easy to forget saving a session.

sessions.nvim is a lightweight wrapper around `:mksession` that adds a small
amount of pixie dust to make sessions management more simple and enjoyable.

* The commands `:SessionsSave` and `:SessionsLoad` are used to save and load
  session files.
* Further changes to the session are automatically saved to the session file
  after saving or loading a session.
* Session files created with sessions.nvim are independent of the plugin;
  loading with `nvim -S` or `:source` will *not* start autosaving.
* Intermediate directories are automatically created.
* A default session filepath may be customized.

sessions.nvim does not do anything automatically. Sessions will not be saved or
loaded until a command or an API function is called. This is to keep the plugin
simple and focused. The entire goal of sessions.nvim is to provide a wrapper
around `:mksession` and `:source`, not to provide workspace management.

[Other plugins](#related) exist to automatically save and load sessions for each
project directory if that is what you desire. It also wouldn't be difficult to
write an autocommand to load session files on nvim startup.

This readme covers *most* of the features of sessions.nvim, but full
documentation is found in the help file `:h sessions`.

## Example Usage

Work on a project until ready to take a break. Run `:SessionsSave .session` to
save the current state to a hidden file `.session`. nvim may be closed.

Later return to the same path and open nvim. Run `:SessionsLoad .session` to
load the saved session. Now any changes to the window layout, buffers, tabs,
etc. will be saved when closing nvim.

See
[natecraddock/workspaces.nvim](https://github.com/natecraddock/workspaces.nvim)
for an easy method of automatically restoring a session in saved workspace
folders.

## Installation

Install with your favorite Neovim package manager. Be sure to call the setup
function if you wish to change the default configuration or register the user
commands.

```lua
require("sessions").setup()
```

The setup function accepts a table to modify the default configuration:

```lua
{
    -- autocmd events which trigger a session save
    --
    -- the default is to only save session files before exiting nvim.
    -- you may wish to also save more frequently by adding "BufEnter" or any
    -- other autocmd event
    events = { "VimLeavePre" },

    -- default session filepath (relative)
    --
    -- if a path is provided here, then the path argument for commands and API
    -- functions will use session_filepath as a default if no path is provided.
    session_filepath = "",
}
```

For example, the following settings will save the session every time a window is
entered, and `.nvim/session` will be used as the default session filepath:

```lua
require("sessions").setup({
    events = { "WinEnter" },
    session_filepath = ".nvim/session",
})
```

This version is compatible with Neovim 0.6.

## Commands

The setup function registers the following commands:

* `:SessionsSave[!] [path]`

  Save a session file to the given path. If the path exists it will be
  overwritten. Starts autosaving the session on the configured events.

* `:SessionsLoad[!] [path]`

  Load a session file from the given path. If the path does not exist no session
  will be loaded. Starts autosaving changes to the session after loading.

* `:SessionsStop[!]`

  Stops session autosaving if enabled. The current state will be saved before
  stopping.

See `:h sessions-usage` for more information on the commands.

## Lua API

The session commands may also be accessed from Lua:

```lua
local sessions = require("sessions")

sessions.save(path: string, opts: table)

sessions.load(path: string, opts: table)

sessions.stop_autosave(opts: table)

sessions.recording(): bool
```

See `:h sessions-api` for more information on the Lua API.

## Demo

https://user-images.githubusercontent.com/7967463/151680092-71963df1-6459-4a57-bea9-a53e2a16fb2c.mp4

In this demo video I create a sessions file at `.nvim/session` relative to my current
directory. I then repeatedly quit nvim, reopen and load the session, modify the layout,
and close nvim. Halfway through I no longer provide a path to `:SessionsLoad` because I
have configured my `session_filepath` to be ".nvim/session".

## Related

If you want a more automatic solution, or something else, these plugins may interest you:

* [tpope/vim-obsession](https://github.com/tpope/vim-obsession) Very similar,
  but modifies the session files to always autosave after sourcing.
* [folke/persistence.nvim](https://github.com/folke/persistence.nvim)
  Automatically stores sessions in a shared directory on nvim exit.
* [rmagatii/auto-session](https://github.com/rmagatti/auto-session)
  Automatically stores sessions in a shared directory.
* [Shatur/neovim-session-manager](https://github.com/Shatur/neovim-session-manager)
  Saves sessions and manages workspaces.
