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
(struct cmd:commit! cmd (effect))
(struct cmd:clear! cmd ())
(struct cmd:transform! cmd (t))
(struct cmd:save! cmd (t))
(struct cmd:restore! cmd (t))

(define (ST-pipeline-apply st p)
  (define fs (ST-pipeline st))
  (for/fold ([p p] [anim? #f]) ([f (in-queue fs)])
    (define-values (next-p f-anim?) (f p))
    (values next-p (or f-anim? anim?))))

(struct redo (start cmds))
(struct istate (i tags saves pp anim?))

(require racket/contract/region)

(define extended-nat/c
  (or/c exact-nonnegative-integer? +inf.0))

(define/contract
  (interp* first-pp dest-i run-effect? ist cmds)
  (-> plpict? extended-nat/c boolean? istate? (listof cmd?)
      istate?)
  (match cmds
    [(list)
     ist]
    [(cons c cmds)
     (interp* first-pp dest-i run-effect?
              (interp1 first-pp dest-i run-effect? ist c)
              cmds)]))

(define/contract
  (interp1 first-pp dest-i run-effect? ist c)
  (-> plpict? extended-nat/c boolean? istate? cmd?
      istate?)
  (match-define (istate i tags saves pp anim?) ist)
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
          (error 'remove! "tag ~e is not present" t)]
         [(redo start cmds-l)
          (interp* first-pp dest-i run-effect? start (reverse cmds-l))])]
      [(cmd:add! t ap)
       (define-values (fp fp-anim?) (force-pict ap))
       (struct-copy istate ist
                    [tags (hash-set tags-n t
                                    (redo ist
                                          (list
                                           (cmd:add! t (ghost fp)))))]
                    [pp (plpict-add pp (tag-pict fp t))]
                    [anim? (or anim? fp-anim?)])]
      [(cmd:commit! effect)
       (define ni (add1 i))
       (when (and (= dest-i ni) run-effect?)
         (effect))
       (struct-copy istate ist
                    [tags tags-n]
                    [i ni])]
      [(cmd:clear!)
       (struct-copy istate ist
                    [tags tags-n]
                    [pp first-pp]
                    [anim? #f])]
      [(cmd:transform! t)
       ;; xxx it is possible the t is animated
       (struct-copy istate ist
                    [tags tags-n]
                    [pp (t pp)])]
      [(cmd:save! t)
       (struct-copy istate ist
                    [saves (hash-set saves t (cons pp anim?))])]
      [(cmd:restore! t)
       (match-define (cons t-pp t-anim?)
                     (hash-ref saves t
                               (λ ()
                                 (error 'restore! "tag ~e is not present"))))
       (struct-copy istate ist
                    [pp t-pp]
                    [anim? t-anim?])])]))

(define (ST-cmds-interp st dest-i run-effect? p)
  (define first-pp (pict->plpict p))
  (define initial-ist
    (istate 0 (hasheq) (hasheq) first-pp #f))
  (define final-ist
    (interp* first-pp dest-i run-effect? initial-ist (queue->list (ST-cmds st))))
  (define final-pp
    (istate-pp final-ist))
  (values (istate-i final-ist)
          (plpict->pict final-pp)
          (istate-anim? final-ist)))

(define (ST-char-handler st k)
  (hash-ref (ST-handlers st) k #f))

(provide
 (contract-out
  [ST? (-> any/c boolean?)]
  [make-fresh-ST (-> ST?)]
  [cmd:go! (-> placer/c cmd?)]
  [cmd:add! (-> symbol? lazy-pict/c cmd?)]
  [cmd:remove! (-> symbol? cmd?)]
  [cmd:commit! (-> (-> any) cmd?)]
  [cmd:clear! (-> cmd?)]
  [cmd:transform! (-> (-> plpict? plpict?) cmd?)]
  [cmd:save! (-> symbol? cmd?)]
  [cmd:restore! (-> symbol? cmd?)]
  [ST-cmds-snoc! (-> ST? cmd? void?)]
  [ST-cmds-interp (-> ST? extended-nat/c boolean? pict?
                      (values exact-nonnegative-integer? pict? boolean?))]
  [ST-pipeline-snoc! (-> ST? (-> pict? (values pict? boolean?)) void?)]
  [ST-pipeline-apply (-> ST? pict? (values pict? boolean?))]
  [ST-add-char-handler! (-> ST? keycode/c (-> any) void?)]
  [ST-char-handler (-> ST? keycode/c (or/c false/c (-> any)))]))
