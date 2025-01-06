local M = {}

--- Thin wrapper for form-1 vim.validate
function M.validate(name, value, validator, optional, message)
    if vim.fn.has("nvim-0.11") == 1 then
        -- spec-style validate is deprecated in nvim-0.11.
        vim.validate(name, value, validator, optional, message)
    else
        if type(optional) == "boolean" then
            if optional then
                vim.validate {
                    [name] = { value, validator, true },
                }
            else
                vim.validate {
                    [name] = { value, validator, message },
                }
            end
        elseif type(optional) == "string" then
            vim.validate {
                [name] = { value, validator, optional },
            }
        else
            vim.validate {
                [name] = { value, validator },
            }
        end
    end
end

return M
