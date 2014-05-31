#lang racket/base
(require racket/contract/base
         racket/match
         data/queue
         pict
         puresuri/pict
         puresuri/plpict
         puresuri/gui)

(struct ST (cmds pipeline handlers))
(define (make-fresh-ST)
  (ST (make-queue) (make-queue) (make-hasheq)))

(define (ST-cmds-snoc! st c)
  (enqueue! (ST-cmds st) c))
(define (ST-pipeline-snoc! st f)
  (enqueue! (ST-pipeline st) f))
(define (ST-add-char-handler! st c f)
  (hash-set! (ST-handlers st) c f))

(struct cmd ())
(struct cmd:go! cmd (pl))
(struct cmd:add! cmd (p))
(struct cmd:commit! cmd ())

(define (ST-pipeline-apply st p)
  (define fs (ST-pipeline st))
  (for/fold ([p p]) ([f (in-queue fs)])
    (f p)))

(define (ST-cmds-interp st dest-i p)
  (define cs (ST-cmds st))
  (define pp (pict->plpict p))
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
            (values i (plpict-move pp pl))]
           [(cmd:add! ap)
            (values i (plpict-add pp (force-pict ap)))]
           [(cmd:commit!)
            (values (add1 i) pp)])])))
  (plpict->pict final-pp))

(define (ST-char-handler st k)
  (hash-ref (ST-handlers st) k #f))

(provide
 (contract-out
  [ST? (-> any/c boolean?)]
  [make-fresh-ST (-> ST?)]
  [cmd:go! (-> placer/c cmd?)]
  [cmd:add! (-> lazy-pict/c cmd?)]
  [cmd:commit! (-> cmd?)]
  [ST-cmds-snoc! (-> ST? cmd? void?)]
  [ST-cmds-interp (-> ST? exact-nonnegative-integer? pict? pict?)]
  [ST-pipeline-snoc! (-> ST? (-> pict? pict?) void?)]
  [ST-pipeline-apply (-> ST? pict? pict?)]
  [ST-add-char-handler! (-> ST? keycode/c (-> any) void?)]
  [ST-char-handler (-> ST? keycode/c (or/c false/c (-> any)))]))
