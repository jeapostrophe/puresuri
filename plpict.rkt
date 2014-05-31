#lang racket/base
(require racket/contract/base
         racket/match
         pict)

(struct plpict (placer pict))

(define placer/c
  (recursive-contract
   (-> pict? pict?
       (values placer/c pict?))))

(define (exact-placer dx dy)
  (letrec ([pl (λ (b p) (values pl (pin-over b dx dy p)))])
    pl))
(define (relative-placer rx ry)
  (letrec ([pl (λ (b p)
                 (define dx (* rx (pict-width b)))
                 (define dy (* ry (pict-height b)))
                 (values pl (pin-over b dx dy p)))])
    pl))

(define (pict->plpict p)
  (plpict (exact-placer 0 0) p))
(define (plpict->pict pp)
  (plpict-pict pp))
(define (plpict-move pp pl)
  (struct-copy plpict pp
               [placer pl]))
(define (plpict-add pp p)
  (match-define (plpict pl bp) pp)
  (define-values (new-pl new-bp) (pl bp p))
  (plpict new-pl new-bp))

(provide
 (contract-out
  [plpict? (-> any/c boolean?)]
  [placer/c contract?]
  [exact-placer (-> real? real? placer/c)]
  [relative-placer (-> real? real? placer/c)]
  [pict->plpict (-> pict? plpict?)]
  [plpict->pict (-> plpict? pict?)]
  [plpict-move (-> plpict? placer/c plpict?)]
  [plpict-add (-> plpict? pict? plpict?)]))
