function venv_python_path()
    local cwd = vim.loop.cwd()
    local where = venv_bin_detection('python')
    if where == 'python' then
        return '/usr/bin/python'
    end
    return where
end

function venv_bin_detection(tool)
    local cwd = vim.loop.cwd()
    if vim.fn.executable(cwd .. '/.venv/bin/' .. tool) == 1 then
        return cwd .. '/.venv/bin/' .. tool
    end
    return tool
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end
