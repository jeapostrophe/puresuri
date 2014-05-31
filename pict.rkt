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

;; xxx taken from ppict, merge with ryanc

(define (pin-over/align scene x y halign valign pict)
  (let ([localrefx (* (pict-width pict) (align->frac halign))]
        [localrefy (* (pict-height pict) (align->frac valign))])
    (pin-over scene (- x localrefx) (- y localrefy) pict)))

(define (align->frac align)
  (case align
    ((t l)   0)
    ((c)   1/2)
    ((b r)   1)))

(define (align->h align)
  (case align
    ((lt lc lb) 'l)
    ((ct cc cb) 'c)
    ((rt rc rb) 'r)))

(define (align->v align)
  (case align
    ((lt ct rt) 't)
    ((lc cc rc) 'c)
    ((lb cb rb) 'b)))

(define align/c
  (or/c 'lt 'ct 'rt
        'lc 'cc 'rc
        'lb 'cb 'rb))
(define halign/c
  (or/c 'l 'c 'r))
(define valign/c
  (or/c 't 'c 'b))

(provide
 (contract-out
  [pin-over/align (-> pict? real? real? halign/c valign/c pict? pict?)]
  [align/c contract?]
  [halign/c contract?]
  [align->h (-> align/c halign/c)]
  [valign/c contract?]
  [align->v (-> align/c valign/c)]))
