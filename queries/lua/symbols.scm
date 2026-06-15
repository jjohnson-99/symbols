; Lua has no classes; symbols are function declarations in their various forms.
; We capture the whole `name:` node (not the inner identifier) so that the
; backend's node:parent() lands on the function_declaration -- giving the full
; body range for nesting -- and the display name reads naturally (e.g. M.foo).

; function foo() ... end   /   local function foo() ... end
(function_declaration
  name: (identifier) @function)

; function M.foo() ... end
(function_declaration
  name: (dot_index_expression) @function)

; function Obj:method() ... end
(function_declaration
  name: (method_index_expression) @function.method)

; Assignment-style functions, e.g. `local cb = function() end`,
; `M.handler = function() end`, `deep.nested.fn = function() end`.
; The name lives in a variable_list, so @scope marks the whole statement to
; give the backend the full body range for nesting.
(assignment_statement
  (variable_list
    name: (_) @function)
  (expression_list
    value: (function_definition))) @scope

; Table-constructor fields holding a function, e.g. `{ handler = function() end }`
(field
  name: (_) @function
  value: (function_definition)) @scope
