#lang racket/base
(require racket/contract/base
         racket/match
         pict
         unstable/gui/pict
         unstable/gui/pict/align
         puresuri/pict)

(struct plpict (placer pict))

(define placer/c
  (recursive-contract
   (-> pict? pict?
       (values placer/c pict?))))

(define (exact-placer dx dy a)
  (λ (b p)
    (values (exact-placer dx (+ dy (pict-height p))
                          a)
            (pin-over/align b dx dy (align->h a) (align->v a) p))))
(define (relative-placer rx ry a)
  (λ (b p)
    (define dx (* rx (pict-width b)))
    (define dy (* ry (pict-height b)))
    ((exact-placer dx dy a) b p)))
(define (at-placer path [finder cc-find] [a 'cc])
  (λ (b p)
    (define find-path 
      (if (tag-path? path) (find-tag b path) path))
    (unless find-path
      (error 'at-placer "tag ~e not found" path))
    (define-values (x y) (finder b find-path))
    ((exact-placer x y a) b p)))

(define (pict->plpict p)
  (plpict (exact-placer 0 0 'lt) p))
(define (plpict->pict pp)
  (plpict-pict pp))
(define (plpict-move pp pl)
  (struct-copy plpict pp
               [placer pl]))
(define (plpict-add pp p)
  (match-define (plpict pl bp) pp)
  (define-values (new-pl new-bp) (pl bp p))
  (plpict new-pl new-bp))

(define (plpict-transform pp t)
  (plpict (plpict-placer pp)
          (t (plpict->pict pp))))

(provide
 (contract-out
  [plpict? (-> any/c boolean?)]
  [placer/c contract?]
  [exact-placer (-> real? real? align/c placer/c)]
  [relative-placer (-> real? real? align/c placer/c)]
  [at-placer (->* ((or/c tag-path? pict-path?))
                  (procedure? align/c)
                  placer/c)]
  [pict->plpict (-> pict? plpict?)]
  [plpict->pict (-> plpict? pict?)]
  [plpict (-> placer/c pict? plpict?)]
  [plpict-placer (-> plpict? placer/c)]
  [plpict-move (-> plpict? placer/c plpict?)]
  [plpict-add (-> plpict? pict? plpict?)]
  [plpict-transform (-> plpict? (-> pict? pict?) plpict?)]))
