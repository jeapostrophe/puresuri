#lang racket/base
(require racket/contract/base
         pict
         puresuri
         puresuri/pict
         puresuri/plpict)

(define (replace! t p)
  (remove! t)
  (go! (at-placer t cc-find 'cc))
  (add! p))

(provide
 (contract-out
  [replace! (-> symbol? lazy-pict/c void?)]))
