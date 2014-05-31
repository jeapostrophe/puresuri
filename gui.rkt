#lang racket/base
(require racket/contract/base)

(define keycode/c
  (or/c char? symbol?))

(provide
 (contract-out
  [keycode/c contract?]))
