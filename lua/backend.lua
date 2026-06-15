-- lua/backend.lua
local M = {}

-- Map a treesitter capture name to a highlight group.
-- Captures come straight from the query (e.g. "type.class", "function.method"),
-- so adding a language only means writing a query + (maybe) a new entry here.
local CAPTURE_TO_HL = {
  ["type.class"]      = "SymbolsClass",
  ["type.struct"]     = "SymbolsStruct",
  ["type.enum"]       = "SymbolsEnum",
  ["type.union"]      = "SymbolsUnion",
  ["namespace"]       = "SymbolsNamespace",
  ["function"]        = "SymbolsFunction",
  ["function.method"] = "SymbolsMethod",
  ["constructor"]     = "SymbolsConstructor",
}

-- A single name node can be captured by several patterns (e.g. Python's
-- __init__ matches @function, @function.method and @constructor). When that
-- happens we keep the most specific capture.
local CAPTURE_PRIORITY = {
  ["constructor"]     = 4,
  ["function.method"] = 3,
  ["type.class"]      = 2,
  ["type.struct"]     = 2,
  ["type.enum"]       = 2,
  ["type.union"]      = 2,
  ["namespace"]       = 2,
  ["function"]        = 1,
}

-- Short label shown before the symbol name in the panel.
local CAPTURE_TO_LABEL = {
  ["type.class"]      = "class",
  ["type.struct"]     = "struct",
  ["type.enum"]       = "enum",
  ["type.union"]      = "union",
  ["namespace"]       = "namespace",
  ["function"]        = "func",
  ["function.method"] = "func",
  ["constructor"]     = "func",
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

local function priority(capture)
  return CAPTURE_PRIORITY[capture] or 0
end

local function collect_symbols_flat(query, root, bufnr)
    -- Keyed by "row:col" so multiple captures landing on the same name node
    -- collapse into the highest-priority capture.
    local by_pos = {}

    for _, match, _ in query:iter_matches(root, bufnr) do
        -- Within a match: the kind capture (e.g. @function) marks the name
        -- node, and an optional @scope capture marks the full definition node.
        -- When the name node's parent isn't the definition itself (e.g. Lua
        -- `M.x = function() end`, where the parent is a variable_list), the
        -- query supplies @scope so we still get the right range for nesting.
        local name_node, capture, scope_node
        for id, nodes in pairs(match) do
            local cap = query.captures[id]
            if cap == "scope" then
                scope_node = nodes[1]
            else
                name_node = nodes[1]
                capture = cap
            end
        end

        if name_node then
            local row, col = name_node:start()
            local key = row .. ":" .. col
            local range_node = scope_node or name_node:parent()

            local existing = by_pos[key]
            if not existing or priority(capture) > priority(existing.capture) then
                by_pos[key] = {
                    name    = vim.treesitter.get_node_text(name_node, bufnr),
                    capture = capture,                  -- e.g. "type.class", "constructor"
                    range   = get_range(range_node),    -- full definition extent (for nesting)
                    row     = row + 1,
                    col     = col,
                    indent  = get_indent(col),          -- consider dropping once scope is derived from the tree
                    children = {},
                }
            end
        end
    end

    local symbols = {}
    for _, sym in pairs(by_pos) do
        table.insert(symbols, sym)
    end
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

    -- get_parser() throws when the buffer has no language (no filetype, no
    -- installed parser, help/scratch buffers, ...). Treat that as "no symbols"
    -- so switching between buffers never breaks the panel.
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then return {} end

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
-- col 3+: [depth * indent_len spaces]label name
local CHEVRON_OPEN   = "\xe2\x8c\x84"  -- ⌄
local CHEVRON_CLOSED = "\xe2\x80\xba"  -- ›

local function format_node(node, depth, results, indent_len)
    local label      = CAPTURE_TO_LABEL[node.capture] or "sym"
    local indent_str = string.rep(" ", depth * indent_len)
    local chevron    = (#node.children > 0) and CHEVRON_OPEN or " "

    -- Byte offsets into `text` so the panel can highlight without re-deriving
    -- the (multibyte) chevron width. `#` is byte length in Lua.
    local prefix    = chevron .. " " .. indent_str
    local label_col = #prefix
    local name_col  = label_col + #label + 1

    table.insert(results, {
        name         = node.name,
        capture      = node.capture,
        hl           = CAPTURE_TO_HL[node.capture] or "SymbolsDefault",
        label        = label,
        depth        = depth,
        indent       = depth,
        row          = node.row,
        has_children = #node.children > 0,
        label_col    = label_col,
        name_col     = name_col,
        text         = prefix .. label .. " " .. node.name,
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
