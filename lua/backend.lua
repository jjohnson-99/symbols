-- lua/backend.lua
local M = {}


-- python is currently hardcoded, will eventually work for languages supported by treesitter
-- query is currently hardcoded, will eventually be customizable per language
function M.getSymbolsTree()
    local query = vim.treesitter.query.parse('python', [[
                    ; query
                    (class_definition
                        name: (identifier) @class_name)
                    (function_definition
                        name: (identifier) @function_name)
                    ]])
    local tree = vim.treesitter.get_parser():parse()[1]
    for id, node, metadata in query:iter_captures(tree:root(), vim.api.nvim_get_current_buf()) do
        -- Print the node name and source text.
        vim.print({query.captures[id], node:type(), vim.treesitter.get_node_text(node, vim.api.nvim_get_current_buf())})
        vim.print(vim.inspect(metadata))
    end
end

return M

--[
--vim.treesitter.is_ancestor({dest}, {source}) {dest} (TSNode) Possible ancestor {source} (TSNode) Possible descendant return (boolean)
--]
