#lang racket/base
(require racket/contract/base
         "state.rkt")

(define current-ST (make-parameter (make-fresh-ST)))

(provide
 (contract-out
  [current-ST (parameter/c ST?)]))
