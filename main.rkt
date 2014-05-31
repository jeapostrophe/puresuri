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

(define (go! pl) (ST-cmds-snoc! (current-ST) (cmd:go! pl)))
(define (add! p) (ST-cmds-snoc! (current-ST) (cmd:add! p)))
(define (commit!) (ST-cmds-snoc! (current-ST) (cmd:commit!)))

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
  [add! (-> lazy-pict/c void?)]
  [commit! (-> void?)]
  [puresuri-pipeline-snoc! (-> (-> pict? pict?) void?)]
  [puresuri-add-char-handler! (-> keycode/c (-> any) void?)]))
