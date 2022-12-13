local M = {}

M.windows = (function()
    if jit then
        local os = string.lower(jit.os)
        return os == "windows"
    else
        return "\\" == package.config:sub(1, 1)
    end
end)()

-- system dependent path separator from plenary.nvim
M.path = {}
M.path.sep = (function()
    if M.windows then
        return "\\"
    else
        return "/"
    end
end)()

M.path.split = function(path)
    local parts = vim.split(path, M.path.sep)

    -- only a name given
    if #parts == 1 then
        return nil, parts[1]
    end

    -- else return dir and basename
    local dir = vim.fn.join(M.slice(parts, 1, #parts - 1), M.path.sep)
    local name = parts[#parts]

    return dir, name
end

M.slice = function(tbl, s, e)
    return { unpack(tbl, s, e) }
end

---@param default table
---@param override table
---@return table
---merges override into default, overriding anything in default
M.merge = function(default, override)
    override = override or {}
    return vim.tbl_deep_extend("force", {}, default, override)
end

return M
