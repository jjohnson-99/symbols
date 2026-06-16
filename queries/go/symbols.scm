; Go symbols

(function_declaration
  name: (identifier) @function)

(method_declaration
  name: (field_identifier) @function.method)

; struct / interface type declarations (other type specs are skipped)
(type_spec
  name: (type_identifier) @type.struct
  type: (struct_type))

(type_spec
  name: (type_identifier) @type.interface
  type: (interface_type))
