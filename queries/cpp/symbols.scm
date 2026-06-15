; C++ symbols (covers both .cpp and .hpp -- both use the `cpp` parser).
;
; Type specifiers expose `name: (type_identifier)` whose parent is the
; specifier itself, so they need no @scope. Functions hide their name inside a
; function_declarator, so the captured name's parent is that declarator rather
; than the definition -- those patterns tag the full node with @scope to give
; the backend the right range for nesting.

;; Types ---------------------------------------------------------------------
(class_specifier
  name: (type_identifier) @type.class)

(struct_specifier
  name: (type_identifier) @type.struct)

(enum_specifier
  name: (type_identifier) @type.enum)

(union_specifier
  name: (type_identifier) @type.union)

(namespace_definition
  name: (namespace_identifier) @namespace)

;; Free functions ------------------------------------------------------------
; definition: `int foo() { ... }`   declaration/prototype: `int foo();`
(function_definition
  declarator: (function_declarator
    declarator: (identifier) @function)) @scope

(declaration
  declarator: (function_declarator
    declarator: (identifier) @function)) @scope

;; Methods -------------------------------------------------------------------
; in-class definition / prototype (field_identifier) and out-of-line
; definition (qualified_identifier, e.g. `Foo::method`)
(function_definition
  declarator: (function_declarator
    declarator: (field_identifier) @function.method)) @scope

(field_declaration
  declarator: (function_declarator
    declarator: (field_identifier) @function.method)) @scope

(function_definition
  declarator: (function_declarator
    declarator: (qualified_identifier) @function.method)) @scope

;; Constructors / destructors ------------------------------------------------
; A constructor declaration has no return type (!type), which distinguishes it
; from a free-function prototype. It also matches @function above, but the
; backend keeps the higher-priority @constructor.
(declaration
  !type
  declarator: (function_declarator
    declarator: (identifier) @constructor)) @scope

(declaration
  declarator: (function_declarator
    declarator: (destructor_name) @constructor)) @scope
