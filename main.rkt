#lang racket/base
(require racket/contract/base
         pict
         puresuri/pict
         puresuri/plpict
         puresuri/gui
         "private/param.rkt"
         "private/state.rkt")

(define slide-w 1024)
(define slide-h 768)

(define (snoc! c) (ST-cmds-snoc! (current-ST) c))

(define (go! pl)
  (snoc! (cmd:go! pl)))
(define (add! p #:tag [tag (gensym)]) 
  (snoc! (cmd:add! tag p)))
(define (remove! tag) 
  (snoc! (cmd:remove! tag)))
(define (commit!)
  (snoc! (cmd:commit!)))
(define (clear!)
  (snoc! (cmd:clear!)))
(define (transform! t)
  (snoc! (cmd:transform! t)))

;; xxx add a slide name/number pipeline (communicate which slide it is via parameter)
(define (puresuri-pipeline-snoc! f)
  (ST-pipeline-snoc! (current-ST) f))
(define (puresuri-add-char-handler! k f)
  (ST-add-char-handler! (current-ST) k f))

(provide
 (contract-out
  [slide-w exact-nonnegative-integer?]
  [slide-h exact-nonnegative-integer?]
  [go! (-> placer/c void?)]
  [add! (->* (lazy-pict/c) (#:tag symbol?) void?)]
  [remove! (-> symbol? void?)]
  [commit! (-> void?)]
  [clear! (-> void?)]
  [transform! (-> (-> plpict? plpict?) void?)]
  [puresuri-pipeline-snoc! (-> (-> pict? pict?) void?)]
  [puresuri-add-char-handler! (-> keycode/c (-> any) void?)]))
