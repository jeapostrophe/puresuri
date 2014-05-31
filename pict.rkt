#lang racket/base
(require racket/contract/base
         racket/match
         pict)

(define lazy-pict/c
  (or/c pict?
        (-> pict?)))

(provide
 (contract-out
  [lazy-pict/c contract?]))
