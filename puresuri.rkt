#lang racket/base
(require racket/contract/base
         pict
         "puresuri-internal.rkt")

(define slide-w 1024)
(define slide-h 768)

(define (go! pl) (ST-cmds-snoc! (cmd:go! pl)))
(define (add! p) (ST-cmds-snoc! (cmd:add! p)))
(define (commit!) (ST-cmds-snoc! (cmd:commit!)))

;; xxx add a slide name/number pipeline (communicate which slide it is via parameter)
(define puresuri-pipeline-snoc! ST-pipeline-snoc!)
(define puresuri-add-char-handler! ST-add-char-handler!)

(provide
 (contract-out
  [slide-w exact-nonnegative-integer?]
  [slide-h exact-nonnegative-integer?]
  [go!
   (-> placer/c
       void?)]
  [add!
   (-> (or/c pict?
             (-> pict?))
       void?)]
  [commit!
   (-> void?)]
  [puresuri-pipeline-snoc!
   (-> (-> pict? pict?)
       void?)]
  [puresuri-add-char-handler!
   (-> char? (-> any)
       void?)]))
