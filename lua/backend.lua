-- lua/backend.lua
local M = {}

local ts = vim.treesitter

local bufnr = vim.api.nvim_get_current_buf()

local function get_indent(node)
    local _, start_col = node:start()
    return start_col
end

local function get_text(node, bufnr)
  return ts.get_node_text(node, bufnr)
end


local query = vim.treesitter.query.parse('python', [[
                    ; query
                    (class_definition
                        name: (identifier) @class.name
                        body: (block
                            (function_definition
                                name: (identifier) @method.name
                            ) @method
                        )
                    ) @class
                    (module
                        (function_definition
                            name: (identifier) @function.name
                        ) @function
                    )
                    ]])


-- python is currently hardcoded, will eventually work for languages supported by treesitter
-- query is currently hardcoded, will eventually be customizable per language
function M.getSymbols()

    local tree = ts.get_parser():parse()[1]
    local results = {}

    for _, match, _ in query:iter_matches(tree:root(), bufnr) do
        local entry = nil

        for id, nodes in pairs(match) do
            local name = query.captures[id]
            local node = nodes[1]

            if name == "class.name" then
                entry = {
                    type = "class",
                    name = get_text(node, bufnr),
                    indent = get_indent(node),
                    row = select(1, node:range()) + 1,
                }

            elseif name == "method.name" then
                entry = {
                    type = "def",
                    name = get_text(node, bufnr),
                    indent = get_indent(node),
                    row = select(1, node:range()) + 1,
                }

            elseif name == "function.name" then
                entry = {
                    type = "def",
                    name = get_text(node, bufnr),
                    indent = get_indent(node),
                    row = select(1, node:range()) + 1,
                }
            end
        end

        if entry then
            table.insert(results, entry)
        end
    end

    vim.print(results)
    --return results

end

return M

--vim.print({name, node:type(), vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())})
