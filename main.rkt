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

(define pipeline/c
  (-> pict? (values pict? boolean?)))
(define (puresuri-pipeline-snoc! f)
  (ST-pipeline-snoc! (current-ST) f))
(define (puresuri-add-char-handler! k f)
  (ST-add-char-handler! (current-ST) k f))

(provide
 plpict?
 placer/c
 exact-placer
 relative-placer
 at-placer
 lazy-pict/c
 (contract-out
  [slide-w exact-nonnegative-integer?]
  [slide-h exact-nonnegative-integer?]
  [current-slide-number (parameter/c exact-nonnegative-integer?)]
  [go! (-> placer/c void?)]
  [add! (->* (lazy-pict/c) (#:tag (or/c #f symbol?)) void?)]
  [remove! (-> symbol? void?)]
  [commit! (->* () (#:effect (-> any)) void?)]
  [clear! (-> void?)]
  [transform! (-> (-> plpict? (values plpict? boolean?)) void?)]
  [save? (-> any/c boolean?)]
  [save! (-> save?)]
  [restore! (-> save? void?)]
  [pipeline/c contract?]
  [puresuri-pipeline-snoc! (-> pipeline/c void?)]
  [charcode/c contract?]
  [puresuri-add-char-handler! (-> charcode/c (-> any) void?)]))
