#lang info
(define version "1.0")
(define collection "puresuri")
(define deps '("lux"
               "base" "gui-lib" "pict-lib" "unstable-lib"))
(define build-deps '("scribble-lib"
                     ))
(define scribblings '(("puresuri.scrbl" ())))
(define raco-commands
  '(("puresuri" (submod puresuri/command main) "run a puresuri slideshow" #f)))
