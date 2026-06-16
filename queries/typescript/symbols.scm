; TypeScript symbols

(function_declaration
  name: (identifier) @function)

(class_declaration
  name: (type_identifier) @type.class)

(interface_declaration
  name: (type_identifier) @type.interface)

(enum_declaration
  name: (identifier) @type.enum)

(type_alias_declaration
  name: (type_identifier) @type)

(internal_module
  name: (identifier) @namespace)

(method_definition
  name: (property_identifier) @function.method)

(method_definition
  name: (property_identifier) @constructor
  (#eq? @constructor "constructor"))

; method declarations inside an interface
(method_signature
  name: (property_identifier) @function.method)

; arrow / function expressions assigned to a variable
(variable_declarator
  name: (identifier) @function
  value: [(arrow_function) (function_expression)])
