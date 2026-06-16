; C symbols
;
; Types expose `name: (type_identifier)` (parent is the specifier). Functions
; are matched at the function_declarator so pointer return types (which wrap the
; declarator) are still found; the backend climbs to the enclosing definition
; for the range.

(struct_specifier
  name: (type_identifier) @type.struct)

(union_specifier
  name: (type_identifier) @type.union)

(enum_specifier
  name: (type_identifier) @type.enum)

(type_definition
  declarator: (type_identifier) @type)

(function_declarator
  declarator: (identifier) @function)
