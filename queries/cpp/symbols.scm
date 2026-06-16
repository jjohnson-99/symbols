; C++ symbols (covers both .cpp and .hpp -- both use the `cpp` parser).
;
; Functions are matched at the function_declarator, so reference/pointer return
; types -- which wrap the declarator in reference_declarator/pointer_declarator
; nodes -- are still found. The backend climbs out of those wrappers to the
; enclosing definition to get the range.

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

;; Functions & methods -------------------------------------------------------
; identifier -> free function; field_identifier -> in-class method;
; qualified_identifier -> out-of-line method (e.g. Foo::method)
(function_declarator
  declarator: (identifier) @function)

(function_declarator
  declarator: (field_identifier) @function.method)

(function_declarator
  declarator: (qualified_identifier) @function.method)

(function_declarator
  declarator: (destructor_name) @constructor)

;; Constructors --------------------------------------------------------------
; A constructor declaration has no return type (!type), which distinguishes it
; from a free-function prototype. It matches the same name as @function above;
; the backend keeps the higher-priority @constructor.
(declaration
  !type
  declarator: (function_declarator
    declarator: (identifier) @constructor))
