; Classes
(class_definition
  name: (identifier) @type.class)

; Functions (module-level and nested).
; Methods/constructors are refined by the more specific patterns below; the
; backend keeps the highest-priority capture per name node.
(function_definition
  name: (identifier) @function)

; Methods: functions defined directly in a class body
(class_definition
  body: (block
    (function_definition
      name: (identifier) @function.method)))

; Constructor: the __init__ method
(class_definition
  body: (block
    (function_definition
      name: (identifier) @constructor
      (#eq? @constructor "__init__"))))
