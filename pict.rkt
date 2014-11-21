#lang racket/base
(require racket/contract/base
         racket/match
         pict)

(define lazy-pict/c
  (or/c pict?
        (-> pict?)))

(define (force-pict p)
  (if (pict? p)
    (values p #f)
    (values (p) #t)))

(provide
 (contract-out
  [lazy-pict/c contract?]
  [force-pict (-> lazy-pict/c (values pict? boolean?))]))

