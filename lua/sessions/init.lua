--[[
Why?
* folke/persistence.nvim: too automatic and not enough control
* topope/obsession: try
* mini-session: not enough control
* rmagatii/auto-session: automatic and bloated
* Shatur/neovim-session-manager: combo of workspace and session

Name:
* sessions.nvim: Simple
* intercession.nvim: clever

Goals:
* Call :Sessions save [path] to save
* Call :Sessions load [path] to load

normal session files are created. The difference is when you call :Sessions load
autocommands are registered which automatically save the session on window, buffer, etc. changes.
The same for when you do :Sessions save

Otherwise it's just a normal session! just a tiny bit of pixie dust
]]

local util = require("sessions.util")

local levels = vim.log.levels

-- default configuration
local config = {
    -- events which trigger a session save
    events = { "VimLeavePre" },

    -- default session filepath (relative)
    session_name = "",
}

local M = {}

-- ensure full path to session file exists, and attempt to create intermediate
-- directories if needed
local ensure_path = function(path)
    local dir, name = util.path.split(path)
    if dir and vim.fn.isdirectory(dir) == 0 then
        if vim.fn.mkdir(dir, "p") == 0 then
            return false
        end
    end
    return name ~= ""
end

-- given a path (possibly empty or nil) returns the absolute session path or
-- the default session path if it exists. Will create intermediate directories
-- as needed. Returns nil otherwise.
local get_session_path = function(path)
    if path and path ~= "" then
        path = vim.fn.expand(path, ":p")
    elseif config.session_name ~= "" then
        path = vim.fn.expand(config.session_name, ":p")
    end

    if path and path ~= "" then
        if not ensure_path(path) then
            return nil
        end
        if vim.fn.filereadable(path) == 0 then
            return nil
        end
        return path
    end

    return nil
end

-- TODO: when an nvim update provides autocommand registration from lua, make
-- this function local to avoid issues setting the session_file_path
local session_file_path = ""
M.write_session_file = function(path)
    if path then
        session_file_path = path
    end
    vim.cmd(string.format("mksession! %s", session_file_path))
end

-- start autosaving changes to the session file
M.start_autosave = function(path)
    if path then
        local original = path
        path = get_session_path(path)
        if not path then
            vim.notify(string.format("sessions.nvim: session file '%s' not found", original), levels.ERROR)
            return
        end
    end

    local events = vim.fn.join(config.events, ",")
    vim.cmd(string.format([[
    augroup sessions.nvim
    autocmd!
    autocmd %s * lua require("sessions").write_session_file()
    augroup end
    ]], events))
end

-- stop autosaving changes to the session file
M.stop_autosave = function()
    vim.cmd[[
    silent! autocmd! sessions.nvim
    silent! augroup! sessions.nvim
    ]]
end

-- save or overwrite a session file to the given path
M.save = function(path, opts)
    opts = opts or {}

    path = get_session_path(path)
    if not path then
        vim.notify("sessions.nvim: could not create session file", levels.ERROR)
        return
    end

    M.write_session_file(path)

    if opts.noautosave then return end
    M.start_autosave()
end

-- load a session file from the given path
M.load = function(path, opts)
    opts = opts or {}

    path = get_session_path(path)
    if not path then
        if not opts.silent then
            vim.notify(string.format("sessions.nvim: file '%s' does not exist", path))
        end
        return
    end

    vim.cmd(string.format("silent! source %s", path))
    session_file_path = path

    if opts.noautosave then return end
    M.start_autosave()
end

local subcommands = { "save", "load", "start", "stop" }

local subcommand_complete = function(lead)
    return vim.tbl_filter(function(item)
        return vim.startswith(item, lead)
    end, subcommands)
end

M.complete = function(lead, line, pos)
    -- remove the command name from the front
    line = string.sub(line, #"Sessions " + 1)
    pos = pos - #"Sessions "

    -- completion for subcommand names
    if #line == 0 then return subcommands end
    local index = string.find(line, " ")
    if not index or pos < index then
        return subcommand_complete(lead)
    end

    -- TODO: path completion?

    return {}
end

M.parse_args = function(subcommand, path)
    if subcommand == "save" then
        M.save(path)
    elseif subcommand == "load" then
        M.load(path)
    elseif subcommand == "start" then
        M.start_autosave(path)
    elseif subcommand == "stop" then
        M.stop_autosave()
    else
        vim.notify(string.format("sessions.nvim: invalid subcommand '%s'", subcommand), levels.ERROR)
    end
end

M.setup = function(opts)
    opts = opts or {}
    config = vim.tbl_deep_extend("force", {}, config, opts)

    -- register commands
    vim.cmd[[
    command! -nargs=+ -complete=customlist,v:lua.require'sessions'.complete Sessions lua require("sessions").parse_args(<f-args>)
    ]]
end

return M
