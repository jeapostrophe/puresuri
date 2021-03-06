#lang info
(define version "1.0")
(define collection "puresuri")
(define deps '("lux"
               "base" "gui-lib" "pict-lib" "ppict" "unstable-lib"))
(define build-deps '("ppict"
                     "gui-doc"
                     "pict-doc"
                     "racket-doc"
                     "slideshow-doc"
                     "unstable-doc"
                     "scribble-lib"
                     ))
(define scribblings '(("puresuri.scrbl" () ("Presentations"))))
(define raco-commands
  '(("puresuri" (submod puresuri/command main) "run a puresuri slideshow" #f)))
