#lang racket/base
(require pict
         puresuri)

(puresuri-pipeline-snoc!
 (λ (p)
   (values (rb-superimpose p (text (number->string (current-slide-number))))
           #f)))
