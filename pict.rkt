#lang racket/base
(require racket/contract/base
         racket/match
         pict)

(define lazy-pict/c
  (or/c pict?
        (-> pict?)))

(define (force-pict p)
  (if (pict? p)
    p
    (p)))

(provide
 (contract-out
  [lazy-pict/c contract?]
  [force-pict (-> lazy-pict/c pict?)]))

