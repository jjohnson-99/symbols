-- lua/backend.lua
local M = {}

-- TYPE_MAP is temporary since adheres only to Python naming
local TYPE_MAP = {
  ["class"] = "class",
  ["function"] = "func",
  ["method"] = "func",
  ["struct"] = "struct",
  ["enum"] = "enum",
  ["union"] = "union",
}

local function get_range(node)
    local r1, c1, r2, c2 = node:range()
    return {r1, c1, r2, c2}
end

local function contains(a, b)
  if a[1] > b[1] or a[3] < b[3] then return false end
  if a[1] == b[1] and a[2] > b[2] then return false end
  if a[3] == b[3] and a[4] < b[4] then return false end
  return true
end

local function get_indent(col)
  local shiftwidth = vim.bo.shiftwidth > 0 and vim.bo.shiftwidth or 2
  return math.floor(col / shiftwidth)
end

local function collect_symbols_flat(query, root, bufnr)
    local symbols = {}

    for _, match, _ in query:iter_matches(root, bufnr) do
        for id, nodes in pairs(match) do
            local capture = query.captures[id]
            local node = nodes[1]

            local kind = capture:match("^([%w_]+)%.name$")
            if kind and TYPE_MAP[kind] then
                local row, col = node:start()

                table.insert(symbols, {
                    type = TYPE_MAP[kind],
                    name = vim.treesitter.get_node_text(node, bufnr),
                    range = get_range(node:parent()), -- node is just the name so node:parent() is the declaration itself
                    row = row + 1,
                    indent = get_indent(col), -- consider removing col/indent and handle scope when walking tree
                    children = {}
                })
            end
        end
    end

    --vim.print(symbols)
    return symbols
end

local function build_tree(symbols)
    table.sort(symbols, function(a, b)
        if a.range[1] == b.range[1] then
            return a.range[2] < b.range[2]
        end
        return a.range[1] < b.range[1]
    end)

    local root = {}

    for i, sym in ipairs(symbols) do
        local parent = nil

        -- find closest enclosing parent
        -- consider using .is_ancestor(candidate, sym), requires backtracking for deep nestings
        -- could not get .is_ancestor to work, but I think I know the problem
        -- can use a stack to check/build tree, would remove need for range
        -- is this implementation worth the time complexity?
        for j = i - 1, 1, -1 do
            local candidate = symbols[j]
            if contains(candidate.range, sym.range) then
                parent = candidate
                break
            end
        end

        if parent then
            table.insert(parent.children, sym)
        else
            table.insert(root, sym)
        end
    end

    return root
end

function M.get_symbols_tree()
    local bufnr = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(bufnr)
    local tree = parser:parse()[1]
    local root = tree:root()
    local lang = parser:lang()

    local query = vim.treesitter.query.get(lang, "symbols")
    if not query then return {} end

    local flat = collect_symbols_flat(query, root, bufnr)
    return build_tree(flat)
end


-- col 1: ⌄ U+2304 (unfolded), › U+203A (folded), or space
-- col 2: space separator (always)
-- col 3+: [depth * indent_len spaces]type name
local CHEVRON_OPEN   = "\xe2\x8c\x84"  -- ⌄
local CHEVRON_CLOSED = "\xe2\x80\xba"  -- ›

local function format_node(node, depth, results, indent_len)
    local chevron = (#node.children > 0) and CHEVRON_OPEN or " "
    local indent  = string.rep(" ", depth * indent_len)
    table.insert(results, {
        text = chevron .. " " .. indent .. node.type .. " " .. node.name,
        row  = node.row,
    })
    for _, child in ipairs(node.children) do
        format_node(child, depth + 1, results, indent_len)
    end
end

function M.get_display_list()
    local tree       = M.get_symbols_tree()
    local results    = {}
    local indent_len = vim.g.symbols_IndentLength or 2
    for _, node in ipairs(tree) do
        format_node(node, 0, results, indent_len)
    end
    return results
end


return M

