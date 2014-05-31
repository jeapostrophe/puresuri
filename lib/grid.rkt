#lang racket/base
(require pict
         ppict-slide-grid
         puresuri)

(define GRID? #f)
(puresuri-add-char-handler! #\g (λ () (set! GRID? (not GRID?))))

(define grid-background (grid-base-pict slide-w slide-h))
(puresuri-pipeline-snoc!
 (λ (p)
   (if GRID?
     (cc-superimpose
      p
      grid-background)
     p)))
