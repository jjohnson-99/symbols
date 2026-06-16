; JavaScript symbols

(function_declaration
  name: (identifier) @function)

(class_declaration
  name: (identifier) @type.class)

(method_definition
  name: (property_identifier) @function.method)

(method_definition
  name: (property_identifier) @constructor
  (#eq? @constructor "constructor"))

; arrow / function expressions assigned to a variable
(variable_declarator
  name: (identifier) @function
  value: [(arrow_function) (function_expression)])
