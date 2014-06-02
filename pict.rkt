#lang racket/base
(require racket/contract/base
         racket/match
         racket/class
         racket/gui/base
         pict)

(define lazy-pict/c
  (or/c pict?
        (-> pict?)))

(define (force-pict p)
  (if (pict? p)
    p
    (p)))

;; xxx move to library
(define (draw-pict-centered p dc aw ah)
  (define pw (pict-width p))
  (define ph (pict-height p))
  (define (inset x y)
    (/ (- x y) 2))
  (draw-pict p dc (inset aw pw) (inset ah ph)))

(provide
 (contract-out
  [lazy-pict/c contract?]
  [force-pict (-> lazy-pict/c pict?)]
  [draw-pict-centered (-> pict? (is-a?/c dc<%>) real? real? void?)]))

