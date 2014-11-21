#lang racket/base
(require racket/contract/base
         racket/match
         pict
         puresuri/pict
         puresuri/plpict
         puresuri/gui
         "private/param.rkt"
         "private/state.rkt")

(define current-slide-number (make-parameter 0))
(define slide-w 1024)
(define slide-h 768)

(define (snoc! c) (ST-cmds-snoc! (current-ST) c))

(define (go! pl)
  (snoc! (cmd:go! pl)))
(define (add! p #:tag [tag (gensym)]) 
  (snoc! (cmd:add! tag p)))
(define (remove! tag) 
  (snoc! (cmd:remove! tag)))
(define (commit! #:effect [effect void])
  (snoc! (cmd:commit! effect)))
(define (clear!)
  (snoc! (cmd:clear!)))
(define (transform! t)
  (snoc! (cmd:transform! t)))

(struct save (t))
(define (save!)
  (define t (gensym))
  (snoc! (cmd:save! t))
  (save t))
(define (restore! s)
  (match-define (save t) s)
  (snoc! (cmd:restore! t)))

(define (puresuri-pipeline-snoc! f)
  (ST-pipeline-snoc! (current-ST) f))
(define (puresuri-add-char-handler! k f)
  (ST-add-char-handler! (current-ST) k f))

(provide
 (contract-out
  [slide-w exact-nonnegative-integer?]
  [slide-h exact-nonnegative-integer?]
  [current-slide-number (parameter/c exact-nonnegative-integer?)]
  [go! (-> placer/c void?)]
  [add! (->* (lazy-pict/c) (#:tag symbol?) void?)]
  [remove! (-> symbol? void?)]
  [commit! (->* () (#:effect (-> any)) void?)]
  [clear! (-> void?)]
  [transform! (-> (-> plpict? (values plpict? boolean?)) void?)]
  [save? (-> any/c boolean?)]
  [save! (-> save?)]
  [restore! (-> save? void?)]
  [puresuri-pipeline-snoc! (-> (-> pict? (values pict? boolean?)) void?)]
  [puresuri-add-char-handler! (-> keycode/c (-> any) void?)]))
