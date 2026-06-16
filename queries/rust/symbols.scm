; Rust symbols

(mod_item
  name: (identifier) @namespace)

(struct_item
  name: (type_identifier) @type.struct)

(enum_item
  name: (type_identifier) @type.enum)

(union_item
  name: (type_identifier) @type.union)

(trait_item
  name: (type_identifier) @type.trait)

; all functions; methods (in impl/trait bodies) are refined below and win via
; the backend's priority dedup
(function_item
  name: (identifier) @function)

(impl_item
  (declaration_list
    (function_item
      name: (identifier) @function.method)))

(trait_item
  (declaration_list
    (function_signature_item
      name: (identifier) @function.method)))
