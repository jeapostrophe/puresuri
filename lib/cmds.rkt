#lang racket/base
(require racket/contract/base
         pict
         puresuri
         puresuri/pict
         puresuri/plpict)

(define (bind! t)
  (transform! (λ (pl) (values (plpict-transform pl t) #f))))

(define (replace! t p)
  (remove! t)
  (go! (at-placer t cc-find 'cc))
  (add! #:tag t p))

(define (slide! #:effect [effect void])
  (commit! #:effect effect)
  (clear!))

(provide
 (contract-out
  [bind! (-> (-> pict? pict?) void?)]
  [replace! (-> symbol? lazy-pict/c void?)]
  [slide! (->* () (#:effect (-> any)) void?)]))
