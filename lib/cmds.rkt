#lang racket/base
(require racket/contract/base
         pict
         puresuri
         puresuri/pict
         puresuri/plpict)

(define (bind! t)
  (transform! (λ (pl) (plpict-transform pl t))))

(define (replace! t p)
  (remove! t)
  (go! (at-placer t cc-find 'cc))
  (add! p))

(define (slide!)
  (commit!)
  (clear!))

(provide
 (contract-out
  [bind! (-> (-> pict? pict?) void?)]
  [replace! (-> symbol? lazy-pict/c void?)]
  [slide! (-> void?)]))
