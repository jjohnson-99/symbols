;(class_definition
;  name: (identifier) @class.name
;  body: (block
;    (function_definition
;      name: (identifier) @method.name
;    ) @method
;  )
;) @class

; alternative could be to

(class_definition
  name: (identifier) @class.name
) @class

;(module
;  (function_definition
;    name: (identifier) @function.name
;  ) @function
;)

(function_definition
    name: (identifier) @function.name
) @function
