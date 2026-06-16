; C symbols
;
; Types expose `name: (type_identifier)` (parent is the specifier, so no @scope).
; Functions hide their name inside a function_declarator, so those use @scope.

(struct_specifier
  name: (type_identifier) @type.struct)

(union_specifier
  name: (type_identifier) @type.union)

(enum_specifier
  name: (type_identifier) @type.enum)

(type_definition
  declarator: (type_identifier) @type)

; definition: `int foo() { ... }`   prototype: `int foo(void);`
(function_definition
  declarator: (function_declarator
    declarator: (identifier) @function)) @scope

(declaration
  declarator: (function_declarator
    declarator: (identifier) @function)) @scope
