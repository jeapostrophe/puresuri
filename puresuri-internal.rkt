#lang racket/base
(require racket/contract/base
         racket/match
         pict
         data/queue)

(struct ST (cmds pipeline handlers))
(define (make-fresh-ST)
  (ST (make-queue) (make-queue) (make-hasheq)))

(define current-ST (make-parameter #f))

(define (ST-cmds-snoc! c)
  (enqueue! (ST-cmds (current-ST)) c))
(define (ST-pipeline-snoc! f)
  (enqueue! (ST-pipeline (current-ST)) f))
(define (ST-add-char-handler! c f)
  (hash-set! (ST-handlers (current-ST)) c f))

(struct cmd ())
(struct cmd:go! cmd (pl))
(struct cmd:add! cmd (p))
(struct cmd:commit! cmd ())

(define (apply-pipeline fs p)
  (for/fold ([p p]) ([f (in-queue fs)])
    (f p)))

(struct placer+pict (placer pict))

(define placer/c
  (-> pict? pict?
      placer+pict?))

(define (exact-placer dx dy)
  (letrec ([pl (λ (b p) (placer+pict pl (pin-over b dx dy p)))])
    pl))
(define (relative-placer rx ry)
  (letrec ([pl (λ (b p) 
                 (define dx (* rx (pict-width b)))
                 (define dy (* ry (pict-height b)))
                 (placer+pict pl (pin-over b dx dy p)))])
    pl))

(define (pict->pp p)
  (placer+pict (exact-placer 0 0) p))
(define (pp->pict pp)
  (placer+pict-pict pp))
(define (pp-replace-placer pp pl)
  (struct-copy placer+pict pp
               [placer pl]))
(define (pp-place pp p)
  (match-define (placer+pict pl bp) pp)
  (pl bp p))

(define (cmds->pict dest-i p cs)
  (define pp (pict->pp p))
  (define-values (final-i final-pp)
    (for/fold ([i 0]
               [pp pp])
        ([c (in-queue cs)])
      (cond
        [(< dest-i i)
         (values i pp)]
        [else
         (match c
           [(cmd:go! pl)
            (values i (pp-replace-placer pp pl))]
           [(cmd:add! ap)
            (values i (pp-place pp ap))]
           [(cmd:commit!)
            (values (add1 i) pp)])])))
  (pp->pict final-pp))

;; xxx
(provide (all-defined-out))
