#lang racket/base
(require racket/contract/base
         racket/match
         racket/list
         data/queue
         pict
         unstable/gui/pict
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
(struct cmd:add! cmd (tag p))
(struct cmd:remove! cmd (tag))
(struct cmd:commit! cmd ())
(struct cmd:clear! cmd ())
(struct cmd:transform! cmd (t))

(define (ST-pipeline-apply st p)
  (define fs (ST-pipeline st))
  (for/fold ([p p]) ([f (in-queue fs)])
    (f p)))

(struct redo (start cmds))
(struct istate (i tags pp))

(require racket/contract/region)

(define/contract 
  (interp* first-pp dest-i ist cmds)
  (-> plpict? exact-nonnegative-integer? istate? (listof cmd?)
      istate?)
  (match cmds
    [(list)
     ist]
    [(cons c cmds)
     (interp* first-pp dest-i
              (interp1 first-pp dest-i ist c)
              cmds)]))

(define/contract
  (interp1 first-pp dest-i ist c)
  (-> plpict? exact-nonnegative-integer? istate? cmd?
      istate?)
  (match-define (istate i tags pp) ist)
  (cond
    [(< dest-i i)
     ist]
    [else
     (define tags-n
       (for/hasheq
        ([(t r) (in-hash tags)])
        (define cmds-l (redo-cmds r))
        (define r-n
          (struct-copy redo r
                       [cmds (cons c cmds-l)]))
        (values t r-n)))
     (match c
       [(cmd:go! pl)
        (struct-copy istate ist
                     [tags tags-n]
                     [pp (plpict-move pp pl)])]
       [(cmd:remove! t)
        (match (hash-ref tags t #f)
          [#f
           ;; xxx error message?
           ist]
          [(redo start cmds-l)
           (interp* first-pp dest-i start (reverse cmds-l))])]
       [(cmd:add! t ap)
        (struct-copy istate ist
                     [tags (hash-set tags-n t
                                     (redo ist 
                                           (list 
                                            (cmd:add! t (ghost (force-pict ap))))))]
                     [pp (plpict-add pp (tag-pict (force-pict ap) t))])]
       [(cmd:commit!)
        (struct-copy istate ist
                     [tags tags-n]
                     [i (add1 i)])]
       [(cmd:clear!)
        (struct-copy istate ist
                     [tags tags-n]
                     [pp first-pp])]
       [(cmd:transform! t)
        (struct-copy istate ist
                     [tags tags-n]
                     [pp (t pp)])])]))

(define (ST-cmds-interp st dest-i p)
  (define first-pp (pict->plpict p))
  (define initial-ist
    (istate 0 (hasheq) first-pp))
  (define final-ist
    (interp* first-pp dest-i initial-ist (queue->list (ST-cmds st))))
  (define final-pp
    (istate-pp final-ist))
  (plpict->pict final-pp))

(define (ST-char-handler st k)
  (hash-ref (ST-handlers st) k #f))

(provide
 (contract-out
  [ST? (-> any/c boolean?)]
  [make-fresh-ST (-> ST?)]
  [cmd:go! (-> placer/c cmd?)]
  [cmd:add! (-> symbol? lazy-pict/c cmd?)]
  [cmd:remove! (-> symbol? cmd?)]
  [cmd:commit! (-> cmd?)]
  [cmd:clear! (-> cmd?)]
  [cmd:transform! (-> (-> plpict? plpict?) cmd?)]
  [ST-cmds-snoc! (-> ST? cmd? void?)]
  [ST-cmds-interp (-> ST? exact-nonnegative-integer? pict? pict?)]
  [ST-pipeline-snoc! (-> ST? (-> pict? pict?) void?)]
  [ST-pipeline-apply (-> ST? pict? pict?)]
  [ST-add-char-handler! (-> ST? keycode/c (-> any) void?)]
  [ST-char-handler (-> ST? keycode/c (or/c false/c (-> any)))]))
